import 'dart:async';

import 'package:drift/drift.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/hash_utils.dart';
import '../data/database/app_database.dart';
import '../data/database/daos/clipboard_dao.dart';
import '../data/database/tables/clipboard_items.dart';
import '../data/storage/image_storage_service.dart';
import '../platform/native_bridge.dart';
import '../platform/native_clipboard_payload.dart';

/// Listens to OS clipboard events from [NativeBridge], deduplicates by SHA-256,
/// persists images to disk, writes metadata to Drift, and coordinates loop-free
/// write-backs on paste.
class ClipboardMonitorService {
  ClipboardMonitorService({
    required NativeBridge nativeBridge,
    required ClipboardDao clipboardDao,
    required ImageStorageService imageStorage,
    this.maxUnpinnedItems = AppConstants.maxUnpinnedItems,
  })  : _nativeBridge = nativeBridge,
        _dao = clipboardDao,
        _imageStorage = imageStorage;

  final NativeBridge _nativeBridge;
  final ClipboardDao _dao;
  final ImageStorageService _imageStorage;
  final int maxUnpinnedItems;

  StreamSubscription<NativeClipboardPayload>? _subscription;

  /// Secondary Dart-side suppression window in case an OS fires a delayed
  /// clipboard notification right after an internal write-back.
  String? _suppressedHash;
  DateTime? _suppressedUntil;

  Future<void> start() async {
    if (_subscription != null) return;
    _subscription = _nativeBridge.clipboardChanges.listen(
      _handleIncomingPayload,
      onError: (_) {},
    );
    await _nativeBridge.startMonitoring();
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    await _nativeBridge.stopMonitoring();
  }

  Future<void> _handleIncomingPayload(NativeClipboardPayload payload) async {
    if (payload.type == ClipboardItemType.image) {
      await _ingestImage(payload);
    } else {
      await _ingestText(payload);
    }
  }

  Future<void> _ingestText(NativeClipboardPayload payload) async {
    final text = payload.plainText;
    if (text == null || text.isEmpty) return;

    final hashInput = payload.type == ClipboardItemType.richText &&
            payload.richContent != null
        ? 'rich:${payload.richContent}\nplain:$text'
        : 'text:$text';
    final hash = HashUtils.sha256String(hashInput);

    if (_isSuppressed(hash)) return;

    final result = await _dao.insertOrBump(
      ClipboardItemsCompanion.insert(
        type: payload.type,
        plainText: Value(text),
        richContent: Value(payload.richContent),
        contentHash: hash,
        charCount: Value(text.runes.length),
        sourceApp: Value(payload.sourceApp),
      ),
      maxUnpinned: maxUnpinnedItems,
    );

    if (result.orphanedImagePaths.isNotEmpty) {
      await _imageStorage.deleteImages(result.orphanedImagePaths);
    }
  }

  Future<void> _ingestImage(NativeClipboardPayload payload) async {
    final bytes = payload.imageBytes;
    if (bytes == null || bytes.isEmpty) return;

    final hash = HashUtils.sha256Bytes(bytes);
    if (_isSuppressed(hash)) return;

    final relativePath = await _imageStorage.saveImage(bytes, hash);

    final result = await _dao.insertOrBump(
      ClipboardItemsCompanion.insert(
        type: ClipboardItemType.image,
        imagePath: Value(relativePath),
        imageWidth: Value(payload.imageWidth),
        imageHeight: Value(payload.imageHeight),
        imageSizeBytes: Value(bytes.length),
        contentHash: hash,
        sourceApp: Value(payload.sourceApp),
      ),
      maxUnpinned: maxUnpinnedItems,
    );

    if (result.orphanedImagePaths.isNotEmpty) {
      await _imageStorage.deleteImages(result.orphanedImagePaths);
    }
  }

  bool _isSuppressed(String hash) {
    final until = _suppressedUntil;
    if (until == null || DateTime.now().isAfter(until)) {
      _suppressedHash = null;
      _suppressedUntil = null;
      return false;
    }
    if (_suppressedHash == hash) {
      _suppressedHash = null;
      _suppressedUntil = null;
      return true;
    }
    return false;
  }

  /// Writes [item] back to the system clipboard without re-recording it.
  /// If [forcePlainText] is true (Shift+Enter), richText items are written as
  /// plain text only.
  Future<void> writeItemToClipboard(
    ClipboardItem item, {
    bool forcePlainText = false,
  }) async {
    _suppressedHash = item.contentHash;
    _suppressedUntil = DateTime.now().add(const Duration(seconds: 2));

    if (item.type == ClipboardItemType.image) {
      final relPath = item.imagePath;
      if (relPath == null) return;
      final bytes = await _imageStorage.readBytes(relPath);
      if (bytes == null) return;

      await _nativeBridge.writeClipboard(
        type: ClipboardItemType.image,
        imageBytes: bytes,
      );
      return;
    }

    final effectiveType =
        forcePlainText ? ClipboardItemType.text : item.type;
    if (forcePlainText && item.plainText != null) {
      _suppressedHash = HashUtils.sha256String('text:${item.plainText!}');
    }

    await _nativeBridge.writeClipboard(
      type: effectiveType,
      plainText: item.plainText,
      richContent: forcePlainText ? null : item.richContent,
    );
  }

  Future<void> deleteItem(int id) async {
    final orphanPath = await _dao.deleteItemById(id);
    if (orphanPath != null) {
      await _imageStorage.deleteImages([orphanPath]);
    }
  }

  Future<void> togglePin(int id) async {
    await _dao.togglePin(id);
  }

  Future<void> clearUnpinnedHistory() async {
    final orphanPaths = await _dao.clearUnpinned();
    if (orphanPaths.isNotEmpty) {
      await _imageStorage.deleteImages(orphanPaths);
    }
  }
}
