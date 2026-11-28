import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_settings.dart';

/// Persists [AppSettings] atomically as JSON under ApplicationSupport.
class SettingsService {
  SettingsService({Future<Directory> Function()? directoryProvider})
      : _directoryProvider =
            directoryProvider ?? getApplicationSupportDirectory;

  static const String fileName = 'settings.json';

  final Future<Directory> Function() _directoryProvider;

  Future<File> _resolveFile() async {
    final dir = await _directoryProvider();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File(p.join(dir.path, fileName));
  }

  Future<AppSettings> load() async {
    try {
      final file = await _resolveFile();
      if (!await file.exists()) {
        return AppSettings.defaults();
      }
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return AppSettings.defaults();
      }
      return AppSettings.fromJson(decoded);
    } catch (_) {
      return AppSettings.defaults();
    }
  }

  Future<void> save(AppSettings settings) async {
    final file = await _resolveFile();
    final tmpFile = File('${file.path}.tmp');
    final encoded = const JsonEncoder.withIndent('  ').convert(settings.toJson());
    await tmpFile.writeAsString('$encoded\n', flush: true);
    if (await file.exists()) {
      await file.delete();
    }
    await tmpFile.rename(file.path);
  }
}
