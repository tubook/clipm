import 'dart:io';

import 'package:flutter/material.dart';

/// Omarchy-inspired dark, high-contrast, strictly 1px-bordered monospace theme.
class OmarchyTheme {
  const OmarchyTheme._();

  static const Color bg = Color(0xFF0E1014);
  static const Color surface = Color(0xFF14171D);
  static const Color surfaceElevated = Color(0xFF1A1E26);
  static const Color border = Color(0xFF2B313C);
  static const Color borderActive = Color(0xFF6B7B93);

  static const Color textPrimary = Color(0xFFE6EDF3);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textMuted = Color(0xFF5A6370);

  static const Color selectionBg = Color(0xFFE6EDF3);
  static const Color selectionFg = Color(0xFF0E1014);
  static const Color accent = Color(0xFF79C0FF);
  static const Color pinAccent = Color(0xFFF2CC60);
  static const Color danger = Color(0xFFF85149);

  /// Native system UI font (SF Pro on macOS, Segoe UI on Windows).
  static String get uiFontFamily {
    if (Platform.isMacOS) return '.AppleSystemUIFont';
    if (Platform.isWindows) return 'Segoe UI';
    return 'sans-serif';
  }

  static List<String> get uiFallbacks => const [
        'SF Pro Text',
        'PingFang SC',
        'Hiragino Sans GB',
        'Segoe UI',
        'sans-serif',
      ];

  /// Native system monospace font (SF Mono on macOS, Consolas on Windows).
  static String get monoFontFamily {
    if (Platform.isMacOS) return '.AppleSystemUIFontMonospaced';
    if (Platform.isWindows) return 'Consolas';
    return 'monospace';
  }

  static List<String> get monoFallbacks => const [
        'SF Mono',
        'Menlo',
        'JetBrains Mono',
        'Cascadia Mono',
        'Consolas',
        'monospace',
      ];

  static TextStyle ui({
    double size = 13,
    FontWeight weight = FontWeight.w400,
    Color color = textPrimary,
    double? height,
    double? letterSpacing,
    bool tabularFigures = false,
  }) {
    return TextStyle(
      fontFamily: uiFontFamily,
      fontFamilyFallback: uiFallbacks,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      leadingDistribution: TextLeadingDistribution.even,
      letterSpacing: letterSpacing ?? (Platform.isMacOS ? -0.1 : 0),
      fontFeatures:
          tabularFigures ? const [FontFeature.tabularFigures()] : null,
    );
  }

  static TextStyle mono({
    double size = 12.5,
    FontWeight weight = FontWeight.w400,
    Color color = textPrimary,
    double? height,
  }) {
    return TextStyle(
      fontFamily: monoFontFamily,
      fontFamilyFallback: monoFallbacks,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      leadingDistribution: TextLeadingDistribution.even,
      letterSpacing: 0,
    );
  }

  static ThemeData build() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
      dividerColor: border,
      fontFamily: uiFontFamily,
      fontFamilyFallback: uiFallbacks,
      colorScheme: const ColorScheme.dark(
        surface: surface,
        primary: accent,
        onPrimary: bg,
        onSurface: textPrimary,
        error: danger,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(4),
        radius: const Radius.circular(2),
        thumbColor: WidgetStateProperty.all(borderActive.withValues(alpha: 0.6)),
      ),
    );
  }
}
