import 'dart:ui';

class AppConstants {
  const AppConstants._();

  static const String appName = 'clipm';
  static const Size overlayWindowSize = Size(760, 480);
  static const int maxUnpinnedItems = 500;
  static const String imagesSubdir = 'images';

  static const String nativeMethodChannel = 'com.clipm/native_bridge/methods';
  static const String nativeEventChannel = 'com.clipm/native_bridge/events';
}
