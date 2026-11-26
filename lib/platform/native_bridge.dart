import 'dart:async';

import 'package:flutter/services.dart';

import '../core/constants/app_constants.dart';
import '../data/database/tables/clipboard_items.dart';
import 'native_clipboard_payload.dart';

/// Unified Dart interface over the macOS (Swift) and Windows (C++) native bridges.
class NativeBridge {
  NativeBridge({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  })  : _methodChannel =
            methodChannel ?? const MethodChannel(AppConstants.nativeMethodChannel),
        _eventChannel =
            eventChannel ?? const EventChannel(AppConstants.nativeEventChannel);

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  Stream<NativeClipboardPayload>? _clipboardStream;

  Stream<NativeClipboardPayload> get clipboardChanges {
    return _clipboardStream ??= _eventChannel
        .receiveBroadcastStream()
        .where((event) => event is Map)
        .map((event) => NativeClipboardPayload.fromMap(event as Map<Object?, Object?>))
        .where((payload) => payload != null)
        .cast<NativeClipboardPayload>();
  }

  Future<void> startMonitoring() async {
    await _methodChannel.invokeMethod<void>('startMonitoring');
  }

  Future<void> stopMonitoring() async {
    await _methodChannel.invokeMethod<void>('stopMonitoring');
  }

  /// Captures the currently focused foreground app/window before showing clipm.
  Future<void> capturePreviousApp() async {
    await _methodChannel.invokeMethod<void>('capturePreviousApp');
  }

  /// Writes an item back to the OS clipboard with loop-prevention markers.
  Future<void> writeClipboard({
    required ClipboardItemType type,
    String? plainText,
    String? richContent,
    Uint8List? imageBytes,
  }) async {
    final typeName = switch (type) {
      ClipboardItemType.image => 'image',
      ClipboardItemType.richText => 'richText',
      ClipboardItemType.text => 'text',
    };

    await _methodChannel.invokeMethod<void>('writeClipboard', <String, dynamic>{
      'type': typeName,
      if (plainText != null) 'plainText': plainText,
      if (richContent != null) 'richContent': richContent,
      if (imageBytes != null) 'imageBytes': imageBytes,
    });
  }

  /// Hides the overlay, restores focus to the previous app, and optionally
  /// synthesizes Cmd+V (macOS) or Ctrl+V (Windows).
  Future<void> restoreFocusAndPaste({required bool simulatePaste}) async {
    await _methodChannel.invokeMethod<void>(
      'restoreFocusAndPaste',
      <String, dynamic>{'simulatePaste': simulatePaste},
    );
  }

  /// macOS only: checks Accessibility permission required for CGEvent paste.
  Future<bool> checkAccessibilityPermission({bool prompt = false}) async {
    final granted = await _methodChannel.invokeMethod<bool>(
      'checkAccessibilityPermission',
      <String, dynamic>{'prompt': prompt},
    );
    return granted ?? true;
  }
}
