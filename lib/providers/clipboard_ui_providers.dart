import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import 'database_providers.dart';

/// Current search bar query string.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Currently highlighted row index in the filtered history list.
final selectedIndexProvider = StateProvider<int>((ref) => 0);

/// Incremented each time the overlay is summoned so the UI can focus & select search text.
final overlayShowCounterProvider = StateProvider<int>((ref) => 0);

/// Reactive stream of filtered clipboard history items.
final clipboardItemsProvider = StreamProvider<List<ClipboardItem>>((ref) {
  final dao = ref.watch(clipboardDaoProvider);
  final query = ref.watch(searchQueryProvider);
  return dao.watchItems(query: query);
});

/// Total number of items stored in SQLite (denominator in "12/500").
final clipboardTotalCountProvider = StreamProvider<int>((ref) {
  final dao = ref.watch(clipboardDaoProvider);
  return dao.watchTotalCount();
});
