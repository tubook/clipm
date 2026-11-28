import 'dart:io';

import 'package:clipm/data/settings/app_settings.dart';
import 'package:clipm/data/settings/settings_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('AppSettings & HotKeyConfig', () {
    test('round-trips JSON and formats platform hotkeys', () {
      final original = AppSettings(
        maxUnpinnedItems: 1000,
        retentionDays: 30,
        summonHotKey: HotKeyConfig(
          usbHidUsage: PhysicalKeyboardKey.keyK.usbHidUsage,
          keyLabel: 'K',
          modifiers: const ['alt', 'meta'],
        ),
        ignoredApps: const ['1Password', 'KeePassXC'],
        launchAtLogin: true,
        followMouseScreen: false,
      );

      final decoded = AppSettings.fromJson(original.toJson());
      expect(decoded, original);
      expect(decoded.summonHotKey.formatDisplay(isMacOS: true), '⌥⌘K');
      expect(decoded.summonHotKey.formatDisplay(isMacOS: false), 'Alt+Win+K');
    });

    test('clamps invalid numeric bounds and falls back on malformed fields', () {
      final decoded = AppSettings.fromJson({
        'maxUnpinnedItems': 5,
        'retentionDays': -10,
        'summonHotKey': {'usbHidUsage': 'bad'},
        'ignoredApps': ['  1Password  ', '', 123, '1Password'],
        'launchAtLogin': 'yes',
      });

      expect(decoded.maxUnpinnedItems, 50);
      expect(decoded.retentionDays, 0);
      expect(decoded.summonHotKey, HotKeyConfig.defaultSummon());
      expect(decoded.ignoredApps, ['1Password']);
      expect(decoded.launchAtLogin, isFalse);
      expect(decoded.followMouseScreen, isTrue);
    });

    test('matches ignored applications case-insensitively', () {
      final settings = AppSettings.defaults().copyWith(
        ignoredApps: const ['1Password', 'keepass'],
      );

      expect(settings.isAppIgnored('1password'), isTrue);
      expect(settings.isAppIgnored('KeePassXC'), isTrue);
      expect(settings.isAppIgnored('Visual Studio Code'), isFalse);
      expect(settings.isAppIgnored(null), isFalse);
    });
  });

  group('SettingsService', () {
    late Directory tempDir;
    late SettingsService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('clipm_settings_test_');
      service = SettingsService(directoryProvider: () async => tempDir);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('returns defaults when file does not exist and persists updates', () async {
      expect(await service.load(), AppSettings.defaults());

      final updated = AppSettings.defaults().copyWith(
        maxUnpinnedItems: 2000,
        retentionDays: 90,
        ignoredApps: const ['Bitwarden'],
        followMouseScreen: false,
      );
      await service.save(updated);

      expect(await service.load(), updated);
    });

    test('recovers safely with defaults when settings.json is corrupted', () async {
      final file = File(p.join(tempDir.path, SettingsService.fileName));
      await file.writeAsString('{corrupt json');

      expect(await service.load(), AppSettings.defaults());
    });
  });
}
