import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:clipm/data/database/app_database.dart';
import 'package:clipm/data/database/daos/clipboard_dao.dart';
import 'package:clipm/data/database/tables/clipboard_items.dart';
import 'package:clipm/data/settings/app_settings.dart';
import 'package:clipm/data/storage/image_storage_service.dart';
import 'package:clipm/platform/native_bridge.dart';
import 'package:clipm/platform/native_clipboard_payload.dart';
import 'package:clipm/services/clipboard_monitor_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeNativeBridge extends NativeBridge {
  final _controller = StreamController<NativeClipboardPayload>.broadcast();
  ClipboardItemType? lastWrittenType;
  String? lastWrittenText;
  List<String>? lastWrittenFilePaths;

  @override
  Stream<NativeClipboardPayload> get clipboardChanges => _controller.stream;

  @override
  Future<void> startMonitoring() async {}

  @override
  Future<void> stopMonitoring() async {}

  @override
  Future<void> writeClipboard({
    required ClipboardItemType type,
    String? plainText,
    String? richContent,
    Uint8List? imageBytes,
    List<String>? filePaths,
  }) async {
    lastWrittenType = type;
    lastWrittenText = plainText;
    lastWrittenFilePaths = filePaths;
  }

  void emit(NativeClipboardPayload payload) => _controller.add(payload);

  Future<void> dispose() => _controller.close();
}

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late _FakeNativeBridge bridge;
  late ImageStorageService imageStorage;
  late ClipboardMonitorService monitor;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('clipm_monitor_test_');
    bridge = _FakeNativeBridge();
    imageStorage = ImageStorageService(baseDirectoryProvider: () async => tempDir);
    monitor = ClipboardMonitorService(
      nativeBridge: bridge,
      clipboardDao: db.clipboardDao,
      imageStorage: imageStorage,
    );
    await monitor.start();
  });

  tearDown(() async {
    await monitor.stop();
    await bridge.dispose();
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('drops incoming items while paused and resumes recording afterward', () async {
    monitor.setPaused(true);
    bridge.emit(
      const NativeClipboardPayload(
        type: ClipboardItemType.text,
        plainText: 'secret while paused',
        sourceApp: 'Notes',
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(await db.clipboardDao.watchItems().first, isEmpty);

    monitor.setPaused(false);
    bridge.emit(
      const NativeClipboardPayload(
        type: ClipboardItemType.text,
        plainText: 'recorded after resume',
        sourceApp: 'Notes',
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));
    final items = await db.clipboardDao.watchItems().first;
    expect(items.length, 1);
    expect(items.first.plainText, 'recorded after resume');
  });

  test('skips entries from ignoredApps and trims overflow on lower maxUnpinnedItems', () async {
    await monitor.applySettings(
      AppSettings.defaults().copyWith(
        maxUnpinnedItems: 500,
        ignoredApps: const ['1Password'],
      ),
    );

    bridge.emit(
      const NativeClipboardPayload(
        type: ClipboardItemType.text,
        plainText: 'vault password',
        sourceApp: '1Password',
      ),
    );
    bridge.emit(
      const NativeClipboardPayload(
        type: ClipboardItemType.text,
        plainText: 'entry 1',
        sourceApp: 'Terminal',
      ),
    );
    bridge.emit(
      const NativeClipboardPayload(
        type: ClipboardItemType.text,
        plainText: 'entry 2',
        sourceApp: 'Terminal',
      ),
    );
    bridge.emit(
      const NativeClipboardPayload(
        type: ClipboardItemType.text,
        plainText: 'entry 3',
        sourceApp: 'Terminal',
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 50));
    var items = await db.clipboardDao.watchItems().first;
    expect(items.length, 3);
    expect(items.any((e) => e.plainText == 'vault password'), isFalse);

    await monitor.applySettings(
      monitor.settings.copyWith(maxUnpinnedItems: 2),
    );
    items = await db.clipboardDao.watchItems().first;
    expect(items.length, 2);
  });

  test('ingests file payloads and supports native file vs plain path write-back', () async {
    bridge.emit(
      const NativeClipboardPayload(
        type: ClipboardItemType.file,
        filePaths: ['/tmp/report.pdf', '/tmp/notes.md'],
        sourceApp: 'Finder',
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 40));

    final fileItems = await db.clipboardDao
        .watchItems(filter: ClipboardFilterMode.file)
        .first;
    expect(fileItems.length, 1);
    final item = fileItems.first;
    expect(
      ClipboardMonitorService.extractFilePaths(item),
      ['/tmp/report.pdf', '/tmp/notes.md'],
    );

    // Searchable via FTS5 by filename
    final searched = await db.clipboardDao.watchItems(query: 'report.pdf').first;
    expect(searched.length, 1);

    // Native file write-back
    await monitor.writeItemToClipboard(item, forcePlainText: false);
    expect(bridge.lastWrittenType, ClipboardItemType.file);
    expect(bridge.lastWrittenFilePaths, ['/tmp/report.pdf', '/tmp/notes.md']);

    // Plain-text path write-back (Shift+Enter)
    await monitor.writeItemToClipboard(item, forcePlainText: true);
    expect(bridge.lastWrittenType, ClipboardItemType.text);
    expect(bridge.lastWrittenText, '/tmp/report.pdf\n/tmp/notes.md');
  });

  test('exports cached image to Downloads with collision-safe filenames', () async {
    final downloadsDir =
        await Directory.systemTemp.createTemp('clipm_downloads_test_');
    addTearDown(() async {
      if (await downloadsDir.exists()) {
        await downloadsDir.delete(recursive: true);
      }
    });

    final relPath = await imageStorage.saveImage(
      Uint8List.fromList([137, 80, 78, 71]),
      'abcdef1234567890',
    );
    final first = await imageStorage.saveImageToDownloads(
      relPath,
      'abcdef1234567890',
      downloadsDirProvider: () async => downloadsDir,
    );
    final second = await imageStorage.saveImageToDownloads(
      relPath,
      'abcdef1234567890',
      downloadsDirProvider: () async => downloadsDir,
    );

    expect(first, endsWith('clipm_abcdef12.png'));
    expect(second, endsWith('clipm_abcdef12_1.png'));
    expect(File(first!).existsSync(), isTrue);
    expect(File(second!).existsSync(), isTrue);
  });
}
