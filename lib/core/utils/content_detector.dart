import 'dart:convert';
import 'dart:ui';

enum DetectedContentKind {
  plain,
  color,
  url,
  json,
}

class DetectedContent {
  const DetectedContent({
    required this.kind,
    this.color,
    this.normalizedColorHex,
    this.uri,
    this.prettyJson,
  });

  static const DetectedContent plain =
      DetectedContent(kind: DetectedContentKind.plain);

  final DetectedContentKind kind;
  final Color? color;
  final String? normalizedColorHex;
  final Uri? uri;
  final String? prettyJson;
}

/// Lightweight, zero-dependency detector for developer-centric clipboard text
/// (CSS/Hex colors, HTTP(S) URLs, and valid JSON payloads).
class ContentDetector {
  const ContentDetector._();

  static final RegExp _hexPattern = RegExp(
    r'^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$',
  );

  static final RegExp _rgbPattern = RegExp(
    r'^rgba?\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})(?:\s*,\s*(0|1|0?\.\d+))?\s*\)$',
    caseSensitive: false,
  );

  static DetectedContent detect(String rawText) {
    final trimmed = rawText.trim();
    if (trimmed.isEmpty) return DetectedContent.plain;

    final colorMatch = _tryParseColor(trimmed);
    if (colorMatch != null) return colorMatch;

    final uriMatch = _tryParseUrl(trimmed);
    if (uriMatch != null) return uriMatch;

    final jsonMatch = _tryParseJson(trimmed);
    if (jsonMatch != null) return jsonMatch;

    return DetectedContent.plain;
  }

  static DetectedContent? _tryParseColor(String text) {
    final hexMatch = _hexPattern.firstMatch(text);
    if (hexMatch != null) {
      final hex = hexMatch.group(1)!;
      int a = 255;
      int r;
      int g;
      int b;
      if (hex.length == 3) {
        r = int.parse('${hex[0]}${hex[0]}', radix: 16);
        g = int.parse('${hex[1]}${hex[1]}', radix: 16);
        b = int.parse('${hex[2]}${hex[2]}', radix: 16);
      } else if (hex.length == 6) {
        r = int.parse(hex.substring(0, 2), radix: 16);
        g = int.parse(hex.substring(2, 4), radix: 16);
        b = int.parse(hex.substring(4, 6), radix: 16);
      } else {
        // CSS #RRGGBBAA
        r = int.parse(hex.substring(0, 2), radix: 16);
        g = int.parse(hex.substring(2, 4), radix: 16);
        b = int.parse(hex.substring(4, 6), radix: 16);
        a = int.parse(hex.substring(6, 8), radix: 16);
      }
      final color = Color.fromARGB(a, r, g, b);
      final normalized =
          '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'
              .toUpperCase();
      return DetectedContent(
        kind: DetectedContentKind.color,
        color: color,
        normalizedColorHex: normalized,
      );
    }

    final rgbMatch = _rgbPattern.firstMatch(text);
    if (rgbMatch != null) {
      final r = int.parse(rgbMatch.group(1)!);
      final g = int.parse(rgbMatch.group(2)!);
      final b = int.parse(rgbMatch.group(3)!);
      if (r > 255 || g > 255 || b > 255) return null;
      final alphaRaw = rgbMatch.group(4);
      final alpha = alphaRaw != null
          ? (double.parse(alphaRaw).clamp(0.0, 1.0) * 255).round()
          : 255;
      final color = Color.fromARGB(alpha, r, g, b);
      final normalized =
          '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'
              .toUpperCase();
      return DetectedContent(
        kind: DetectedContentKind.color,
        color: color,
        normalizedColorHex: normalized,
      );
    }

    return null;
  }

  static DetectedContent? _tryParseUrl(String text) {
    if (text.contains('\n') || text.contains('\r') || text.contains(' ')) {
      return null;
    }
    final uri = Uri.tryParse(text);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') return null;
    return DetectedContent(
      kind: DetectedContentKind.url,
      uri: uri,
    );
  }

  static DetectedContent? _tryParseJson(String text) {
    final first = text[0];
    final last = text[text.length - 1];
    if (!((first == '{' && last == '}') || (first == '[' && last == ']'))) {
      return null;
    }
    // Avoid parsing huge blobs synchronously on every keystroke.
    if (text.length > 256 * 1024) return null;
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map && decoded is! List) return null;
      final pretty = const JsonEncoder.withIndent('  ').convert(decoded);
      return DetectedContent(
        kind: DetectedContentKind.json,
        prettyJson: pretty,
      );
    } catch (_) {
      return null;
    }
  }
}
