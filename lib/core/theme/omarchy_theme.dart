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

  static String get monoFontFamily {
    if (Platform.isMacOS) return 'Menlo';
    if (Platform.isWindows) return 'Consolas';
    return 'monospace';
  }

  static List<String> get monoFallbacks => const [
        'JetBrains Mono',
        'SF Mono',
        'Cascadia Mono',
        'Menlo',
        'Consolas',
        'monospace',
      ];

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
      letterSpacing: 0,
    );
  }

  static ThemeData build() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
      dividerColor: border,
      fontFamily: monoFontFamily,
      colorScheme: const ColorScheme.dark(
        surface: surface,
        primary: accent,
        onPrimary: bg,
        onSurface: textPrimary,
        error: danger,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(4),
        radius: Radius.zero,
        thumbColor: WidgetStateProperty.all(borderActive.withValues(alpha: 0.6)),
      ),
    );
  }
}
