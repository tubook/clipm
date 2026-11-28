import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

import '../../core/constants/app_constants.dart';

/// Serializable representation of a global summon hotkey.
@immutable
class HotKeyConfig {
  const HotKeyConfig({
    required this.usbHidUsage,
    required this.keyLabel,
    required this.modifiers,
  });

  /// Default summon shortcut: Cmd+Ctrl+V (macOS) / Win+Ctrl+V (Windows).
  factory HotKeyConfig.defaultSummon() {
    return HotKeyConfig(
      usbHidUsage: PhysicalKeyboardKey.keyV.usbHidUsage,
      keyLabel: 'V',
      modifiers: const ['control', 'meta'],
    );
  }

  factory HotKeyConfig.fromJson(Map<String, dynamic> json) {
    final usage = json['usbHidUsage'];
    final label = json['keyLabel'];
    final rawMods = json['modifiers'];

    if (usage is! int || label is! String || rawMods is! List) {
      return HotKeyConfig.defaultSummon();
    }

    final mods = rawMods
        .whereType<String>()
        .where(_allowedModifiers.contains)
        .toSet()
        .toList()
      ..sort();

    if (mods.isEmpty) {
      return HotKeyConfig.defaultSummon();
    }

    return HotKeyConfig(
      usbHidUsage: usage,
      keyLabel: label.toUpperCase(),
      modifiers: List.unmodifiable(mods),
    );
  }

  static const Set<String> _allowedModifiers = {
    'meta',
    'control',
    'alt',
    'shift',
  };

  final int usbHidUsage;
  final String keyLabel;
  final List<String> modifiers;

  Map<String, dynamic> toJson() => {
        'usbHidUsage': usbHidUsage,
        'keyLabel': keyLabel,
        'modifiers': modifiers,
      };

  HotKey toHotKey() {
    final mapped = <HotKeyModifier>[];
    for (final mod in modifiers) {
      switch (mod) {
        case 'meta':
          mapped.add(HotKeyModifier.meta);
        case 'control':
          mapped.add(HotKeyModifier.control);
        case 'alt':
          mapped.add(HotKeyModifier.alt);
        case 'shift':
          mapped.add(HotKeyModifier.shift);
      }
    }
    return HotKey(
      key: PhysicalKeyboardKey(usbHidUsage),
      modifiers: mapped.isEmpty
          ? [HotKeyModifier.meta, HotKeyModifier.control]
          : mapped,
      scope: HotKeyScope.system,
    );
  }

  String formatDisplay({bool? isMacOS}) {
    final mac = isMacOS ?? Platform.isMacOS;
    final ordered = <String>[];
    if (modifiers.contains('control')) ordered.add(mac ? '⌃' : 'Ctrl');
    if (modifiers.contains('alt')) ordered.add(mac ? '⌥' : 'Alt');
    if (modifiers.contains('shift')) ordered.add(mac ? '⇧' : 'Shift');
    if (modifiers.contains('meta')) ordered.add(mac ? '⌘' : 'Win');
    ordered.add(keyLabel);
    return mac ? ordered.join() : ordered.join('+');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HotKeyConfig &&
        other.usbHidUsage == usbHidUsage &&
        other.keyLabel == keyLabel &&
        listEquals(other.modifiers, modifiers);
  }

  @override
  int get hashCode =>
      Object.hash(usbHidUsage, keyLabel, Object.hashAll(modifiers));
}

/// Local user preferences persisted as JSON under ApplicationSupport.
@immutable
class AppSettings {
  const AppSettings({
    this.maxUnpinnedItems = AppConstants.maxUnpinnedItems,
    this.retentionDays = 0,
    required this.summonHotKey,
    this.ignoredApps = const [],
    this.launchAtLogin = false,
    this.followMouseScreen = true,
  });

