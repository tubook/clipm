// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clipboard_dao.dart';

// ignore_for_file: type=lint
mixin _$ClipboardDaoMixin on DatabaseAccessor<AppDatabase> {
  $ClipboardItemsTable get clipboardItems => attachedDatabase.clipboardItems;
  ClipboardDaoManager get managers => ClipboardDaoManager(this);
}

class ClipboardDaoManager {
  final _$ClipboardDaoMixin _db;
  ClipboardDaoManager(this._db);
  $$ClipboardItemsTableTableManager get clipboardItems =>
      $$ClipboardItemsTableTableManager(
          _db.attachedDatabase, _db.clipboardItems);
}
