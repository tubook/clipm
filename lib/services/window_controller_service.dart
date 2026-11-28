import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../core/constants/app_constants.dart';
import '../data/database/app_database.dart';
import '../data/settings/app_settings.dart';
import '../platform/native_bridge.dart';
import 'clipboard_monitor_service.dart';

/// Coordinates borderless overlay window lifecycle, configurable global hotkey,
/// system tray menu, multi-monitor positioning, and focus handoff / paste.
class WindowControllerService with WindowListener, TrayListener {
  WindowControllerService({
    required NativeBridge nativeBridge,
    required ClipboardMonitorService monitorService,
    required VoidCallback onOverlayShown,
    required VoidCallback onOpenSettings,
    required VoidCallback onTogglePause,
  })  : _nativeBridge = nativeBridge,
        _monitorService = monitorService,
        _onOverlayShown = onOverlayShown,
        _onOpenSettings = onOpenSettings,
        _onTogglePause = onTogglePause;

  final NativeBridge _nativeBridge;
  final ClipboardMonitorService _monitorService;
  final VoidCallback _onOverlayShown;
  final VoidCallback _onOpenSettings;
  final VoidCallback _onTogglePause;

  bool _isVisible = false;
  bool _isInitialized = false;
  HotKeyConfig _currentHotKey = HotKeyConfig.defaultSummon();
  bool _followMouseScreen = true;

  Future<void> init({AppSettings? initialSettings}) async {
    if (_isInitialized) return;
    _isInitialized = true;

    if (initialSettings != null) {
      _currentHotKey = initialSettings.summonHotKey;
      _followMouseScreen = initialSettings.followMouseScreen;
    }

    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: AppConstants.overlayWindowSize,
      minimumSize: AppConstants.overlayWindowSize,
      maximumSize: AppConstants.overlayWindowSize,
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: true,
      alwaysOnTop: true,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setAsFrameless();
      await windowManager.setBackgroundColor(Colors.transparent);
      await windowManager.setHasShadow(true);
      await windowManager.setResizable(false);
      await windowManager.setMinimizable(false);
      await windowManager.setMaximizable(false);
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setSkipTaskbar(true);
      await windowManager.hide();
    });

    windowManager.addListener(this);

    await _registerHotKey(_currentHotKey);
    await _initTray();

    if (Platform.isMacOS) {
      // Prompt once for Accessibility permission so Cmd+V paste works seamlessly.
      await _nativeBridge.checkAccessibilityPermission(prompt: true);
    }
  }

  Future<void> applySettings(AppSettings next) async {
    _followMouseScreen = next.followMouseScreen;
    if (next.summonHotKey != _currentHotKey) {
      await updateSummonHotKey(next.summonHotKey);
    }
  }

  Future<bool> updateSummonHotKey(HotKeyConfig next) async {
    final previous = _currentHotKey;
    try {
      await _registerHotKey(next);
      _currentHotKey = next;
      return true;
    } catch (_) {
      try {
        await _registerHotKey(previous);
      } catch (_) {}
      return false;
    }
  }

  Future<void> _registerHotKey(HotKeyConfig config) async {
    await hotKeyManager.unregisterAll();
    await hotKeyManager.register(
      config.toHotKey(),
      keyDownHandler: (_) => toggleOverlay(),
    );
  }

  Future<void> _initTray() async {
    trayManager.addListener(this);
    final iconPath = Platform.isWindows
        ? 'assets/icons/tray_icon.ico'
        : 'assets/icons/tray_icon.png';
    try {
      await trayManager.setIcon(
        iconPath,
        isTemplate: Platform.isMacOS,
      );
    } catch (_) {
      // Fallback gracefully if tray icon asset is missing during dev.
    }

    await refreshTrayMenu();
  }

  Future<void> refreshTrayMenu() async {
    if (!_isInitialized) return;
    final paused = _monitorService.isPaused;
    await trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(key: 'toggle', label: 'Show / Hide clipm'),
          MenuItem(
            key: 'toggle_pause',
            label: paused ? 'Resume Monitoring' : 'Pause Monitoring',
          ),
          MenuItem.separator(),
          MenuItem(key: 'settings', label: 'Settings...'),
          MenuItem(key: 'clear_unpinned', label: 'Clear Unpinned History'),
          MenuItem.separator(),
          MenuItem(key: 'quit', label: 'Quit clipm'),
        ],
      ),
    );
  }

  Future<void> toggleOverlay() async {
    if (_isVisible) {
      await hideOverlay(restoreFocus: true);
    } else {
      await showOverlay();
    }
  }

  Future<void> showOverlay({bool openSettings = false}) async {
    // Capture the active external app BEFORE clipm takes focus.
    await _nativeBridge.capturePreviousApp();

    await _positionOverlay();
    await windowManager.show();
    await windowManager.focus();
    _isVisible = true;
    _onOverlayShown();
    if (openSettings) {
      _onOpenSettings();
    }
  }

  Future<void> _positionOverlay() async {
    if (_followMouseScreen) {
      final workArea = await _nativeBridge.getActiveScreenWorkArea();
      if (workArea != null) {
        const size = AppConstants.overlayWindowSize;
        final x = workArea.left + (workArea.width - size.width) / 2;
        final y = workArea.top + (workArea.height - size.height) / 2;
        await windowManager.setPosition(Offset(x, y));
        return;
      }
    }
    await windowManager.center();
  }

  Future<void> hideOverlay({required bool restoreFocus}) async {
    _isVisible = false;
    if (restoreFocus) {
      await _nativeBridge.restoreFocusAndPaste(simulatePaste: false);
    } else {
      await windowManager.hide();
    }
  }

  /// Writes [item] to the clipboard, hides the overlay, returns focus to the
  /// previous window, and triggers OS-level paste (Cmd+V / Ctrl+V).
  Future<void> pasteItem(
    ClipboardItem item, {
    bool forcePlainText = false,
  }) async {
    await _monitorService.writeItemToClipboard(
      item,
      forcePlainText: forcePlainText,
    );
    _isVisible = false;
    await _nativeBridge.restoreFocusAndPaste(simulatePaste: true);
  }

  Future<void> dispose() async {
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    await hotKeyManager.unregisterAll();
  }

  // --- WindowListener ---
  @override
  void onWindowBlur() {
    // Auto-dismiss when clicking outside the floating overlay.
    if (_isVisible) {
      hideOverlay(restoreFocus: false);
    }
  }

  // --- TrayListener ---
  @override
  void onTrayIconMouseDown() {
    toggleOverlay();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    switch (menuItem.key) {
      case 'toggle':
        await toggleOverlay();
      case 'toggle_pause':
        _onTogglePause();
      case 'settings':
        if (_isVisible) {
          _onOpenSettings();
        } else {
          await showOverlay(openSettings: true);
        }
      case 'clear_unpinned':
        await _monitorService.clearUnpinnedHistory();
      case 'quit':
        await _monitorService.stop();
        await dispose();
        await windowManager.destroy();
        exit(0);
    }
  }
}
