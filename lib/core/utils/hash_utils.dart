import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class HashUtils {
  const HashUtils._();

  static String sha256String(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

  static String sha256Bytes(Uint8List bytes) {
    return sha256.convert(bytes).toString();
  }
}
