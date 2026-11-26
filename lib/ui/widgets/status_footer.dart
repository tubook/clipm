import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/omarchy_theme.dart';
import '../../core/utils/time_utils.dart';
import '../../data/database/app_database.dart';
import '../../data/database/tables/clipboard_items.dart';

class StatusFooter extends StatelessWidget {
  const StatusFooter({
    super.key,
    required this.item,
  });

  final ClipboardItem? item;

  String _metaLine(ClipboardItem current) {
    final parts = <String>[];
    switch (current.type) {
      case ClipboardItemType.image:
        parts.add('IMG');
        if (current.imageWidth != null && current.imageHeight != null) {
          parts.add('${current.imageWidth}x${current.imageHeight}');
        }
        if (current.imageSizeBytes != null) {
          parts.add(TimeUtils.formatByteSize(current.imageSizeBytes!));
        }
      case ClipboardItemType.richText:
        parts.add('RICH');
        parts.add('${current.charCount} chars');
      case ClipboardItemType.text:
        parts.add('TEXT');
        parts.add('${current.charCount} chars');
    }

    if (current.isPinned) {
      parts.add('PIN');
    }
    if (current.sourceApp != null && current.sourceApp!.isNotEmpty) {
      parts.add(current.sourceApp!);
    }
    parts.add(TimeUtils.formatTimestamp(current.createdAt));
    return parts.join(' | ');
  }

  @override
  Widget build(BuildContext context) {
    final pinKey = Platform.isMacOS ? '⌘P' : '⌃⇧P';

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: OmarchyTheme.surface,
        border: Border(
          top: BorderSide(color: OmarchyTheme.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item != null ? _metaLine(item!) : 'ready',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OmarchyTheme.mono(
                size: 10.5,
                color: OmarchyTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '↵ paste  ⇧↵ plain  $pinKey pin  ⌃D del  esc close',
            style: OmarchyTheme.mono(
              size: 10.5,
              color: OmarchyTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
