import 'dart:typed_data';

import '../data/database/tables/clipboard_items.dart';

class NativeClipboardPayload {
  const NativeClipboardPayload({
    required this.type,
    this.plainText,
    this.richContent,
    this.imageBytes,
    this.imageWidth,
    this.imageHeight,
    this.filePaths,
    this.sourceApp,
  });

  final ClipboardItemType type;
  final String? plainText;
  final String? richContent;
  final Uint8List? imageBytes;
  final int? imageWidth;
  final int? imageHeight;
  final List<String>? filePaths;
  final String? sourceApp;

  static NativeClipboardPayload? fromMap(Map<Object?, Object?> raw) {
    final typeStr = raw['type'] as String?;
    if (typeStr == null) return null;

    final type = switch (typeStr) {
      'image' => ClipboardItemType.image,
      'richText' => ClipboardItemType.richText,
      'file' => ClipboardItemType.file,
      _ => ClipboardItemType.text,
    };

    final rawFiles = raw['filePaths'];
    final filePaths = rawFiles is List
        ? rawFiles.whereType<String>().where((p) => p.isNotEmpty).toList()
        : null;

    return NativeClipboardPayload(
      type: type,
      plainText: raw['plainText'] as String?,
      richContent: raw['richContent'] as String?,
      imageBytes: raw['imageBytes'] as Uint8List?,
      imageWidth: (raw['imageWidth'] as num?)?.toInt(),
      imageHeight: (raw['imageHeight'] as num?)?.toInt(),
      filePaths: filePaths,
      sourceApp: raw['sourceApp'] as String?,
    );
  }
}
