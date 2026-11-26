// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ClipboardItemsTable extends ClipboardItems
    with TableInfo<$ClipboardItemsTable, ClipboardItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClipboardItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  @override
  late final GeneratedColumnWithTypeConverter<ClipboardItemType, int> type =
      GeneratedColumn<int>('type', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<ClipboardItemType>(
              $ClipboardItemsTable.$convertertype);
  static const VerificationMeta _plainTextMeta =
      const VerificationMeta('plainText');
  @override
  late final GeneratedColumn<String> plainText = GeneratedColumn<String>(
      'plain_text', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _richContentMeta =
      const VerificationMeta('richContent');
  @override
  late final GeneratedColumn<String> richContent = GeneratedColumn<String>(
      'rich_content', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _imagePathMeta =
      const VerificationMeta('imagePath');
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
      'image_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _imageWidthMeta =
      const VerificationMeta('imageWidth');
  @override
  late final GeneratedColumn<int> imageWidth = GeneratedColumn<int>(
      'image_width', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _imageHeightMeta =
      const VerificationMeta('imageHeight');
  @override
  late final GeneratedColumn<int> imageHeight = GeneratedColumn<int>(
      'image_height', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _imageSizeBytesMeta =
      const VerificationMeta('imageSizeBytes');
  @override
  late final GeneratedColumn<int> imageSizeBytes = GeneratedColumn<int>(
      'image_size_bytes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _contentHashMeta =
      const VerificationMeta('contentHash');
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
      'content_hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _charCountMeta =
      const VerificationMeta('charCount');
  @override
  late final GeneratedColumn<int> charCount = GeneratedColumn<int>(
      'char_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _sourceAppMeta =
      const VerificationMeta('sourceApp');
  @override
  late final GeneratedColumn<String> sourceApp = GeneratedColumn<String>(
      'source_app', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isPinnedMeta =
      const VerificationMeta('isPinned');
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
      'is_pinned', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_pinned" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _lastUsedAtMeta =
      const VerificationMeta('lastUsedAt');
  @override
  late final GeneratedColumn<DateTime> lastUsedAt = GeneratedColumn<DateTime>(
      'last_used_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        type,
        plainText,
        richContent,
        imagePath,
        imageWidth,
        imageHeight,
        imageSizeBytes,
        contentHash,
        charCount,
        sourceApp,
        isPinned,
        createdAt,
        lastUsedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clipboard_items';
  @override
  VerificationContext validateIntegrity(Insertable<ClipboardItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('plain_text')) {
      context.handle(_plainTextMeta,
          plainText.isAcceptableOrUnknown(data['plain_text']!, _plainTextMeta));
    }
    if (data.containsKey('rich_content')) {
      context.handle(
          _richContentMeta,
          richContent.isAcceptableOrUnknown(
              data['rich_content']!, _richContentMeta));
    }
    if (data.containsKey('image_path')) {
      context.handle(_imagePathMeta,
          imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta));
    }
    if (data.containsKey('image_width')) {
      context.handle(
          _imageWidthMeta,
          imageWidth.isAcceptableOrUnknown(
              data['image_width']!, _imageWidthMeta));
    }
    if (data.containsKey('image_height')) {
      context.handle(
          _imageHeightMeta,
          imageHeight.isAcceptableOrUnknown(
              data['image_height']!, _imageHeightMeta));
    }
    if (data.containsKey('image_size_bytes')) {
      context.handle(
          _imageSizeBytesMeta,
          imageSizeBytes.isAcceptableOrUnknown(
              data['image_size_bytes']!, _imageSizeBytesMeta));
    }
    if (data.containsKey('content_hash')) {
      context.handle(
          _contentHashMeta,
          contentHash.isAcceptableOrUnknown(
              data['content_hash']!, _contentHashMeta));
    } else if (isInserting) {
      context.missing(_contentHashMeta);
    }
    if (data.containsKey('char_count')) {
      context.handle(_charCountMeta,
          charCount.isAcceptableOrUnknown(data['char_count']!, _charCountMeta));
    }
    if (data.containsKey('source_app')) {
      context.handle(_sourceAppMeta,
          sourceApp.isAcceptableOrUnknown(data['source_app']!, _sourceAppMeta));
    }
    if (data.containsKey('is_pinned')) {
      context.handle(_isPinnedMeta,
          isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
          _lastUsedAtMeta,
          lastUsedAt.isAcceptableOrUnknown(
              data['last_used_at']!, _lastUsedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClipboardItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClipboardItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      type: $ClipboardItemsTable.$convertertype.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}type'])!),
      plainText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plain_text']),
      richContent: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rich_content']),
      imagePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_path']),
      imageWidth: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}image_width']),
      imageHeight: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}image_height']),
      imageSizeBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}image_size_bytes']),
      contentHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_hash'])!,
      charCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}char_count'])!,
      sourceApp: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_app']),
      isPinned: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_pinned'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      lastUsedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_used_at'])!,
    );
  }

  @override
  $ClipboardItemsTable createAlias(String alias) {
    return $ClipboardItemsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ClipboardItemType, int, int> $convertertype =
      const EnumIndexConverter<ClipboardItemType>(ClipboardItemType.values);
}

class ClipboardItem extends DataClass implements Insertable<ClipboardItem> {
  final int id;

  /// Content category: plain text, rich text (HTML + plain fallback), or image.
  final ClipboardItemType type;

  /// Plain text content (also stores plain-text fallback for richText items).
  final String? plainText;

  /// Raw HTML/rich payload for richText items.
  final String? richContent;

  /// Relative path under applicationSupportDirectory (e.g. "images/<sha256>.png").
  final String? imagePath;

  /// Image width in pixels.
  final int? imageWidth;

  /// Image height in pixels.
  final int? imageHeight;

  /// Image file size in bytes.
  final int? imageSizeBytes;

  /// SHA-256 content digest for deduplication and asset reference checks.
  final String contentHash;

  /// Character count for text items.
  final int charCount;

  /// Source application name captured when the item was copied.
  final String? sourceApp;

  /// Pinned items stay at the top and are exempt from auto-pruning.
  final bool isPinned;

  /// First capture timestamp.
  final DateTime createdAt;

  /// Most recent copy/bump timestamp used for MRU ordering.
  final DateTime lastUsedAt;
  const ClipboardItem(
      {required this.id,
      required this.type,
      this.plainText,
      this.richContent,
      this.imagePath,
      this.imageWidth,
      this.imageHeight,
      this.imageSizeBytes,
      required this.contentHash,
      required this.charCount,
      this.sourceApp,
      required this.isPinned,
      required this.createdAt,
      required this.lastUsedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['type'] =
          Variable<int>($ClipboardItemsTable.$convertertype.toSql(type));
    }
    if (!nullToAbsent || plainText != null) {
      map['plain_text'] = Variable<String>(plainText);
    }
    if (!nullToAbsent || richContent != null) {
      map['rich_content'] = Variable<String>(richContent);
    }
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    if (!nullToAbsent || imageWidth != null) {
      map['image_width'] = Variable<int>(imageWidth);
    }
    if (!nullToAbsent || imageHeight != null) {
      map['image_height'] = Variable<int>(imageHeight);
    }
    if (!nullToAbsent || imageSizeBytes != null) {
      map['image_size_bytes'] = Variable<int>(imageSizeBytes);
    }
    map['content_hash'] = Variable<String>(contentHash);
    map['char_count'] = Variable<int>(charCount);
    if (!nullToAbsent || sourceApp != null) {
      map['source_app'] = Variable<String>(sourceApp);
    }
    map['is_pinned'] = Variable<bool>(isPinned);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_used_at'] = Variable<DateTime>(lastUsedAt);
    return map;
  }

  ClipboardItemsCompanion toCompanion(bool nullToAbsent) {
    return ClipboardItemsCompanion(
      id: Value(id),
      type: Value(type),
      plainText: plainText == null && nullToAbsent
          ? const Value.absent()
          : Value(plainText),
      richContent: richContent == null && nullToAbsent
          ? const Value.absent()
          : Value(richContent),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      imageWidth: imageWidth == null && nullToAbsent
          ? const Value.absent()
          : Value(imageWidth),
      imageHeight: imageHeight == null && nullToAbsent
          ? const Value.absent()
          : Value(imageHeight),
      imageSizeBytes: imageSizeBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(imageSizeBytes),
      contentHash: Value(contentHash),
      charCount: Value(charCount),
      sourceApp: sourceApp == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceApp),
      isPinned: Value(isPinned),
      createdAt: Value(createdAt),
      lastUsedAt: Value(lastUsedAt),
    );
  }

  factory ClipboardItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClipboardItem(
      id: serializer.fromJson<int>(json['id']),
      type: $ClipboardItemsTable.$convertertype
          .fromJson(serializer.fromJson<int>(json['type'])),
      plainText: serializer.fromJson<String?>(json['plainText']),
      richContent: serializer.fromJson<String?>(json['richContent']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      imageWidth: serializer.fromJson<int?>(json['imageWidth']),
      imageHeight: serializer.fromJson<int?>(json['imageHeight']),
      imageSizeBytes: serializer.fromJson<int?>(json['imageSizeBytes']),
      contentHash: serializer.fromJson<String>(json['contentHash']),
      charCount: serializer.fromJson<int>(json['charCount']),
      sourceApp: serializer.fromJson<String?>(json['sourceApp']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastUsedAt: serializer.fromJson<DateTime>(json['lastUsedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer
          .toJson<int>($ClipboardItemsTable.$convertertype.toJson(type)),
      'plainText': serializer.toJson<String?>(plainText),
      'richContent': serializer.toJson<String?>(richContent),
      'imagePath': serializer.toJson<String?>(imagePath),
      'imageWidth': serializer.toJson<int?>(imageWidth),
      'imageHeight': serializer.toJson<int?>(imageHeight),
      'imageSizeBytes': serializer.toJson<int?>(imageSizeBytes),
      'contentHash': serializer.toJson<String>(contentHash),
      'charCount': serializer.toJson<int>(charCount),
      'sourceApp': serializer.toJson<String?>(sourceApp),
      'isPinned': serializer.toJson<bool>(isPinned),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastUsedAt': serializer.toJson<DateTime>(lastUsedAt),
    };
  }

  ClipboardItem copyWith(
          {int? id,
          ClipboardItemType? type,
          Value<String?> plainText = const Value.absent(),
          Value<String?> richContent = const Value.absent(),
          Value<String?> imagePath = const Value.absent(),
          Value<int?> imageWidth = const Value.absent(),
          Value<int?> imageHeight = const Value.absent(),
          Value<int?> imageSizeBytes = const Value.absent(),
          String? contentHash,
          int? charCount,
          Value<String?> sourceApp = const Value.absent(),
          bool? isPinned,
          DateTime? createdAt,
          DateTime? lastUsedAt}) =>
      ClipboardItem(
        id: id ?? this.id,
        type: type ?? this.type,
        plainText: plainText.present ? plainText.value : this.plainText,
        richContent: richContent.present ? richContent.value : this.richContent,
        imagePath: imagePath.present ? imagePath.value : this.imagePath,
        imageWidth: imageWidth.present ? imageWidth.value : this.imageWidth,
        imageHeight: imageHeight.present ? imageHeight.value : this.imageHeight,
        imageSizeBytes:
            imageSizeBytes.present ? imageSizeBytes.value : this.imageSizeBytes,
        contentHash: contentHash ?? this.contentHash,
        charCount: charCount ?? this.charCount,
        sourceApp: sourceApp.present ? sourceApp.value : this.sourceApp,
        isPinned: isPinned ?? this.isPinned,
        createdAt: createdAt ?? this.createdAt,
        lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      );
  ClipboardItem copyWithCompanion(ClipboardItemsCompanion data) {
    return ClipboardItem(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      plainText: data.plainText.present ? data.plainText.value : this.plainText,
      richContent:
          data.richContent.present ? data.richContent.value : this.richContent,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      imageWidth:
          data.imageWidth.present ? data.imageWidth.value : this.imageWidth,
      imageHeight:
          data.imageHeight.present ? data.imageHeight.value : this.imageHeight,
      imageSizeBytes: data.imageSizeBytes.present
          ? data.imageSizeBytes.value
          : this.imageSizeBytes,
      contentHash:
          data.contentHash.present ? data.contentHash.value : this.contentHash,
      charCount: data.charCount.present ? data.charCount.value : this.charCount,
      sourceApp: data.sourceApp.present ? data.sourceApp.value : this.sourceApp,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastUsedAt:
          data.lastUsedAt.present ? data.lastUsedAt.value : this.lastUsedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClipboardItem(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('plainText: $plainText, ')
          ..write('richContent: $richContent, ')
          ..write('imagePath: $imagePath, ')
          ..write('imageWidth: $imageWidth, ')
          ..write('imageHeight: $imageHeight, ')
          ..write('imageSizeBytes: $imageSizeBytes, ')
          ..write('contentHash: $contentHash, ')
          ..write('charCount: $charCount, ')
          ..write('sourceApp: $sourceApp, ')
          ..write('isPinned: $isPinned, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastUsedAt: $lastUsedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      type,
      plainText,
      richContent,
      imagePath,
      imageWidth,
      imageHeight,
      imageSizeBytes,
      contentHash,
      charCount,
      sourceApp,
      isPinned,
      createdAt,
      lastUsedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClipboardItem &&
          other.id == this.id &&
          other.type == this.type &&
          other.plainText == this.plainText &&
          other.richContent == this.richContent &&
          other.imagePath == this.imagePath &&
          other.imageWidth == this.imageWidth &&
          other.imageHeight == this.imageHeight &&
          other.imageSizeBytes == this.imageSizeBytes &&
          other.contentHash == this.contentHash &&
          other.charCount == this.charCount &&
          other.sourceApp == this.sourceApp &&
          other.isPinned == this.isPinned &&
          other.createdAt == this.createdAt &&
          other.lastUsedAt == this.lastUsedAt);
}

class ClipboardItemsCompanion extends UpdateCompanion<ClipboardItem> {
  final Value<int> id;
  final Value<ClipboardItemType> type;
  final Value<String?> plainText;
  final Value<String?> richContent;
  final Value<String?> imagePath;
  final Value<int?> imageWidth;
  final Value<int?> imageHeight;
  final Value<int?> imageSizeBytes;
  final Value<String> contentHash;
  final Value<int> charCount;
  final Value<String?> sourceApp;
  final Value<bool> isPinned;
  final Value<DateTime> createdAt;
  final Value<DateTime> lastUsedAt;
  const ClipboardItemsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.plainText = const Value.absent(),
    this.richContent = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.imageWidth = const Value.absent(),
    this.imageHeight = const Value.absent(),
    this.imageSizeBytes = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.charCount = const Value.absent(),
    this.sourceApp = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
  });
  ClipboardItemsCompanion.insert({
    this.id = const Value.absent(),
    required ClipboardItemType type,
    this.plainText = const Value.absent(),
    this.richContent = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.imageWidth = const Value.absent(),
    this.imageHeight = const Value.absent(),
    this.imageSizeBytes = const Value.absent(),
    required String contentHash,
    this.charCount = const Value.absent(),
    this.sourceApp = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
  })  : type = Value(type),
        contentHash = Value(contentHash);
  static Insertable<ClipboardItem> custom({
    Expression<int>? id,
    Expression<int>? type,
    Expression<String>? plainText,
    Expression<String>? richContent,
    Expression<String>? imagePath,
    Expression<int>? imageWidth,
    Expression<int>? imageHeight,
    Expression<int>? imageSizeBytes,
    Expression<String>? contentHash,
    Expression<int>? charCount,
    Expression<String>? sourceApp,
    Expression<bool>? isPinned,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastUsedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (plainText != null) 'plain_text': plainText,
      if (richContent != null) 'rich_content': richContent,
      if (imagePath != null) 'image_path': imagePath,
      if (imageWidth != null) 'image_width': imageWidth,
      if (imageHeight != null) 'image_height': imageHeight,
      if (imageSizeBytes != null) 'image_size_bytes': imageSizeBytes,
      if (contentHash != null) 'content_hash': contentHash,
      if (charCount != null) 'char_count': charCount,
      if (sourceApp != null) 'source_app': sourceApp,
      if (isPinned != null) 'is_pinned': isPinned,
      if (createdAt != null) 'created_at': createdAt,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
    });
  }

  ClipboardItemsCompanion copyWith(
      {Value<int>? id,
      Value<ClipboardItemType>? type,
      Value<String?>? plainText,
      Value<String?>? richContent,
      Value<String?>? imagePath,
      Value<int?>? imageWidth,
      Value<int?>? imageHeight,
      Value<int?>? imageSizeBytes,
      Value<String>? contentHash,
      Value<int>? charCount,
      Value<String?>? sourceApp,
      Value<bool>? isPinned,
      Value<DateTime>? createdAt,
      Value<DateTime>? lastUsedAt}) {
    return ClipboardItemsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      plainText: plainText ?? this.plainText,
      richContent: richContent ?? this.richContent,
      imagePath: imagePath ?? this.imagePath,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
      imageSizeBytes: imageSizeBytes ?? this.imageSizeBytes,
      contentHash: contentHash ?? this.contentHash,
      charCount: charCount ?? this.charCount,
      sourceApp: sourceApp ?? this.sourceApp,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] =
          Variable<int>($ClipboardItemsTable.$convertertype.toSql(type.value));
    }
    if (plainText.present) {
      map['plain_text'] = Variable<String>(plainText.value);
    }
    if (richContent.present) {
      map['rich_content'] = Variable<String>(richContent.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (imageWidth.present) {
      map['image_width'] = Variable<int>(imageWidth.value);
    }
    if (imageHeight.present) {
      map['image_height'] = Variable<int>(imageHeight.value);
    }
    if (imageSizeBytes.present) {
      map['image_size_bytes'] = Variable<int>(imageSizeBytes.value);
    }
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (charCount.present) {
      map['char_count'] = Variable<int>(charCount.value);
    }
    if (sourceApp.present) {
      map['source_app'] = Variable<String>(sourceApp.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClipboardItemsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('plainText: $plainText, ')
          ..write('richContent: $richContent, ')
          ..write('imagePath: $imagePath, ')
          ..write('imageWidth: $imageWidth, ')
          ..write('imageHeight: $imageHeight, ')
          ..write('imageSizeBytes: $imageSizeBytes, ')
          ..write('contentHash: $contentHash, ')
          ..write('charCount: $charCount, ')
          ..write('sourceApp: $sourceApp, ')
          ..write('isPinned: $isPinned, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastUsedAt: $lastUsedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ClipboardItemsTable clipboardItems = $ClipboardItemsTable(this);
  late final Index idxClipboardSort = Index('idx_clipboard_sort',
      'CREATE INDEX idx_clipboard_sort ON clipboard_items (is_pinned, last_used_at)');
  late final Index idxClipboardHash = Index('idx_clipboard_hash',
      'CREATE INDEX idx_clipboard_hash ON clipboard_items (content_hash)');
  late final ClipboardDao clipboardDao = ClipboardDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [clipboardItems, idxClipboardSort, idxClipboardHash];
}

typedef $$ClipboardItemsTableCreateCompanionBuilder = ClipboardItemsCompanion
    Function({
  Value<int> id,
  required ClipboardItemType type,
  Value<String?> plainText,
  Value<String?> richContent,
  Value<String?> imagePath,
  Value<int?> imageWidth,
  Value<int?> imageHeight,
  Value<int?> imageSizeBytes,
  required String contentHash,
  Value<int> charCount,
  Value<String?> sourceApp,
  Value<bool> isPinned,
  Value<DateTime> createdAt,
  Value<DateTime> lastUsedAt,
});
typedef $$ClipboardItemsTableUpdateCompanionBuilder = ClipboardItemsCompanion
    Function({
  Value<int> id,
  Value<ClipboardItemType> type,
  Value<String?> plainText,
  Value<String?> richContent,
  Value<String?> imagePath,
  Value<int?> imageWidth,
  Value<int?> imageHeight,
  Value<int?> imageSizeBytes,
  Value<String> contentHash,
  Value<int> charCount,
  Value<String?> sourceApp,
  Value<bool> isPinned,
  Value<DateTime> createdAt,
  Value<DateTime> lastUsedAt,
});

class $$ClipboardItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ClipboardItemsTable> {
  $$ClipboardItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<ClipboardItemType, ClipboardItemType, int>
      get type => $composableBuilder(
          column: $table.type,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get plainText => $composableBuilder(
      column: $table.plainText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get richContent => $composableBuilder(
      column: $table.richContent, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get imageWidth => $composableBuilder(
      column: $table.imageWidth, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get imageHeight => $composableBuilder(
      column: $table.imageHeight, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get imageSizeBytes => $composableBuilder(
      column: $table.imageSizeBytes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contentHash => $composableBuilder(
      column: $table.contentHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get charCount => $composableBuilder(
      column: $table.charCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceApp => $composableBuilder(
      column: $table.sourceApp, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPinned => $composableBuilder(
      column: $table.isPinned, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastUsedAt => $composableBuilder(
      column: $table.lastUsedAt, builder: (column) => ColumnFilters(column));
}

class $$ClipboardItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ClipboardItemsTable> {
  $$ClipboardItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get plainText => $composableBuilder(
      column: $table.plainText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get richContent => $composableBuilder(
      column: $table.richContent, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get imageWidth => $composableBuilder(
      column: $table.imageWidth, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get imageHeight => $composableBuilder(
      column: $table.imageHeight, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get imageSizeBytes => $composableBuilder(
      column: $table.imageSizeBytes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contentHash => $composableBuilder(
      column: $table.contentHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get charCount => $composableBuilder(
      column: $table.charCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceApp => $composableBuilder(
      column: $table.sourceApp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPinned => $composableBuilder(
      column: $table.isPinned, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastUsedAt => $composableBuilder(
      column: $table.lastUsedAt, builder: (column) => ColumnOrderings(column));
}

class $$ClipboardItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClipboardItemsTable> {
  $$ClipboardItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ClipboardItemType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get plainText =>
      $composableBuilder(column: $table.plainText, builder: (column) => column);

  GeneratedColumn<String> get richContent => $composableBuilder(
      column: $table.richContent, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<int> get imageWidth => $composableBuilder(
      column: $table.imageWidth, builder: (column) => column);

  GeneratedColumn<int> get imageHeight => $composableBuilder(
      column: $table.imageHeight, builder: (column) => column);

  GeneratedColumn<int> get imageSizeBytes => $composableBuilder(
      column: $table.imageSizeBytes, builder: (column) => column);

  GeneratedColumn<String> get contentHash => $composableBuilder(
      column: $table.contentHash, builder: (column) => column);

  GeneratedColumn<int> get charCount =>
      $composableBuilder(column: $table.charCount, builder: (column) => column);

  GeneratedColumn<String> get sourceApp =>
      $composableBuilder(column: $table.sourceApp, builder: (column) => column);

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUsedAt => $composableBuilder(
      column: $table.lastUsedAt, builder: (column) => column);
}

class $$ClipboardItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ClipboardItemsTable,
    ClipboardItem,
    $$ClipboardItemsTableFilterComposer,
    $$ClipboardItemsTableOrderingComposer,
    $$ClipboardItemsTableAnnotationComposer,
    $$ClipboardItemsTableCreateCompanionBuilder,
    $$ClipboardItemsTableUpdateCompanionBuilder,
    (
      ClipboardItem,
      BaseReferences<_$AppDatabase, $ClipboardItemsTable, ClipboardItem>
    ),
    ClipboardItem,
    PrefetchHooks Function()> {
  $$ClipboardItemsTableTableManager(
      _$AppDatabase db, $ClipboardItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClipboardItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClipboardItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClipboardItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<ClipboardItemType> type = const Value.absent(),
            Value<String?> plainText = const Value.absent(),
            Value<String?> richContent = const Value.absent(),
            Value<String?> imagePath = const Value.absent(),
            Value<int?> imageWidth = const Value.absent(),
            Value<int?> imageHeight = const Value.absent(),
            Value<int?> imageSizeBytes = const Value.absent(),
            Value<String> contentHash = const Value.absent(),
            Value<int> charCount = const Value.absent(),
            Value<String?> sourceApp = const Value.absent(),
            Value<bool> isPinned = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> lastUsedAt = const Value.absent(),
          }) =>
              ClipboardItemsCompanion(
            id: id,
            type: type,
            plainText: plainText,
            richContent: richContent,
            imagePath: imagePath,
            imageWidth: imageWidth,
            imageHeight: imageHeight,
            imageSizeBytes: imageSizeBytes,
            contentHash: contentHash,
            charCount: charCount,
            sourceApp: sourceApp,
            isPinned: isPinned,
            createdAt: createdAt,
            lastUsedAt: lastUsedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required ClipboardItemType type,
            Value<String?> plainText = const Value.absent(),
            Value<String?> richContent = const Value.absent(),
            Value<String?> imagePath = const Value.absent(),
            Value<int?> imageWidth = const Value.absent(),
            Value<int?> imageHeight = const Value.absent(),
            Value<int?> imageSizeBytes = const Value.absent(),
            required String contentHash,
            Value<int> charCount = const Value.absent(),
            Value<String?> sourceApp = const Value.absent(),
            Value<bool> isPinned = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> lastUsedAt = const Value.absent(),
          }) =>
              ClipboardItemsCompanion.insert(
            id: id,
            type: type,
            plainText: plainText,
            richContent: richContent,
            imagePath: imagePath,
            imageWidth: imageWidth,
            imageHeight: imageHeight,
            imageSizeBytes: imageSizeBytes,
            contentHash: contentHash,
            charCount: charCount,
            sourceApp: sourceApp,
            isPinned: isPinned,
            createdAt: createdAt,
            lastUsedAt: lastUsedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ClipboardItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ClipboardItemsTable,
    ClipboardItem,
    $$ClipboardItemsTableFilterComposer,
    $$ClipboardItemsTableOrderingComposer,
    $$ClipboardItemsTableAnnotationComposer,
    $$ClipboardItemsTableCreateCompanionBuilder,
    $$ClipboardItemsTableUpdateCompanionBuilder,
    (
      ClipboardItem,
      BaseReferences<_$AppDatabase, $ClipboardItemsTable, ClipboardItem>
    ),
    ClipboardItem,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ClipboardItemsTableTableManager get clipboardItems =>
      $$ClipboardItemsTableTableManager(_db, _db.clipboardItems);
}
