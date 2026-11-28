import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/omarchy_theme.dart';
import '../../data/settings/app_settings.dart';
import '../../providers/settings_providers.dart';

/// Omarchy-styled inline preferences panel rendered inside the main overlay.
class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({
    super.key,
    required this.onClose,
  });

  final VoidCallback onClose;

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  final TextEditingController _ignoredAppController = TextEditingController();
  final FocusNode _rootFocusNode = FocusNode();
  final FocusNode _hotkeyRecorderFocusNode = FocusNode();

  bool _isRecordingHotKey = false;
  String? _statusMessage;
  bool _statusIsError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _rootFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _ignoredAppController.dispose();
    _rootFocusNode.dispose();
    _hotkeyRecorderFocusNode.dispose();
    super.dispose();
  }

  void _setStatus(String message, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      _statusMessage = message;
      _statusIsError = isError;
    });
  }

  KeyEventResult _handleRootKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (_isRecordingHotKey) {
      return _handleHotKeyCapture(event);
    }

    final key = event.logicalKey;
    final hardware = HardwareKeyboard.instance;
    final isClosePrefs = key == LogicalKeyboardKey.escape ||
        ((Platform.isMacOS ? hardware.isMetaPressed : hardware.isControlPressed) &&
            key == LogicalKeyboardKey.comma);

    if (isClosePrefs) {
      widget.onClose();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  KeyEventResult _handleHotKeyCapture(KeyDownEvent event) {
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      setState(() => _isRecordingHotKey = false);
      _setStatus('hotkey recording cancelled');
      return KeyEventResult.handled;
    }

    if (_isModifierOnlyKey(key)) {
      return KeyEventResult.handled;
    }

    final hardware = HardwareKeyboard.instance;
    final modifiers = <String>[];
    if (hardware.isControlPressed) modifiers.add('control');
    if (hardware.isAltPressed) modifiers.add('alt');
    if (hardware.isShiftPressed) modifiers.add('shift');
    if (hardware.isMetaPressed) modifiers.add('meta');
    modifiers.sort();

    if (modifiers.isEmpty) {
      _setStatus('include at least one modifier (⌘ / ⌃ / ⌥ / ⇧)', isError: true);
      return KeyEventResult.handled;
    }

    final label = _formatKeyLabel(key);
    if (label == null) {
      _setStatus('unsupported key — try A-Z, 0-9, Space, or F1-F12', isError: true);
      return KeyEventResult.handled;
    }

    final candidate = HotKeyConfig(
      usbHidUsage: event.physicalKey.usbHidUsage,
      keyLabel: label,
      modifiers: modifiers,
    );

    setState(() => _isRecordingHotKey = false);
    _applyHotKey(candidate);
    return KeyEventResult.handled;
  }

  Future<void> _applyHotKey(HotKeyConfig candidate) async {
    final ok = await ref
        .read(appSettingsProvider.notifier)
        .setSummonHotKey(candidate);
    if (ok) {
      _setStatus('hotkey updated to ${candidate.formatDisplay()}');
    } else {
      _setStatus('failed to register hotkey (may conflict with OS)', isError: true);
    }
  }

  bool _isModifierOnlyKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.meta ||
        key == LogicalKeyboardKey.metaLeft ||
        key == LogicalKeyboardKey.metaRight ||
        key == LogicalKeyboardKey.control ||
        key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight ||
        key == LogicalKeyboardKey.alt ||
        key == LogicalKeyboardKey.altLeft ||
        key == LogicalKeyboardKey.altRight ||
        key == LogicalKeyboardKey.shift ||
        key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight;
  }

  String? _formatKeyLabel(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.space) return 'SPACE';
    final label = key.keyLabel.trim();
    if (label.isEmpty) return null;
    if (label.length == 1) return label.toUpperCase();
    if (RegExp(r'^F([1-9]|1[0-2])$', caseSensitive: false).hasMatch(label)) {
      return label.toUpperCase();
    }
    return null;
  }

  Future<void> _addIgnoredApp() async {
    final text = _ignoredAppController.text.trim();
    if (text.isEmpty) return;
    await ref.read(appSettingsProvider.notifier).addIgnoredApp(text);
    _ignoredAppController.clear();
    _setStatus('added "$text" to ignored apps');
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final isPaused = ref.watch(monitoringPausedProvider);
    final notifier = ref.read(appSettingsProvider.notifier);

    return Focus(
      focusNode: _rootFocusNode,
      onKeyEvent: _handleRootKey,
      child: Column(
        children: [
          // Header
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: OmarchyTheme.surface,
              border: Border(
                bottom: BorderSide(color: OmarchyTheme.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                Text(
                  ':',
                  style: OmarchyTheme.mono(
                    size: 14,
                    weight: FontWeight.w700,
                    color: OmarchyTheme.accent,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'preferences',
                  style: OmarchyTheme.mono(
                    size: 13,
                    weight: FontWeight.w600,
                    color: OmarchyTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                _ActionChip(
                  label: 'esc back',
                  onTap: widget.onClose,
                ),
              ],
            ),
          ),

          // Body
          Expanded(
            child: Container(
              color: OmarchyTheme.bg,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Global Hotkey
                  _SettingRow(
                    title: 'summon hotkey',
                    subtitle: 'global shortcut to toggle clipm overlay',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _isRecordingHotKey
                                ? OmarchyTheme.accent.withValues(alpha: 0.16)
                                : OmarchyTheme.surface,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: _isRecordingHotKey
                                  ? OmarchyTheme.accent
                                  : OmarchyTheme.border,
                            ),
                          ),
                          child: Text(
                            _isRecordingHotKey
                                ? 'press keys...'
                                : settings.summonHotKey.formatDisplay(),
                            style: OmarchyTheme.mono(
                              size: 12,
                              weight: FontWeight.w600,
                              color: _isRecordingHotKey
                                  ? OmarchyTheme.accent
                                  : OmarchyTheme.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _ActionChip(
                          label: _isRecordingHotKey ? 'cancel' : 'record',
                          active: _isRecordingHotKey,
                          onTap: () {
                            setState(() {
                              _isRecordingHotKey = !_isRecordingHotKey;
                            });
                            _rootFocusNode.requestFocus();
                          },
                        ),
                        const SizedBox(width: 6),
                        _ActionChip(
                          label: 'reset',
                          onTap: () => _applyHotKey(HotKeyConfig.defaultSummon()),
                        ),
                      ],
                    ),
                  ),

                  const _SettingDivider(),

                  // History Capacity
                  _SettingRow(
                    title: 'max unpinned items',
                    subtitle: 'pinned items are exempt from auto-pruning',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final preset in AppSettings.maxUnpinnedPresets) ...[
                          _ChoicePill(
                            label: '$preset',
                            selected: settings.maxUnpinnedItems == preset,
                            onTap: () async {
                              await notifier.setMaxUnpinnedItems(preset);
                              _setStatus('max unpinned limit set to $preset');
                            },
                          ),
                          if (preset != AppSettings.maxUnpinnedPresets.last)
                            const SizedBox(width: 6),
                        ],
                      ],
                    ),
                  ),

                  const _SettingDivider(),

                  // Retention Days
                  _SettingRow(
                    title: 'auto-expire unpinned',
                    subtitle: 'prune unpinned items older than N days',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final days in AppSettings.retentionDayPresets) ...[
                          _ChoicePill(
                            label: days == 0 ? 'never' : '${days}d',
                            selected: settings.retentionDays == days,
                            onTap: () async {
                              await notifier.setRetentionDays(days);
                              _setStatus(
                                days == 0
                                    ? 'auto-expiration disabled'
                                    : 'unpinned items expire after $days days',
                              );
                            },
                          ),
                          if (days != AppSettings.retentionDayPresets.last)
                            const SizedBox(width: 6),
                        ],
                      ],
                    ),
                  ),

                  const _SettingDivider(),

                  // Privacy Pause
                  _SettingRow(
                    title: 'clipboard monitoring',
                    subtitle: 'pause temporarily when copying sensitive data',
                    trailing: _TogglePill(
                      enabled: !isPaused,
                      onLabel: 'ACTIVE',
                      offLabel: 'PAUSED',
                      offColor: OmarchyTheme.pinAccent,
                      onTap: () async {
                        await notifier.toggleMonitoringPaused();
                        _setStatus(
                          ref.read(monitoringPausedProvider)
                              ? 'clipboard monitoring paused'
                              : 'clipboard monitoring resumed',
                        );
                      },
                    ),
                  ),

                  const _SettingDivider(),

                  // Launch at Login
                  _SettingRow(
                    title: 'launch at login',
                    subtitle: 'start clipm automatically on system startup',
                    trailing: _TogglePill(
                      enabled: settings.launchAtLogin,
                      onTap: () async {
                        final next = !settings.launchAtLogin;
                        final ok = await notifier.setLaunchAtLogin(next);
                        if (ok) {
                          _setStatus(
                            next
                                ? 'launch at login enabled'
                                : 'launch at login disabled',
                          );
                        } else {
                          _setStatus(
                            'unable to update login item on this system',
                            isError: true,
                          );
                        }
                      },
                    ),
                  ),

                  const _SettingDivider(),

                  // Multi-Monitor Follow Mouse
                  _SettingRow(
                    title: 'follow mouse display',
                    subtitle: 'center overlay on the screen containing cursor',
                    trailing: _TogglePill(
                      enabled: settings.followMouseScreen,
                      onTap: () async {
                        final next = !settings.followMouseScreen;
                        await notifier.setFollowMouseScreen(next);
                        _setStatus(
                          next
                              ? 'overlay follows active mouse display'
                              : 'overlay uses primary display',
                        );
                      },
                    ),
                  ),

                  const _SettingDivider(),

                  // Ignored Apps
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ignored applications',
                        style: OmarchyTheme.mono(
                          size: 12.5,
                          weight: FontWeight.w600,
                          color: OmarchyTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'clipboard entries from matching app names are skipped',
                        style: OmarchyTheme.mono(
                          size: 11,
                          color: OmarchyTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 30,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: OmarchyTheme.surface,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: OmarchyTheme.border),
                              ),
                              alignment: Alignment.centerLeft,
                              child: TextField(
                                controller: _ignoredAppController,
                                onSubmitted: (_) => _addIgnoredApp(),
                                cursorColor: OmarchyTheme.accent,
                                style: OmarchyTheme.mono(size: 12),
                                decoration: InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  hintText: 'e.g. 1Password, KeePassXC, Bitwarden',
                                  hintStyle: OmarchyTheme.mono(
                                    size: 11.5,
                                    color: OmarchyTheme.textMuted,
                                  ),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _ActionChip(
                            label: '+ add',
                            onTap: _addIgnoredApp,
                          ),
                        ],
                      ),
                      if (settings.ignoredApps.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final app in settings.ignoredApps)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: OmarchyTheme.surface,
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(color: OmarchyTheme.border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      app,
                                      style: OmarchyTheme.mono(
                                        size: 11.5,
                                        color: OmarchyTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () => notifier.removeIgnoredApp(app),
                                      child: Text(
                                        '×',
                                        style: OmarchyTheme.mono(
                                          size: 12,
                                          weight: FontWeight.w700,
                                          color: OmarchyTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Footer status
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: OmarchyTheme.surface,
              border: Border(
                top: BorderSide(color: OmarchyTheme.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _statusMessage ?? 'saved locally to settings.json',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OmarchyTheme.mono(
                      size: 10.5,
                      color: _statusIsError
                          ? OmarchyTheme.danger
                          : OmarchyTheme.textSecondary,
                    ),
                  ),
                ),
                Text(
                  'esc back to history',
                  style: OmarchyTheme.mono(
                    size: 10.5,
                    color: OmarchyTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: OmarchyTheme.mono(
                  size: 12.5,
                  weight: FontWeight.w600,
                  color: OmarchyTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: OmarchyTheme.mono(
                  size: 11,
                  color: OmarchyTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        trailing,
      ],
    );
  }
}

class _SettingDivider extends StatelessWidget {
  const _SettingDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      height: 1,
      color: OmarchyTheme.border.withValues(alpha: 0.7),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? OmarchyTheme.selectionBg : OmarchyTheme.surface,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: selected ? OmarchyTheme.selectionBg : OmarchyTheme.border,
            ),
          ),
          child: Text(
            label,
            style: OmarchyTheme.mono(
              size: 11,
              weight: selected ? FontWeight.w700 : FontWeight.w400,
              color: selected
                  ? OmarchyTheme.selectionFg
                  : OmarchyTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _TogglePill extends StatelessWidget {
  const _TogglePill({
    required this.enabled,
    required this.onTap,
    this.onLabel = 'ON',
    this.offLabel = 'OFF',
    this.offColor = OmarchyTheme.textMuted,
  });

  final bool enabled;
  final VoidCallback onTap;
  final String onLabel;
  final String offLabel;
  final Color offColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: enabled
                ? OmarchyTheme.accent.withValues(alpha: 0.16)
                : OmarchyTheme.surface,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: enabled ? OmarchyTheme.accent : OmarchyTheme.border,
            ),
          ),
          child: Text(
            enabled ? onLabel : offLabel,
            style: OmarchyTheme.mono(
              size: 11,
              weight: FontWeight.w700,
              color: enabled ? OmarchyTheme.accent : offColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: active ? OmarchyTheme.surfaceElevated : OmarchyTheme.bg,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: active ? OmarchyTheme.accent : OmarchyTheme.border,
            ),
          ),
          child: Text(
            label,
            style: OmarchyTheme.mono(
              size: 11,
              color: active ? OmarchyTheme.accent : OmarchyTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
