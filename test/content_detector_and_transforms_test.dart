import 'package:clipm/core/utils/content_detector.dart';
import 'package:clipm/core/utils/text_transforms.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContentDetector', () {
    test('detects hex and rgb/rgba colors', () {
      final hex6 = ContentDetector.detect('#79c0ff');
      expect(hex6.kind, DetectedContentKind.color);
      expect(hex6.normalizedColorHex, '#79C0FF');

      final hex3 = ContentDetector.detect('#f0a');
      expect(hex3.kind, DetectedContentKind.color);
      expect(hex3.normalizedColorHex, '#FF00AA');

      final rgb = ContentDetector.detect('rgb(14, 16, 20)');
      expect(rgb.kind, DetectedContentKind.color);
      expect(rgb.normalizedColorHex, '#0E1014');

      final invalidRgb = ContentDetector.detect('rgb(300, 0, 0)');
      expect(invalidRgb.kind, DetectedContentKind.plain);
    });

    test('detects single-line HTTP(S) URLs only', () {
      final url = ContentDetector.detect('https://github.com/tubook/clipm');
      expect(url.kind, DetectedContentKind.url);
      expect(url.uri?.host, 'github.com');

      expect(
        ContentDetector.detect('ftp://example.com/file').kind,
        DetectedContentKind.plain,
      );
      expect(
        ContentDetector.detect('https://a.com\nhttps://b.com').kind,
        DetectedContentKind.plain,
      );
    });

    test('detects valid JSON objects/arrays and formats pretty JSON', () {
      final json = ContentDetector.detect('{"name":"clipm","version":2}');
      expect(json.kind, DetectedContentKind.json);
      expect(json.prettyJson, contains('\n  "name": "clipm"'));

      final arr = ContentDetector.detect('[1,2,3]');
      expect(arr.kind, DetectedContentKind.json);

      expect(
        ContentDetector.detect('{not valid json}').kind,
        DetectedContentKind.plain,
      );
    });
  });

  group('TextTransforms', () {
    test('handles whitespace and casing transforms', () {
      expect(TextTransforms.trim('  hello \n '), 'hello');
      expect(TextTransforms.singleLine('line1\n  line2\tline3'), 'line1 line2 line3');
      expect(TextTransforms.uppercase('clipm'), 'CLIPM');
      expect(TextTransforms.lowercase('CLIPM'), 'clipm');
      expect(TextTransforms.toCamelCase('clipboard_history_item'), 'clipboardHistoryItem');
      expect(TextTransforms.toSnakeCase('ClipboardHistoryItem'), 'clipboard_history_item');
    });

    test('handles JSON, URL, and Base64 transforms', () {
      expect(TextTransforms.minifyJson('{\n  "a": 1\n}'), '{"a":1}');
      expect(TextTransforms.prettyJson('{"a":1}'), '{\n  "a": 1\n}');
      expect(TextTransforms.urlEncode('a b/c'), 'a%20b%2Fc');
      expect(TextTransforms.urlDecode('a%20b%2Fc'), 'a b/c');
      expect(TextTransforms.base64EncodeText('clipm'), 'Y2xpcG0=');
      expect(TextTransforms.base64DecodeText('Y2xpcG0='), 'clipm');
      expect(TextTransforms.base64DecodeText('not-base64!!!'), isNull);
    });
  });
}
