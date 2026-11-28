import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings/app_settings.dart';
import '../data/settings/settings_service.dart';
import 'service_providers.dart';

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

/// True when clipboard monitoring is temporarily paused (privacy mode).
final monitoringPausedProvider = StateProvider<bool>((ref) => false);

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  return AppSettingsNotifier(ref);
});

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier(this._ref) : super(AppSettings.defaults());

  final Ref _ref;

  Future<AppSettings> load() async {
    final loaded = await _ref.read(settingsServiceProvider).load();
    final osLaunchAtLogin =
        await _ref.read(nativeBridgeProvider).getLaunchAtLogin();
    final merged = loaded.copyWith(launchAtLogin: osLaunchAtLogin);
    state = merged;
    await _ref.read(clipboardMonitorServiceProvider).applySettings(merged);
    return merged;
  }

  Future<void> _persistAndApply(AppSettings next) async {
    state = next;
    await _ref.read(settingsServiceProvider).save(next);
    await _ref.read(clipboardMonitorServiceProvider).applySettings(next);
    await _ref.read(windowControllerServiceProvider).applySettings(next);
  }

  Future<void> setMaxUnpinnedItems(int value) async {
    final clamped = value.clamp(50, 5000);
    await _persistAndApply(state.copyWith(maxUnpinnedItems: clamped));
  }

  Future<void> setRetentionDays(int days) async {
    final clamped = days.clamp(0, 3650);
    await _persistAndApply(state.copyWith(retentionDays: clamped));
  }

  Future<bool> setSummonHotKey(HotKeyConfig hotKey) async {
    final ok = await _ref
        .read(windowControllerServiceProvider)
        .updateSummonHotKey(hotKey);
    if (!ok) return false;
    state = state.copyWith(summonHotKey: hotKey);
    await _ref.read(settingsServiceProvider).save(state);
    return true;
  }

  Future<void> addIgnoredApp(String appName) async {
    final trimmed = appName.trim();
    if (trimmed.isEmpty) return;
    final lower = trimmed.toLowerCase();
    if (state.ignoredApps.any((e) => e.toLowerCase() == lower)) return;
    await _persistAndApply(
      state.copyWith(ignoredApps: [...state.ignoredApps, trimmed]),
    );
  }

  Future<void> removeIgnoredApp(String appName) async {
    final next = state.ignoredApps.where((e) => e != appName).toList();
    await _persistAndApply(state.copyWith(ignoredApps: next));
  }

  Future<bool> setLaunchAtLogin(bool enabled) async {
    final ok = await _ref.read(nativeBridgeProvider).setLaunchAtLogin(enabled);
    if (!ok) return false;
    state = state.copyWith(launchAtLogin: enabled);
    await _ref.read(settingsServiceProvider).save(state);
    return true;
  }

  Future<void> setFollowMouseScreen(bool enabled) async {
    await _persistAndApply(state.copyWith(followMouseScreen: enabled));
  }

  Future<void> toggleMonitoringPaused() async {
    final next = !_ref.read(monitoringPausedProvider);
    _ref.read(monitoringPausedProvider.notifier).state = next;
    _ref.read(clipboardMonitorServiceProvider).setPaused(next);
    await _ref.read(windowControllerServiceProvider).refreshTrayMenu();
  }
}
