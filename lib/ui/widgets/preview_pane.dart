import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/theme/omarchy_theme.dart';
import '../../core/utils/content_detector.dart';
import '../../core/utils/time_utils.dart';
import '../../data/database/app_database.dart';
import '../../data/database/tables/clipboard_items.dart';
import '../../providers/database_providers.dart';
import '../../services/clipboard_monitor_service.dart';

class PreviewPane extends ConsumerWidget {
  const PreviewPane({
    super.key,
    required this.item,
    this.onOpenUrl,
    this.onSaveImage,
  });

  final ClipboardItem? item;
  final ValueChanged<String>? onOpenUrl;
  final ValueChanged<ClipboardItem>? onSaveImage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = item;
    if (current == null) {
      return Center(
        child: Text(
          'Empty selection',
          style: OmarchyTheme.ui(
            size: 12.5,
            color: OmarchyTheme.textMuted,
          ),
        ),
      );
    }

    if (current.type == ClipboardItemType.image) {
      return _ImagePreview(
        item: current,
        onSaveImage: onSaveImage,
      );
    }

    if (current.type == ClipboardItemType.file) {
      return _FilePreview(item: current);
    }

    return _SmartTextPreview(
      text: current.plainText ?? '',
      onOpenUrl: onOpenUrl,
    );
  }
}

class _SmartTextPreview extends StatefulWidget {
  const _SmartTextPreview({
    required this.text,
    this.onOpenUrl,
  });

  final String text;
  final ValueChanged<String>? onOpenUrl;

  @override
  State<_SmartTextPreview> createState() => _SmartTextPreviewState();
}

class _SmartTextPreviewState extends State<_SmartTextPreview> {
  bool _showPrettyJson = true;

