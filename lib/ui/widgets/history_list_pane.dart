import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../core/theme/omarchy_theme.dart';
import '../../core/utils/time_utils.dart';
import '../../data/database/app_database.dart';
import '../../data/database/tables/clipboard_items.dart';
import '../../services/clipboard_monitor_service.dart';

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

  static const double rowHeight = 34.0;

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
          'No matching items',
          style: OmarchyTheme.ui(
            size: 12.5,
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
            quickSlot: index < 9 ? index + 1 : null,
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
    required this.quickSlot,
    required this.isSelected,
    required this.onTap,
    required this.onDoubleTap,
  });

  final ClipboardItem item;
  final int? quickSlot;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;

  String _summaryText() {
    if (item.type == ClipboardItemType.image) {
      final w = item.imageWidth ?? 0;
      final h = item.imageHeight ?? 0;
      return '[IMG ${w}x$h]';
    }
    if (item.type == ClipboardItemType.file) {
      final paths = ClipboardMonitorService.extractFilePaths(item);
      if (paths.isEmpty) return '[FILE]';
      final first = p.basename(paths.first);
      return paths.length == 1
          ? first
          : '$first (+${paths.length - 1})';
    }
    final raw = item.plainText ?? '';
    return raw.replaceAll(RegExp(r'[\r\n\t]+'), ' ').trim();
  }

  String _glyph() {
    if (item.isPinned) return '*';
    return switch (item.type) {
      ClipboardItemType.image => '#',
      ClipboardItemType.file => '@',
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
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 14,
                child: Center(
                  child: Text(
                    _glyph(),
                    style: OmarchyTheme.mono(
                      size: 12,
                      weight: FontWeight.w600,
                      color: glyphColor,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _summaryText(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OmarchyTheme.ui(
                    size: 13,
                    weight: isSelected ? FontWeight.w500 : FontWeight.w400,
                    color: fgColor,
                    height: 1.2,
                  ),
                ),
              ),
              if (quickSlot != null) ...[
                const SizedBox(width: 6),
                Text(
                  '$quickSlot',
                  style: OmarchyTheme.ui(
                    size: 10.5,
                    weight: FontWeight.w600,
                    color: isSelected
                        ? OmarchyTheme.selectionFg.withValues(alpha: 0.65)
                        : OmarchyTheme.textMuted.withValues(alpha: 0.8),
                    height: 1.0,
                    tabularFigures: true,
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Text(
                TimeUtils.formatRelative(item.lastUsedAt),
                style: OmarchyTheme.ui(
                  size: 11,
                  color: metaColor,
                  height: 1.0,
                  tabularFigures: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
