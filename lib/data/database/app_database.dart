import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/clipboard_dao.dart';
import 'tables/clipboard_items.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [ClipboardItems],
  daos: [ClipboardDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _createFts5Infrastructure();
        },
        beforeOpen: (OpeningDetails details) async {
          await customStatement('PRAGMA foreign_keys = ON;');
          await customStatement('PRAGMA journal_mode = WAL;');
          await customStatement('PRAGMA synchronous = NORMAL;');
        },
      );

  /// Creates an external-content FTS5 virtual table with trigram tokenizer
  /// (supporting CJK and arbitrary substring matching) and sync triggers.
  Future<void> _createFts5Infrastructure() async {
    await customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS clipboard_items_fts USING fts5(
        plain_text,
        content='clipboard_items',
        content_rowid='id',
        tokenize='trigram'
      );
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS clipboard_items_ai
      AFTER INSERT ON clipboard_items BEGIN
        INSERT INTO clipboard_items_fts(rowid, plain_text)
        VALUES (new.id, COALESCE(new.plain_text, ''));
      END;
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS clipboard_items_ad
      AFTER DELETE ON clipboard_items BEGIN
        INSERT INTO clipboard_items_fts(clipboard_items_fts, rowid, plain_text)
        VALUES ('delete', old.id, COALESCE(old.plain_text, ''));
      END;
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS clipboard_items_au
      AFTER UPDATE OF plain_text ON clipboard_items BEGIN
        INSERT INTO clipboard_items_fts(clipboard_items_fts, rowid, plain_text)
        VALUES ('delete', old.id, COALESCE(old.plain_text, ''));
        INSERT INTO clipboard_items_fts(rowid, plain_text)
        VALUES (new.id, COALESCE(new.plain_text, ''));
      END;
    ''');
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final supportDir = await getApplicationSupportDirectory();
    final dbFile = File(p.join(supportDir.path, 'clipm.sqlite'));
    return NativeDatabase.createInBackground(dbFile);
  });
}
