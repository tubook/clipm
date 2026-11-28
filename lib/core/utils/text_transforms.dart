import 'dart:convert';

/// Pure text transformation helpers used by the Cmd+K / Ctrl+K Action Palette.
class TextTransforms {
  const TextTransforms._();

  static String trim(String input) => input.trim();

  static String singleLine(String input) {
    return input.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String uppercase(String input) => input.toUpperCase();

  static String lowercase(String input) => input.toLowerCase();

  static List<String> _splitWords(String input) {
    final spaced = input
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (m) => '${m.group(1)} ${m.group(2)}',
        )
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), ' ')
        .trim();
    if (spaced.isEmpty) return const [];
    return spaced.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  }

  static String toCamelCase(String input) {
    final words = _splitWords(input);
    if (words.isEmpty) return input;
    final buf = StringBuffer(words.first.toLowerCase());
    for (var i = 1; i < words.length; i++) {
      final w = words[i].toLowerCase();
      buf.write(w[0].toUpperCase());
      if (w.length > 1) buf.write(w.substring(1));
    }
    return buf.toString();
  }

  static String toSnakeCase(String input) {
    final words = _splitWords(input);
    if (words.isEmpty) return input;
    return words.map((w) => w.toLowerCase()).join('_');
  }

  static String? prettyJson(String input) {
    try {
      final decoded = jsonDecode(input.trim());
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return null;
    }
  }

  static String? minifyJson(String input) {
    try {
      final decoded = jsonDecode(input.trim());
      return jsonEncode(decoded);
    } catch (_) {
      return null;
    }
  }

  static String? urlDecode(String input) {
    try {
      return Uri.decodeComponent(input.trim());
    } catch (_) {
      return null;
    }
  }

  static String urlEncode(String input) {
    return Uri.encodeComponent(input);
  }

  static String? base64DecodeText(String input) {
    try {
      final normalized = base64.normalize(input.trim());
      final bytes = base64.decode(normalized);
      return utf8.decode(bytes);
    } catch (_) {
      return null;
    }
  }

  static String base64EncodeText(String input) {
    return base64.encode(utf8.encode(input));
  }
}
