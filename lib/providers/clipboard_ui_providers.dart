import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import '../data/database/daos/clipboard_dao.dart';
import 'database_providers.dart';
import 'settings_providers.dart';

/// Current search bar query string.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Active category filter (All / Text / Image / Pinned).
final filterModeProvider =
    StateProvider<ClipboardFilterMode>((ref) => ClipboardFilterMode.all);

/// Whether the inline settings view is currently open inside the overlay.
final isSettingsOpenProvider = StateProvider<bool>((ref) => false);

/// Currently highlighted row index in the filtered history list.
final selectedIndexProvider = StateProvider<int>((ref) => 0);

/// Incremented each time the overlay is summoned so the UI can focus & select search text.
final overlayShowCounterProvider = StateProvider<int>((ref) => 0);

/// Reactive stream of filtered clipboard history items.
final clipboardItemsProvider = StreamProvider<List<ClipboardItem>>((ref) {
  final dao = ref.watch(clipboardDaoProvider);
  final query = ref.watch(searchQueryProvider);
  final filter = ref.watch(filterModeProvider);
  final limit = ref.watch(
    appSettingsProvider.select((s) => s.maxUnpinnedItems + 200),
  );
  return dao.watchItems(query: query, filter: filter, limit: limit);
});

/// Total number of items stored in SQLite (denominator in "12/500").
final clipboardTotalCountProvider = StreamProvider<int>((ref) {
  final dao = ref.watch(clipboardDaoProvider);
  return dao.watchTotalCount();
});
