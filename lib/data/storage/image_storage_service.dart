import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_constants.dart';

/// Persists clipboard images under `<applicationSupportDirectory>/images/`
/// using content-addressed filenames (`<sha256>.png`) and resolves relative paths.
class ImageStorageService {
  ImageStorageService({Future<Directory> Function()? baseDirectoryProvider})
      : _baseDirectoryProvider =
            baseDirectoryProvider ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _baseDirectoryProvider;
  Directory? _supportDir;

  Future<Directory> _getSupportDir() async {
    return _supportDir ??= await _baseDirectoryProvider();
  }

  /// Saves [pngBytes] as `images/<contentHash>.png` if not already present,
  /// returning the relative path stored in SQLite.
  Future<String> saveImage(Uint8List pngBytes, String contentHash) async {
    final supportDir = await _getSupportDir();
    final imagesDir = Directory(p.join(supportDir.path, AppConstants.imagesSubdir));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final relativePath = p.posix.join(AppConstants.imagesSubdir, '$contentHash.png');
    final file = File(p.join(supportDir.path, AppConstants.imagesSubdir, '$contentHash.png'));
    if (!await file.exists()) {
      await file.writeAsBytes(pngBytes, flush: true);
    }
    return relativePath;
  }

  /// Resolves a stored relative path into an absolute [File].
  Future<File> resolveFile(String relativePath) async {
    final supportDir = await _getSupportDir();
    final normalized = p.joinAll(relativePath.split('/'));
    return File(p.join(supportDir.path, normalized));
  }

  /// Reads raw PNG bytes for write-back to the system clipboard.
  Future<Uint8List?> readBytes(String relativePath) async {
    final file = await resolveFile(relativePath);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  /// Best-effort deletion of orphaned image files on disk.
  Future<void> deleteImages(Iterable<String> relativePaths) async {
    for (final rel in relativePaths) {
      try {
        final file = await resolveFile(rel);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Ignore transient file lock errors during background cleanup.
      }
    }
  }

  /// Copies a cached image into the user's Downloads directory and returns the
  /// destination file path, or null if the source or target directory is unavailable.
  Future<String?> saveImageToDownloads(
    String relativePath,
    String contentHash, {
    Future<Directory?> Function()? downloadsDirProvider,
  }) async {
    final source = await resolveFile(relativePath);
    if (!await source.exists()) return null;

    final downloadsDir = await (downloadsDirProvider ?? getDownloadsDirectory)();
    if (downloadsDir == null) return null;
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }

    final shortHash =
        contentHash.length >= 8 ? contentHash.substring(0, 8) : contentHash;
    var candidate = File(p.join(downloadsDir.path, 'clipm_$shortHash.png'));
    var suffix = 1;
    while (await candidate.exists()) {
      candidate =
          File(p.join(downloadsDir.path, 'clipm_${shortHash}_$suffix.png'));
      suffix++;
    }

    await source.copy(candidate.path);
    return candidate.path;
  }
}
