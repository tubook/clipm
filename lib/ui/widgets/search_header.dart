import 'package:flutter/material.dart';

import '../../core/theme/omarchy_theme.dart';

class SearchHeader extends StatelessWidget {
  const SearchHeader({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.matchedCount,
    required this.totalCount,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int matchedCount;
  final int totalCount;
  final ValueChanged<String> onChanged;

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
                hintText: 'filter clipboard history...',
                hintStyle: OmarchyTheme.mono(
                  size: 13,
                  color: OmarchyTheme.textMuted,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 8),
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