  @override
  void didUpdateWidget(covariant _SmartTextPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _showPrettyJson = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final detected = ContentDetector.detect(widget.text);
    final mod = Platform.isMacOS ? '⌘' : '⌃';

    final displayText =
        (detected.kind == DetectedContentKind.json && _showPrettyJson)
            ? (detected.prettyJson ?? widget.text)
            : widget.text;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: OmarchyTheme.bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (detected.kind == DetectedContentKind.color &&
              detected.color != null)
            _ColorBanner(
              color: detected.color!,
              hex: detected.normalizedColorHex ?? widget.text.trim(),
            ),
          if (detected.kind == DetectedContentKind.url && detected.uri != null)
            _SmartBanner(
              badge: 'URL',
              detail: detected.uri!.host,
              actionLabel: '${mod}O open',
              onAction: widget.onOpenUrl != null
                  ? () => widget.onOpenUrl!(detected.uri.toString())
                  : null,
            ),
          if (detected.kind == DetectedContentKind.json)
            _SmartBanner(
              badge: 'JSON',
              detail: _showPrettyJson ? 'formatted' : 'raw',
              actionLabel: _showPrettyJson ? 'show raw' : 'format',
              onAction: () =>
                  setState(() => _showPrettyJson = !_showPrettyJson),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Scrollbar(
                child: SingleChildScrollView(
                  child: SelectableText(
                    displayText,
                    style: detected.kind == DetectedContentKind.json
                        ? OmarchyTheme.mono(
                            size: 12.5,
                            height: 1.48,
                            color: OmarchyTheme.textPrimary,
                          )
                        : OmarchyTheme.ui(
                            size: 13,
                            height: 1.55,
                            color: detected.kind == DetectedContentKind.url
                                ? OmarchyTheme.accent
                                : OmarchyTheme.textPrimary,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorBanner extends StatelessWidget {
  const _ColorBanner({
    required this.color,
    required this.hex,
  });

  final Color color;
  final String hex;

  @override
  Widget build(BuildContext context) {
    final r = (color.r * 255).round();
    final g = (color.g * 255).round();
    final b = (color.b * 255).round();
    final a = color.a;
    final rgbText = a < 0.999
        ? 'rgba($r, $g, $b, ${a.toStringAsFixed(2)})'
        : 'rgb($r, $g, $b)';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: OmarchyTheme.surface,
        border: Border(
          bottom: BorderSide(color: OmarchyTheme.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 22,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: OmarchyTheme.borderActive, width: 1),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            hex,
            style: OmarchyTheme.mono(
              size: 12,
              weight: FontWeight.w700,
              color: OmarchyTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            rgbText,
            style: OmarchyTheme.mono(
              size: 11.5,
              color: OmarchyTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmartBanner extends StatelessWidget {
  const _SmartBanner({
    required this.badge,
    required this.detail,
    this.actionLabel,
    this.onAction,
  });

  final String badge;
  final String detail;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: const BoxDecoration(
        color: OmarchyTheme.surface,
        border: Border(
          bottom: BorderSide(color: OmarchyTheme.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: OmarchyTheme.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: OmarchyTheme.accent.withValues(alpha: 0.6),
              ),
            ),
            child: Text(
              badge,
              style: OmarchyTheme.mono(
                size: 10,
                weight: FontWeight.w700,
                color: OmarchyTheme.accent,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OmarchyTheme.mono(
                size: 11,
                color: OmarchyTheme.textSecondary,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: OmarchyTheme.bg,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: OmarchyTheme.border),
                  ),
                  child: Text(
                    actionLabel!,
                    style: OmarchyTheme.mono(
                      size: 10.5,
                      color: OmarchyTheme.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilePreview extends StatelessWidget {
  const _FilePreview({required this.item});

  final ClipboardItem item;

  @override
  Widget build(BuildContext context) {
    final paths = ClipboardMonitorService.extractFilePaths(item);

    return Container(
      color: OmarchyTheme.bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SmartBanner(
            badge: 'FILE',
            detail:
                '${paths.length} ${paths.length == 1 ? 'item' : 'items'} · ↵ paste files · ⇧↵ paste paths',
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: paths.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final filePath = paths[index];
                final name = p.basename(filePath);
                final dir = p.dirname(filePath);
                final entityType = FileSystemEntity.typeSync(filePath);
                final status = switch (entityType) {
                  FileSystemEntityType.directory => ('DIR', OmarchyTheme.accent),
                  FileSystemEntityType.file => ('FILE', OmarchyTheme.textSecondary),
                  FileSystemEntityType.link => ('LINK', OmarchyTheme.pinAccent),
                  _ => ('MISSING', OmarchyTheme.danger),
                };

                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: OmarchyTheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: OmarchyTheme.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: OmarchyTheme.bg,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: OmarchyTheme.border),
                        ),
                        child: Text(
                          status.$1,
                          style: OmarchyTheme.mono(
                            size: 9.5,
                            weight: FontWeight.w700,
                            color: status.$2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: OmarchyTheme.mono(
                                size: 12,
                                weight: FontWeight.w600,
                                color: OmarchyTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dir,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: OmarchyTheme.mono(
                                size: 10.5,
                                color: OmarchyTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePreview extends ConsumerWidget {
  const _ImagePreview({
    required this.item,
    this.onSaveImage,
  });

  final ClipboardItem item;
  final ValueChanged<ClipboardItem>? onSaveImage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = item.imagePath;
    if (path == null) {
      return Center(
        child: Text(
          '[missing image path]',
          style: OmarchyTheme.ui(size: 12.5, color: OmarchyTheme.danger),
        ),
      );
    }

    final storage = ref.watch(imageStorageServiceProvider);
    final mod = Platform.isMacOS ? '⌘' : '⌃';
    final dims = (item.imageWidth != null && item.imageHeight != null)
        ? '${item.imageWidth}×${item.imageHeight}'
        : 'PNG';
    final size = item.imageSizeBytes != null
        ? ' · ${TimeUtils.formatByteSize(item.imageSizeBytes!)}'
        : '';

    return Container(
      color: OmarchyTheme.bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SmartBanner(
            badge: 'IMG',
            detail: '$dims$size',
            actionLabel: '${mod}S save',
            onAction: onSaveImage != null ? () => onSaveImage!(item) : null,
          ),
          Expanded(
            child: FutureBuilder<File>(
              future: storage.resolveFile(path),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }
                final file = snapshot.data!;
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: OmarchyTheme.border, width: 1),
                      ),
                      child: Image.file(
                        file,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (_, __, ___) => Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            '[failed to load image]',
                            style: OmarchyTheme.ui(
                              size: 12.5,
                              color: OmarchyTheme.danger,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
