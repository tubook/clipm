import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'providers/service_providers.dart';
import 'providers/settings_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();

  // Load persisted settings before registering global hotkey and starting monitor.
  final initialSettings =
      await container.read(appSettingsProvider.notifier).load();

  final windowController = container.read(windowControllerServiceProvider);
  await windowController.init(initialSettings: initialSettings);

  final monitorService = container.read(clipboardMonitorServiceProvider);
  await monitorService.start();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ClipmApp(),
    ),
  );
}
