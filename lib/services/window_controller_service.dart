import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../core/constants/app_constants.dart';
import '../data/database/app_database.dart';
import '../platform/native_bridge.dart';
import 'clipboard_monitor_service.dart';

/// Coordinates borderless overlay window lifecycle, global hotkey
/// (Cmd/Win + Ctrl + V), system tray menu, and focus handoff / paste.
class WindowControllerService with WindowListener, TrayListener {
  WindowControllerService({
    required NativeBridge nativeBridge,
    required ClipboardMonitorService monitorService,
    required VoidCallback onOverlayShown,
  })  : _nativeBridge = nativeBridge,
        _monitorService = monitorService,
        _onOverlayShown = onOverlayShown;

  final NativeBridge _nativeBridge;
  final ClipboardMonitorService _monitorService;
  final VoidCallback _onOverlayShown;

  bool _isVisible = false;
  bool _isInitialized = false;

  /// Global summon shortcut: Cmd + Ctrl + V (macOS) / Win + Ctrl + V (Windows).
  static final HotKey summonHotKey = HotKey(
    key: PhysicalKeyboardKey.keyV,
    modifiers: [HotKeyModifier.meta, HotKeyModifier.control],
    scope: HotKeyScope.system,
  );

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: AppConstants.overlayWindowSize,
      minimumSize: AppConstants.overlayWindowSize,
      maximumSize: AppConstants.overlayWindowSize,
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: true,
      titleBarStyle: TitleBarStyle.hidden,
      alwaysOnTop: true,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setAsFrameless();
      await windowManager.setResizable(false);
      await windowManager.setMinimizable(false);
      await windowManager.setMaximizable(false);
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setSkipTaskbar(true);
      await windowManager.hide();
    });

    windowManager.addListener(this);

    await _registerHotKey();
    await _initTray();

    if (Platform.isMacOS) {
      // Prompt once for Accessibility permission so Cmd+V paste works seamlessly.
      await _nativeBridge.checkAccessibilityPermission(prompt: true);
    }
  }

  Future<void> _registerHotKey() async {
    await hotKeyManager.unregisterAll();
    await hotKeyManager.register(
      summonHotKey,
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

    await trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(key: 'toggle', label: 'Show / Hide clipm'),
          MenuItem.separator(),
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

  Future<void> showOverlay() async {
    // Capture the active external app BEFORE clipm takes focus.
    await _nativeBridge.capturePreviousApp();

    await windowManager.center();
    await windowManager.show();
    await windowManager.focus();
    _isVisible = true;
    _onOverlayShown();
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
