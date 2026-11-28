import 'package:drift/drift.dart';

enum ClipboardItemType {
  text,
  richText,
  image,
  file,
}

@TableIndex(name: 'idx_clipboard_sort', columns: {#isPinned, #lastUsedAt})
@TableIndex(name: 'idx_clipboard_hash', columns: {#contentHash})
class ClipboardItems extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Content category: plain text, rich text (HTML + plain fallback), or image.
  IntColumn get type => intEnum<ClipboardItemType>()();

  /// Plain text content (also stores plain-text fallback for richText items).
  TextColumn get plainText => text().nullable()();

  /// Raw HTML/rich payload for richText items.
  TextColumn get richContent => text().nullable()();

  /// Relative path under applicationSupportDirectory (e.g. `images/<sha256>.png`).
  TextColumn get imagePath => text().nullable()();

  /// Image width in pixels.
  IntColumn get imageWidth => integer().nullable()();

  /// Image height in pixels.
  IntColumn get imageHeight => integer().nullable()();

  /// Image file size in bytes.
  IntColumn get imageSizeBytes => integer().nullable()();

  /// SHA-256 content digest for deduplication and asset reference checks.
  TextColumn get contentHash => text()();

  /// Character count for text items.
  IntColumn get charCount => integer().withDefault(const Constant(0))();

  /// Source application name captured when the item was copied.
  TextColumn get sourceApp => text().nullable()();

  /// Pinned items stay at the top and are exempt from auto-pruning.
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();

  /// First capture timestamp.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Most recent copy/bump timestamp used for MRU ordering.
  DateTimeColumn get lastUsedAt => dateTime().withDefault(currentDateAndTime)();
}
