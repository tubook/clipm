import 'package:flutter/material.dart';

import '../../core/theme/omarchy_theme.dart';
import '../../data/database/daos/clipboard_dao.dart';

class SearchHeader extends StatelessWidget {
  const SearchHeader({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.matchedCount,
    required this.totalCount,
    required this.filterMode,
    required this.onFilterChanged,
    required this.isPaused,
    required this.onTogglePause,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int matchedCount;
  final int totalCount;
  final ClipboardFilterMode filterMode;
  final ValueChanged<ClipboardFilterMode> onFilterChanged;
  final bool isPaused;
  final VoidCallback onTogglePause;
  final ValueChanged<String> onChanged;

  static const _filters = [
    (ClipboardFilterMode.all, 'ALL'),
    (ClipboardFilterMode.text, 'TXT'),
    (ClipboardFilterMode.image, 'IMG'),
    (ClipboardFilterMode.pinned, 'PIN'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: OmarchyTheme.surface,
        border: Border(
          bottom: BorderSide(color: OmarchyTheme.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(
            '>',
            style: OmarchyTheme.mono(
              size: 14,
              weight: FontWeight.w700,
              color: OmarchyTheme.accent,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              onChanged: onChanged,
              cursorColor: OmarchyTheme.accent,
              cursorWidth: 7,
              style: OmarchyTheme.mono(size: 13),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'filter history... (tab: type, @app:name)',
                hintStyle: OmarchyTheme.mono(
                  size: 12.5,
                  color: OmarchyTheme.textMuted,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (isPaused) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onTogglePause,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: OmarchyTheme.pinAccent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: OmarchyTheme.pinAccent.withValues(alpha: 0.7),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'PAUSED',
                    style: OmarchyTheme.mono(
                      size: 10,
                      weight: FontWeight.w700,
                      color: OmarchyTheme.pinAccent,
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
          for (final (mode, label) in _filters) ...[
            GestureDetector(
              onTap: () => onFilterChanged(mode),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: filterMode == mode
                        ? OmarchyTheme.selectionBg
                        : OmarchyTheme.bg,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: filterMode == mode
                          ? OmarchyTheme.selectionBg
                          : OmarchyTheme.border,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    label,
                    style: OmarchyTheme.mono(
                      size: 10,
                      weight: filterMode == mode ? FontWeight.w700 : FontWeight.w400,
                      color: filterMode == mode
                          ? OmarchyTheme.selectionFg
                          : OmarchyTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: OmarchyTheme.bg,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: OmarchyTheme.border, width: 1),
            ),
            child: Text(
              '$matchedCount/$totalCount',
              style: OmarchyTheme.mono(
                size: 11,
                color: OmarchyTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
