import 'package:clipm/data/database/app_database.dart';
import 'package:clipm/data/database/daos/clipboard_dao.dart';
import 'package:clipm/data/database/tables/clipboard_items.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ClipboardDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.clipboardDao;
  });

  tearDown(() async {
    await db.close();
  });

  test('ignores consecutive duplicate hash and bumps older duplicates', () async {
    final r1 = await dao.insertOrBump(
      ClipboardItemsCompanion.insert(
        type: ClipboardItemType.text,
        plainText: const Value('hello world'),
        contentHash: 'hash_a',
        charCount: const Value(11),
      ),
    );
    expect(r1.ignoredAsDuplicate, isFalse);

    // Consecutive duplicate -> ignored
    final r2 = await dao.insertOrBump(
      ClipboardItemsCompanion.insert(
        type: ClipboardItemType.text,
        plainText: const Value('hello world'),
        contentHash: 'hash_a',
        charCount: const Value(11),
      ),
    );
    expect(r2.ignoredAsDuplicate, isTrue);

    await dao.insertOrBump(
      ClipboardItemsCompanion.insert(
        type: ClipboardItemType.text,
        plainText: const Value('second entry'),
        contentHash: 'hash_b',
        charCount: const Value(12),
      ),
    );

    // Older duplicate -> bumped to top without creating a 3rd row
    final r3 = await dao.insertOrBump(
      ClipboardItemsCompanion.insert(
        type: ClipboardItemType.text,
        plainText: const Value('hello world'),
        contentHash: 'hash_a',
        charCount: const Value(11),
      ),
    );
    expect(r3.ignoredAsDuplicate, isFalse);

    final items = await dao.watchItems().first;
    expect(items.length, 2);
    expect(items.first.contentHash, 'hash_a');
  });

  test('prunes oldest unpinned entries beyond maxUnpinned while keeping pinned items', () async {
    final pinned = await dao.insertOrBump(
      ClipboardItemsCompanion.insert(
        type: ClipboardItemType.image,
        imagePath: const Value('images/pinned.png'),
        contentHash: 'hash_pinned',
      ),
      maxUnpinned: 2,
    );
    await dao.togglePin(pinned.itemId!);

    await dao.insertOrBump(
      ClipboardItemsCompanion.insert(
        type: ClipboardItemType.image,
        imagePath: const Value('images/old1.png'),
        contentHash: 'hash_1',
      ),
      maxUnpinned: 2,
    );
    await dao.insertOrBump(
      ClipboardItemsCompanion.insert(
        type: ClipboardItemType.text,
        plainText: const Value('keep me'),
        contentHash: 'hash_2',
      ),
      maxUnpinned: 2,
    );
    final overflow = await dao.insertOrBump(
      ClipboardItemsCompanion.insert(
        type: ClipboardItemType.text,
        plainText: const Value('newest'),
        contentHash: 'hash_3',
      ),
      maxUnpinned: 2,
    );

    expect(overflow.orphanedImagePaths, ['images/old1.png']);
    final items = await dao.watchItems().first;
    expect(items.length, 3); // 1 pinned + 2 unpinned
    expect(items.first.isPinned, isTrue);
    expect(items.map((e) => e.contentHash), ['hash_pinned', 'hash_3', 'hash_2']);
  });

  test('supports FTS5 trigram search (>=3 chars) and LIKE fallback (1-2 chars)', () async {
    await dao.insertOrBump(
      ClipboardItemsCompanion.insert(
        type: ClipboardItemType.text,
        plainText: const Value('Omarchy 剪贴板历史管理工具'),
        contentHash: 'hash_zh',
      ),
    );
    await dao.insertOrBump(
      ClipboardItemsCompanion.insert(
        type: ClipboardItemType.text,
        plainText: const Value('flutter_riverpod state management'),
        contentHash: 'hash_en',
      ),
    );

    final ftsEn = await dao.watchItems(query: 'riverpod').first;
    expect(ftsEn.length, 1);
    expect(ftsEn.first.contentHash, 'hash_en');

    final ftsZh = await dao.watchItems(query: '剪贴板').first;
    expect(ftsZh.length, 1);
    expect(ftsZh.first.contentHash, 'hash_zh');

    final shortLike = await dao.watchItems(query: '历史').first;
    expect(shortLike.length, 1);
    expect(shortLike.first.contentHash, 'hash_zh');
  });
}
