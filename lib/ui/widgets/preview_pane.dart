import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/omarchy_theme.dart';
import '../../data/database/app_database.dart';
import '../../data/database/tables/clipboard_items.dart';
import '../../providers/database_providers.dart';

class PreviewPane extends ConsumerWidget {
  const PreviewPane({
    super.key,
    required this.item,
  });

  final ClipboardItem? item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = item;
    if (current == null) {
      return Center(
        child: Text(
          'empty selection',
          style: OmarchyTheme.mono(
            size: 12,
            color: OmarchyTheme.textMuted,
          ),
        ),
      );
    }

    if (current.type == ClipboardItemType.image) {
      return _ImagePreview(relativePath: current.imagePath);
    }

    return _TextPreview(text: current.plainText ?? '');
  }
}

class _TextPreview extends StatelessWidget {
  const _TextPreview({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: OmarchyTheme.bg,
      padding: const EdgeInsets.all(14),
      child: Scrollbar(
        child: SingleChildScrollView(
          child: SelectableText(
            text,
            style: OmarchyTheme.mono(
              size: 12.5,
              height: 1.48,
              color: OmarchyTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ImagePreview extends ConsumerWidget {
  const _ImagePreview({required this.relativePath});

  final String? relativePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = relativePath;
    if (path == null) {
      return Center(
        child: Text(
          '[missing image path]',
          style: OmarchyTheme.mono(size: 12, color: OmarchyTheme.danger),
        ),
      );
    }

    final storage = ref.watch(imageStorageServiceProvider);

    return FutureBuilder<File>(
      future: storage.resolveFile(path),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final file = snapshot.data!;
        return Container(
          color: OmarchyTheme.bg,
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
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
                  style: OmarchyTheme.mono(size: 12, color: OmarchyTheme.danger),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