  factory AppSettings.defaults() {
    return AppSettings(
      maxUnpinnedItems: AppConstants.maxUnpinnedItems,
      retentionDays: 0,
      summonHotKey: HotKeyConfig.defaultSummon(),
      ignoredApps: const [],
      launchAtLogin: false,
      followMouseScreen: true,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final rawMax = json['maxUnpinnedItems'];
    final maxUnpinned =
        rawMax is int ? rawMax.clamp(50, 5000) : AppConstants.maxUnpinnedItems;

    final rawRetention = json['retentionDays'];
    final retention =
        rawRetention is int ? rawRetention.clamp(0, 3650) : 0;

    final rawHotKey = json['summonHotKey'];
    final hotKey = rawHotKey is Map<String, dynamic>
        ? HotKeyConfig.fromJson(rawHotKey)
        : HotKeyConfig.defaultSummon();

    final rawIgnored = json['ignoredApps'];
    final ignored = rawIgnored is List
        ? rawIgnored
            .whereType<String>()
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList()
        : const <String>[];

    final launch = json['launchAtLogin'] is bool
        ? json['launchAtLogin'] as bool
        : false;

    final followMouse = json['followMouseScreen'] is bool
        ? json['followMouseScreen'] as bool
        : true;

    return AppSettings(
      maxUnpinnedItems: maxUnpinned,
      retentionDays: retention,
      summonHotKey: hotKey,
      ignoredApps: List.unmodifiable(ignored),
      launchAtLogin: launch,
      followMouseScreen: followMouse,
    );
  }

  static const List<int> maxUnpinnedPresets = [100, 500, 1000, 2000];
  static const List<int> retentionDayPresets = [0, 7, 30, 90];

  final int maxUnpinnedItems;

  /// 0 means keep unpinned items indefinitely (subject to [maxUnpinnedItems]).
  final int retentionDays;

  final HotKeyConfig summonHotKey;

  /// Case-insensitive application names whose clipboard writes are ignored.
  final List<String> ignoredApps;

  final bool launchAtLogin;
  final bool followMouseScreen;

  bool isAppIgnored(String? sourceApp) {
    if (sourceApp == null || sourceApp.trim().isEmpty || ignoredApps.isEmpty) {
      return false;
    }
    final normalized = sourceApp.trim().toLowerCase();
    for (final entry in ignoredApps) {
      final candidate = entry.trim().toLowerCase();
      if (candidate.isEmpty) continue;
      if (normalized == candidate || normalized.contains(candidate)) {
        return true;
      }
    }
    return false;
  }

  AppSettings copyWith({
    int? maxUnpinnedItems,
    int? retentionDays,
    HotKeyConfig? summonHotKey,
    List<String>? ignoredApps,
    bool? launchAtLogin,
    bool? followMouseScreen,
  }) {
    return AppSettings(
      maxUnpinnedItems: maxUnpinnedItems ?? this.maxUnpinnedItems,
      retentionDays: retentionDays ?? this.retentionDays,
      summonHotKey: summonHotKey ?? this.summonHotKey,
      ignoredApps: ignoredApps != null
          ? List.unmodifiable(ignoredApps)
          : this.ignoredApps,
      launchAtLogin: launchAtLogin ?? this.launchAtLogin,
      followMouseScreen: followMouseScreen ?? this.followMouseScreen,
    );
  }

  Map<String, dynamic> toJson() => {
        'maxUnpinnedItems': maxUnpinnedItems,
        'retentionDays': retentionDays,
        'summonHotKey': summonHotKey.toJson(),
        'ignoredApps': ignoredApps,
        'launchAtLogin': launchAtLogin,
        'followMouseScreen': followMouseScreen,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.maxUnpinnedItems == maxUnpinnedItems &&
        other.retentionDays == retentionDays &&
        other.summonHotKey == summonHotKey &&
        listEquals(other.ignoredApps, ignoredApps) &&
        other.launchAtLogin == launchAtLogin &&
        other.followMouseScreen == followMouseScreen;
  }

  @override
  int get hashCode => Object.hash(
        maxUnpinnedItems,
        retentionDays,
        summonHotKey,
        Object.hashAll(ignoredApps),
        launchAtLogin,
        followMouseScreen,
      );
}
