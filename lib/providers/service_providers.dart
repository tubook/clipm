import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../platform/native_bridge.dart';
import '../services/clipboard_monitor_service.dart';
import '../services/window_controller_service.dart';
import 'clipboard_ui_providers.dart';
import 'database_providers.dart';

final nativeBridgeProvider = Provider<NativeBridge>((ref) {
  return NativeBridge();
});

final clipboardMonitorServiceProvider = Provider<ClipboardMonitorService>((ref) {
  final service = ClipboardMonitorService(
    nativeBridge: ref.watch(nativeBridgeProvider),
    clipboardDao: ref.watch(clipboardDaoProvider),
    imageStorage: ref.watch(imageStorageServiceProvider),
  );
  ref.onDispose(service.stop);
  return service;
});

final windowControllerServiceProvider = Provider<WindowControllerService>((ref) {
  final controller = WindowControllerService(
    nativeBridge: ref.watch(nativeBridgeProvider),
    monitorService: ref.watch(clipboardMonitorServiceProvider),
    onOverlayShown: () {
      // Reset search query, selection, and bump focus trigger every time the overlay appears.
      ref.read(searchQueryProvider.notifier).state = '';
      ref.read(selectedIndexProvider.notifier).state = 0;
      ref.read(overlayShowCounterProvider.notifier).state++;
    },
  );
  ref.onDispose(controller.dispose);
  return controller;
});
