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
    (ClipboardFilterMode.file, 'FILE'),
    (ClipboardFilterMode.pinned, 'PIN'),
  ];

  static const _badgeStrut = StrutStyle(
    fontSize: 10.5,
    height: 1.0,
    forceStrutHeight: true,
    leadingDistribution: TextLeadingDistribution.even,
  );

  static const _badgeHeightBehavior = TextHeightBehavior(
    applyHeightToFirstAscent: false,
    applyHeightToLastDescent: false,
    leadingDistribution: TextLeadingDistribution.even,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: OmarchyTheme.surface,
        border: Border(
          bottom: BorderSide(color: OmarchyTheme.border, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '>',
            style: OmarchyTheme.mono(
              size: 14,
              weight: FontWeight.w700,
              color: OmarchyTheme.accent,
              height: 1.0,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              onChanged: onChanged,
              textAlignVertical: TextAlignVertical.center,
              cursorColor: OmarchyTheme.accent,
              cursorWidth: 1.8,
              cursorHeight: 16,
              cursorRadius: const Radius.circular(1),
              style: OmarchyTheme.ui(size: 13.5, height: 1.2),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Filter history… (Tab: type, @app:name)',
                hintStyle: OmarchyTheme.ui(
                  size: 13.5,
                  color: OmarchyTheme.textMuted,
                  height: 1.2,
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
                  height: 22,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 7),
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
                    strutStyle: _badgeStrut,
                    textHeightBehavior: _badgeHeightBehavior,
                    style: OmarchyTheme.ui(
                      size: 10.5,
                      weight: FontWeight.w600,
                      color: OmarchyTheme.pinAccent,
                      height: 1.0,
                      letterSpacing: 0.2,
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
                  height: 22,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  decoration: BoxDecoration(
                    color: filterMode == mode
                        ? OmarchyTheme.selectionBg
                        : OmarchyTheme.bg,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: filterMode == mode
                          ? OmarchyTheme.selectionBg
                          : OmarchyTheme.border,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    label,
                    strutStyle: _badgeStrut,
                    textHeightBehavior: _badgeHeightBehavior,
                    style: OmarchyTheme.ui(
                      size: 10.5,
                      weight: filterMode == mode
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: filterMode == mode
                          ? OmarchyTheme.selectionFg
                          : OmarchyTheme.textSecondary,
                      height: 1.0,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          const SizedBox(width: 4),
          Container(
            height: 22,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: OmarchyTheme.bg,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: OmarchyTheme.border, width: 1),
            ),
            child: Text(
              '$matchedCount/$totalCount',
              strutStyle: _badgeStrut,
              textHeightBehavior: _badgeHeightBehavior,
              style: OmarchyTheme.ui(
                size: 10.5,
                weight: FontWeight.w500,
                color: OmarchyTheme.textSecondary,
                height: 1.0,
                tabularFigures: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
