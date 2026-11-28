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

  static const _footerStrut = StrutStyle(
    fontSize: 11,
    height: 1.2,
    forceStrutHeight: true,
    leadingDistribution: TextLeadingDistribution.even,
  );

  static const _footerHeightBehavior = TextHeightBehavior(
    applyHeightToFirstAscent: false,
    applyHeightToLastDescent: false,
    leadingDistribution: TextLeadingDistribution.even,
  );

  List<InlineSpan> _buildHintSpans(String mod, String pinKey) {
    final keyStyle = OmarchyTheme.ui(
      size: 11,
      weight: FontWeight.w500,
      color: OmarchyTheme.textSecondary,
      height: 1.2,
      tabularFigures: true,
    );
    final labelStyle = OmarchyTheme.ui(
      size: 11,
      color: OmarchyTheme.textMuted,
      height: 1.2,
    );
    final dotStyle = OmarchyTheme.ui(
      size: 11,
      color: OmarchyTheme.textMuted.withValues(alpha: 0.7),
      height: 1.2,
    );

    final pairs = <(String, String)>[
      ('↵', 'paste'),
      ('${mod}1-9', 'quick'),
      ('Tab', 'filter'),
      (pinKey, 'pin'),
      ('$mod,', 'prefs'),
      ('Esc', ''),
    ];

    final spans = <InlineSpan>[];
    for (var i = 0; i < pairs.length; i++) {
      if (i > 0) {
        spans.add(TextSpan(text: ' · ', style: dotStyle));
      }
      final (key, label) = pairs[i];
      spans.add(TextSpan(text: key, style: keyStyle));
      if (label.isNotEmpty) {
        spans.add(TextSpan(text: ' $label', style: labelStyle));
      }
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final mod = Platform.isMacOS ? '⌘' : '⌃';
    final pinKey = Platform.isMacOS ? '⌘P' : '⌃⇧P';

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: OmarchyTheme.surface,
        border: Border(
          top: BorderSide(color: OmarchyTheme.border, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              item != null ? _metaLine(item!) : 'Ready',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              strutStyle: _footerStrut,
              textHeightBehavior: _footerHeightBehavior,
              style: OmarchyTheme.ui(
                size: 11,
                color: OmarchyTheme.textSecondary,
                height: 1.2,
                tabularFigures: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text.rich(
            TextSpan(children: _buildHintSpans(mod, pinKey)),
            maxLines: 1,
            style: OmarchyTheme.ui(
              size: 11,
              color: OmarchyTheme.textMuted,
              height: 1.2,
            ),
            strutStyle: _footerStrut,
            textHeightBehavior: _footerHeightBehavior,
          ),
        ],
      ),
    );
  }
}
