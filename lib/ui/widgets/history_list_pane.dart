import 'package:flutter/material.dart';

import '../../core/theme/omarchy_theme.dart';
import '../../core/utils/time_utils.dart';
import '../../data/database/app_database.dart';
import '../../data/database/tables/clipboard_items.dart';

class HistoryListPane extends StatefulWidget {
  const HistoryListPane({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    required this.onActivate,
  });

  final List<ClipboardItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final ValueChanged<ClipboardItem> onActivate;

  static const double rowHeight = 32.0;

  @override
  State<HistoryListPane> createState() => _HistoryListPaneState();
}

class _HistoryListPaneState extends State<HistoryListPane> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant HistoryListPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex ||
        widget.items.length != oldWidget.items.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureVisible());
    }
  }

  void _ensureVisible() {
    if (!_scrollController.hasClients || widget.items.isEmpty) return;

    final itemTop = widget.selectedIndex * HistoryListPane.rowHeight;
    final itemBottom = itemTop + HistoryListPane.rowHeight;
    final viewportHeight = _scrollController.position.viewportDimension;
    final currentOffset = _scrollController.offset;

    if (itemTop < currentOffset) {
      _scrollController.jumpTo(itemTop);
    } else if (itemBottom > currentOffset + viewportHeight) {
      _scrollController.jumpTo(
        (itemBottom - viewportHeight)
            .clamp(0.0, _scrollController.position.maxScrollExtent),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return Center(
        child: Text(
          'no matching items',
          style: OmarchyTheme.mono(
            size: 12,
            color: OmarchyTheme.textMuted,
          ),
        ),
      );
    }

    return Scrollbar(
      controller: _scrollController,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemExtent: HistoryListPane.rowHeight,
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          final item = widget.items[index];
          final isSelected = index == widget.selectedIndex;
          return _HistoryRow(
            item: item,
            isSelected: isSelected,
            onTap: () => widget.onSelect(index),
            onDoubleTap: () => widget.onActivate(item),
          );
        },
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.onDoubleTap,
  });

  final ClipboardItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;

  String _summaryText() {
    if (item.type == ClipboardItemType.image) {
      final w = item.imageWidth ?? 0;
      final h = item.imageHeight ?? 0;
      return '[IMG ${w}x$h]';
    }
    final raw = item.plainText ?? '';
    return raw.replaceAll(RegExp(r'[\r\n\t]+'), ' ').trim();
  }

  String _glyph() {
    if (item.isPinned) return '*';
    return switch (item.type) {
      ClipboardItemType.image => '#',
      ClipboardItemType.richText => '+',
      ClipboardItemType.text => '-',
    };
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected ? OmarchyTheme.selectionBg : Colors.transparent;
    final fgColor =
        isSelected ? OmarchyTheme.selectionFg : OmarchyTheme.textPrimary;
    final metaColor = isSelected
        ? OmarchyTheme.selectionFg.withValues(alpha: 0.72)
        : OmarchyTheme.textMuted;
    final glyphColor = isSelected
        ? OmarchyTheme.selectionFg
        : (item.isPinned ? OmarchyTheme.pinAccent : OmarchyTheme.textSecondary);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              SizedBox(
                width: 14,
                child: Text(
                  _glyph(),
                  style: OmarchyTheme.mono(
                    size: 12,
                    weight: FontWeight.w700,
                    color: glyphColor,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _summaryText(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OmarchyTheme.mono(
                    size: 12,
                    weight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: fgColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                TimeUtils.formatRelative(item.lastUsedAt),
                style: OmarchyTheme.mono(
                  size: 11,
                  color: metaColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
