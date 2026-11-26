import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'providers/service_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();

  // Initialize desktop window, global hotkey (Cmd/Win+Ctrl+V), tray, and native monitor.
  final windowController = container.read(windowControllerServiceProvider);
  await windowController.init();

  final monitorService = container.read(clipboardMonitorServiceProvider);
  await monitorService.start();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ClipmApp(),
    ),
  );
}
