import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/clipboard_items.dart';

part 'clipboard_dao.g.dart';

enum ClipboardFilterMode {
  all,
  text,
  image,
  file,
  pinned,
}

class UpsertClipboardResult {
  const UpsertClipboardResult({
    this.itemId,
    this.ignoredAsDuplicate = false,
    this.orphanedImagePaths = const [],
  });

  final int? itemId;
  final bool ignoredAsDuplicate;
  final List<String> orphanedImagePaths;
}

class _ParsedSearchQuery {
  const _ParsedSearchQuery({
    required this.textQuery,
    this.appFilter,
  });

  final String textQuery;
  final String? appFilter;

  static final RegExp _appTokenPattern = RegExp(
    r'(?:^|\s)@app:(\S+)',
    caseSensitive: false,
  );

  factory _ParsedSearchQuery.parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const _ParsedSearchQuery(textQuery: '');
    }

    String? appFilter;
    final remaining = trimmed.replaceAllMapped(_appTokenPattern, (match) {
      appFilter = match.group(1)?.trim();
      return ' ';
    }).trim();

    return _ParsedSearchQuery(
      textQuery: remaining,
      appFilter: (appFilter != null && appFilter!.isNotEmpty) ? appFilter : null,
    );
  }
}

@DriftAccessor(tables: [ClipboardItems])
class ClipboardDao extends DatabaseAccessor<AppDatabase>
    with _$ClipboardDaoMixin {
  ClipboardDao(super.db);

  static String _escapeLike(String input) {
    return input
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
  }

  /// Streams clipboard history with optional [filter], `@app:<name>` source-app
  /// filter, and FTS5 trigram search (falling back to LIKE for 1-2 char queries).
  Stream<List<ClipboardItem>> watchItems({
    String query = '',
    ClipboardFilterMode filter = ClipboardFilterMode.all,
    int limit = 500,
  }) {
    final parsed = _ParsedSearchQuery.parse(query);
    final textQuery = parsed.textQuery;
    final appFilter = parsed.appFilter;

    final conditions = <String>[];
    final variables = <Variable<Object>>[];

    switch (filter) {
      case ClipboardFilterMode.all:
        break;
      case ClipboardFilterMode.text:
        conditions.add('c.type IN (?, ?)');
        variables.add(Variable.withInt(ClipboardItemType.text.index));
        variables.add(Variable.withInt(ClipboardItemType.richText.index));
      case ClipboardFilterMode.image:
        conditions.add('c.type = ?');
        variables.add(Variable.withInt(ClipboardItemType.image.index));
      case ClipboardFilterMode.file:
        conditions.add('c.type = ?');
        variables.add(Variable.withInt(ClipboardItemType.file.index));
      case ClipboardFilterMode.pinned:
        conditions.add('c.is_pinned = 1');
    }

    if (appFilter != null) {
      conditions.add(r"LOWER(COALESCE(c.source_app, '')) LIKE ? ESCAPE '\'");
      variables.add(
        Variable.withString('%${_escapeLike(appFilter.toLowerCase())}%'),
      );
    }

    if (textQuery.isEmpty) {
      final whereClause =
          conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';
      variables.add(Variable.withInt(limit));
      return customSelect(
        '''
        SELECT c.* FROM clipboard_items c
        $whereClause
        ORDER BY c.is_pinned DESC, c.last_used_at DESC, c.id DESC
        LIMIT ?
        ''',
        variables: variables,
        readsFrom: {clipboardItems},
      ).asyncMap((row) => clipboardItems.mapFromRow(row)).watch();
    }

    if (textQuery.runes.length < 3) {
      final escaped = _escapeLike(textQuery);
      conditions.add(r"c.plain_text LIKE ? ESCAPE '\'");
      variables.add(Variable.withString('%$escaped%'));
      variables.add(Variable.withInt(limit));
      return customSelect(
        '''
        SELECT c.* FROM clipboard_items c
        WHERE ${conditions.join(' AND ')}
        ORDER BY c.is_pinned DESC, c.last_used_at DESC, c.id DESC
        LIMIT ?
        ''',
        variables: variables,
        readsFrom: {clipboardItems},
      ).asyncMap((row) => clipboardItems.mapFromRow(row)).watch();
    }

    final ftsQuery = '"${textQuery.replaceAll('"', '""')}"';
    conditions.add('clipboard_items_fts MATCH ?');
    variables.add(Variable.withString(ftsQuery));
    variables.add(Variable.withInt(limit));

    return customSelect(
      '''
      SELECT c.* FROM clipboard_items c
      INNER JOIN clipboard_items_fts fts ON fts.rowid = c.id
      WHERE ${conditions.join(' AND ')}
      ORDER BY c.is_pinned DESC, c.last_used_at DESC, c.id DESC
      LIMIT ?
      ''',
      variables: variables,
      readsFrom: {clipboardItems},
    ).asyncMap((row) => clipboardItems.mapFromRow(row)).watch();
  }

  /// Streams total item count for the search header counter.
  Stream<int> watchTotalCount() {
    final countExp = clipboardItems.id.count();
    final query = selectOnly(clipboardItems)..addColumns([countExp]);
    return query.map((row) => row.read(countExp) ?? 0).watchSingle();
  }

  /// Inserts a new item or bumps an existing duplicate, then prunes overflow
  /// unpinned entries beyond [maxUnpinned].
  Future<UpsertClipboardResult> insertOrBump(
    ClipboardItemsCompanion entry, {
    int maxUnpinned = 500,
    DateTime? now,
  }) async {
    return transaction(() async {
      final hash = entry.contentHash.value;
      final baseNow = now ?? DateTime.now();

      final latest = await (select(clipboardItems)
            ..orderBy([
              (t) => OrderingTerm.desc(t.lastUsedAt),
              (t) => OrderingTerm.desc(t.id),
            ])
            ..limit(1))
          .getSingleOrNull();

      if (latest != null && latest.contentHash == hash) {
        return const UpsertClipboardResult(ignoredAsDuplicate: true);
      }

      // Drift stores DateTime columns with 1-second Unix precision by default.
      // Compare at second granularity so sub-second copies/bumps stay strictly monotonic.
      final baseSec = baseNow.millisecondsSinceEpoch ~/ 1000;
      final latestSec = latest == null ? -1 : latest.lastUsedAt.millisecondsSinceEpoch ~/ 1000;
      final effectiveNow = (latest != null && baseSec <= latestSec)
          ? DateTime.fromMillisecondsSinceEpoch((latestSec + 1) * 1000)
          : baseNow;

      final existing = await (select(clipboardItems)
            ..where((t) => t.contentHash.equals(hash))
            ..limit(1))
          .getSingleOrNull();

      if (existing != null) {
        await (update(clipboardItems)..where((t) => t.id.equals(existing.id)))
            .write(
          ClipboardItemsCompanion(
            lastUsedAt: Value(effectiveNow),
            sourceApp: entry.sourceApp.present
                ? entry.sourceApp
                : const Value.absent(),
          ),
        );
        return UpsertClipboardResult(itemId: existing.id);
      }

      final insertedId = await into(clipboardItems).insert(
        entry.copyWith(
          createdAt: Value(baseNow),
          lastUsedAt: Value(effectiveNow),
        ),
      );

      final orphanedImages = await _pruneOverflowUnpinned(maxUnpinned);

      return UpsertClipboardResult(
        itemId: insertedId,
        orphanedImagePaths: orphanedImages,
      );
    });
  }

  Future<List<String>> _pruneOverflowUnpinned(int maxUnpinned) async {
    final countExp = clipboardItems.id.count();
    final unpinnedCountRow = await (selectOnly(clipboardItems)
          ..addColumns([countExp])
          ..where(clipboardItems.isPinned.equals(false)))
        .getSingle();
    final unpinnedCount = unpinnedCountRow.read(countExp) ?? 0;

    final excess = unpinnedCount - maxUnpinned;
    if (excess <= 0) return const [];

    final toDelete = await (select(clipboardItems)
          ..where((t) => t.isPinned.equals(false))
          ..orderBy([
            (t) => OrderingTerm.asc(t.lastUsedAt),
            (t) => OrderingTerm.asc(t.id),
          ])
          ..limit(excess))
        .get();

    if (toDelete.isEmpty) return const [];

    final ids = toDelete.map((e) => e.id).toList();
    final candidateImages = toDelete
        .map((e) => e.imagePath)
        .whereType<String>()
        .toSet();

    await (delete(clipboardItems)..where((t) => t.id.isIn(ids))).go();

    return _filterUnreferencedImages(candidateImages);
  }

  /// Toggles pin state for an item and returns the new pinned status.
  Future<bool> togglePin(int id) async {
    return transaction(() async {
      final item = await (select(clipboardItems)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (item == null) return false;

      final nextPinned = !item.isPinned;
      await (update(clipboardItems)..where((t) => t.id.equals(id)))
          .write(ClipboardItemsCompanion(isPinned: Value(nextPinned)));
      return nextPinned;
    });
  }

  /// Deletes a single item and returns its image relative path if orphaned.
  Future<String?> deleteItemById(int id) async {
    return transaction(() async {
      final item = await (select(clipboardItems)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (item == null) return null;

      await (delete(clipboardItems)..where((t) => t.id.equals(id))).go();

      final imgPath = item.imagePath;
      if (imgPath == null) return null;
      final orphaned = await _filterUnreferencedImages({imgPath});
      return orphaned.isNotEmpty ? orphaned.first : null;
    });
  }

  /// Clears all unpinned items (used by tray menu) and returns orphaned image paths.
  Future<List<String>> clearUnpinned() async {
    return transaction(() async {
      final targets = await (select(clipboardItems)
            ..where((t) => t.isPinned.equals(false)))
          .get();
      final candidateImages = targets
          .map((e) => e.imagePath)
          .whereType<String>()
          .toSet();

      await (delete(clipboardItems)..where((t) => t.isPinned.equals(false)))
          .go();

      return _filterUnreferencedImages(candidateImages);
    });
  }

  /// Trims excess unpinned entries when [maxUnpinned] is reduced in settings.
  Future<List<String>> pruneOverflow(int maxUnpinned) async {
    return transaction(() => _pruneOverflowUnpinned(maxUnpinned));
  }

  /// Deletes unpinned items whose [lastUsedAt] is older than [retentionDays].
  /// Returns orphaned image paths to remove from disk.
  Future<List<String>> pruneExpiredUnpinned(
    int retentionDays, {
    DateTime? now,
  }) async {
    if (retentionDays <= 0) return const [];
    final cutoff = (now ?? DateTime.now()).subtract(Duration(days: retentionDays));

    return transaction(() async {
      final expired = await (select(clipboardItems)
            ..where(
              (t) =>
                  t.isPinned.equals(false) &
                  t.lastUsedAt.isSmallerThanValue(cutoff),
            ))
          .get();

      if (expired.isEmpty) return const [];

      final ids = expired.map((e) => e.id).toList();
      final candidateImages = expired
          .map((e) => e.imagePath)
          .whereType<String>()
          .toSet();

      await (delete(clipboardItems)..where((t) => t.id.isIn(ids))).go();

      return _filterUnreferencedImages(candidateImages);
    });
  }

  Future<List<String>> _filterUnreferencedImages(Set<String> candidates) async {
    if (candidates.isEmpty) return const [];
    final stillUsed = await (selectOnly(clipboardItems)
          ..addColumns([clipboardItems.imagePath])
          ..where(clipboardItems.imagePath.isIn(candidates)))
        .map((row) => row.read(clipboardItems.imagePath))
        .get();
    final stillUsedSet = stillUsed.whereType<String>().toSet();
    return candidates.difference(stillUsedSet).toList();
  }
}
