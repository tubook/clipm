import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/clipboard_items.dart';

part 'clipboard_dao.g.dart';

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

@DriftAccessor(tables: [ClipboardItems])
class ClipboardDao extends DatabaseAccessor<AppDatabase>
    with _$ClipboardDaoMixin {
  ClipboardDao(super.db);

  /// Streams clipboard history with FTS5 trigram search (falling back to LIKE
  /// for 1-2 character queries).
  Stream<List<ClipboardItem>> watchItems({
    String query = '',
    int limit = 500,
  }) {
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      return (select(clipboardItems)
            ..orderBy([
              (t) => OrderingTerm.desc(t.isPinned),
              (t) => OrderingTerm.desc(t.lastUsedAt),
              (t) => OrderingTerm.desc(t.id),
            ])
            ..limit(limit))
          .watch();
    }

    if (trimmed.runes.length < 3) {
      final escaped = trimmed
          .replaceAll(r'\', r'\\')
          .replaceAll('%', r'\%')
          .replaceAll('_', r'\_');
      return customSelect(
        '''
        SELECT * FROM clipboard_items
        WHERE plain_text LIKE ? ESCAPE '\\'
        ORDER BY is_pinned DESC, last_used_at DESC, id DESC
        LIMIT ?
        ''',
        variables: [
          Variable.withString('%$escaped%'),
          Variable.withInt(limit),
        ],
        readsFrom: {clipboardItems},
      ).asyncMap((row) => clipboardItems.mapFromRow(row)).watch();
    }

    final ftsQuery = '"${trimmed.replaceAll('"', '""')}"';
    return customSelect(
      '''
      SELECT c.* FROM clipboard_items c
      INNER JOIN clipboard_items_fts fts ON fts.rowid = c.id
      WHERE clipboard_items_fts MATCH ?
      ORDER BY c.is_pinned DESC, c.last_used_at DESC, c.id DESC
      LIMIT ?
      ''',
      variables: [
        Variable.withString(ftsQuery),
        Variable.withInt(limit),
      ],
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
