import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import '../data/database/daos/clipboard_dao.dart';
import '../data/storage/image_storage_service.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final clipboardDaoProvider = Provider<ClipboardDao>((ref) {
  return ref.watch(appDatabaseProvider).clipboardDao;
});

final imageStorageServiceProvider = Provider<ImageStorageService>((ref) {
  return ImageStorageService();
});
