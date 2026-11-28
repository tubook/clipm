import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/omarchy_theme.dart';
import '../../core/utils/content_detector.dart';
import '../../core/utils/text_transforms.dart';
import '../../data/database/app_database.dart';
import '../../data/database/tables/clipboard_items.dart';

enum QuickActionKind {
  pasteDefault,
  pastePlainText,
  copyOnly,
  copyPlainTextOnly,
  openUrl,
  saveImageToDownloads,
  transformAndPaste,
  togglePin,
  deleteItem,
}

class QuickAction {
  const QuickAction({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.kind,
    this.shortcutHint,
    this.transformedText,
    this.isDanger = false,
  });

  final String id;
  final String label;
  final String subtitle;
  final QuickActionKind kind;
  final String? shortcutHint;
  final String? transformedText;
  final bool isDanger;
}

/// Builds the context-aware list of actions available for [item].
List<QuickAction> buildQuickActionsForItem(ClipboardItem item) {
  final mod = Platform.isMacOS ? '⌘' : '⌃';
  final actions = <QuickAction>[
    const QuickAction(
      id: 'paste_default',
      label: 'Paste',
      subtitle: 'write to clipboard and paste into previous app',
      kind: QuickActionKind.pasteDefault,
      shortcutHint: '↵',
    ),
    const QuickAction(
      id: 'copy_only',
      label: 'Copy Only',
      subtitle: 'write to clipboard without auto-pasting',
      kind: QuickActionKind.copyOnly,
    ),
  ];

  if (item.type == ClipboardItemType.image) {
    actions.add(
      QuickAction(
        id: 'save_image',
        label: 'Save Image to Downloads',
        subtitle: 'export PNG copy to your Downloads folder',
        kind: QuickActionKind.saveImageToDownloads,
        shortcutHint: '${mod}S',
      ),
    );
  } else if (item.type == ClipboardItemType.file) {
    actions.addAll([
      const QuickAction(
        id: 'paste_paths',
        label: 'Paste File Paths (Plain Text)',
        subtitle: 'paste newline-separated paths instead of files',
        kind: QuickActionKind.pastePlainText,
        shortcutHint: '⇧↵',
      ),
      const QuickAction(
        id: 'copy_paths',
        label: 'Copy File Paths Only',
        subtitle: 'copy newline-separated paths without pasting',
        kind: QuickActionKind.copyPlainTextOnly,
      ),
    ]);
  } else {
    final text = item.plainText ?? '';
    final detected = ContentDetector.detect(text);

    if (item.type == ClipboardItemType.richText) {
      actions.add(
        const QuickAction(
          id: 'paste_plain',
          label: 'Paste as Plain Text',
          subtitle: 'strip HTML formatting before pasting',
          kind: QuickActionKind.pastePlainText,
          shortcutHint: '⇧↵',
        ),
      );
    }

    if (detected.kind == DetectedContentKind.url && detected.uri != null) {
      actions.add(
        QuickAction(
          id: 'open_url',
          label: 'Open URL in Browser',
          subtitle: detected.uri.toString(),
          kind: QuickActionKind.openUrl,
          shortcutHint: '${mod}O',
        ),
      );
    }

    if (detected.kind == DetectedContentKind.json) {
      final pretty = TextTransforms.prettyJson(text);
      if (pretty != null) {
        actions.add(
          QuickAction(
            id: 'pretty_json',
            label: 'Pretty Print JSON & Paste',
            subtitle: 'format JSON with 2-space indentation',
            kind: QuickActionKind.transformAndPaste,
            transformedText: pretty,
          ),
        );
      }
      final minified = TextTransforms.minifyJson(text);
      if (minified != null) {
        actions.add(
          QuickAction(
            id: 'minify_json',
            label: 'Minify JSON & Paste',
            subtitle: 'compact JSON into a single line',
            kind: QuickActionKind.transformAndPaste,
            transformedText: minified,
          ),
        );
      }
    }

    actions.addAll([
      QuickAction(
        id: 'trim',
        label: 'Trim Whitespace & Paste',
        subtitle: 'strip leading and trailing whitespace',
        kind: QuickActionKind.transformAndPaste,
        transformedText: TextTransforms.trim(text),
      ),
      QuickAction(
        id: 'single_line',
        label: 'Collapse to Single Line & Paste',
        subtitle: 'replace line breaks and extra spaces with single spaces',
        kind: QuickActionKind.transformAndPaste,
        transformedText: TextTransforms.singleLine(text),
      ),
      QuickAction(
        id: 'lowercase',
        label: 'lowercase & Paste',
        subtitle: 'convert all characters to lowercase',
        kind: QuickActionKind.transformAndPaste,
        transformedText: TextTransforms.lowercase(text),
      ),
      QuickAction(
        id: 'uppercase',
        label: 'UPPERCASE & Paste',
        subtitle: 'convert all characters to uppercase',
        kind: QuickActionKind.transformAndPaste,
        transformedText: TextTransforms.uppercase(text),
      ),
      QuickAction(
        id: 'camel_case',
        label: 'camelCase & Paste',
        subtitle: 'convert identifier or phrase to camelCase',
        kind: QuickActionKind.transformAndPaste,
        transformedText: TextTransforms.toCamelCase(text),
      ),
      QuickAction(
        id: 'snake_case',
        label: 'snake_case & Paste',
        subtitle: 'convert identifier or phrase to snake_case',
        kind: QuickActionKind.transformAndPaste,
        transformedText: TextTransforms.toSnakeCase(text),
      ),
    ]);

    final urlDecoded = TextTransforms.urlDecode(text);
    if (urlDecoded != null && urlDecoded != text.trim()) {
      actions.add(
        QuickAction(
          id: 'url_decode',
          label: 'URL Decode & Paste',
          subtitle: 'decode percent-encoded URI components',
          kind: QuickActionKind.transformAndPaste,
          transformedText: urlDecoded,
        ),
      );
    }
    actions.add(
      QuickAction(
        id: 'url_encode',
        label: 'URL Encode & Paste',
        subtitle: 'percent-encode text for URLs',
        kind: QuickActionKind.transformAndPaste,
        transformedText: TextTransforms.urlEncode(text),
      ),
    );

    final b64Decoded = TextTransforms.base64DecodeText(text);
    if (b64Decoded != null && b64Decoded.isNotEmpty) {
      actions.add(
        QuickAction(
          id: 'base64_decode',
          label: 'Base64 Decode & Paste',
          subtitle: 'decode UTF-8 Base64 string',
          kind: QuickActionKind.transformAndPaste,
          transformedText: b64Decoded,
        ),
      );
    }
    actions.add(
      QuickAction(
        id: 'base64_encode',
        label: 'Base64 Encode & Paste',
        subtitle: 'encode UTF-8 text as Base64',
        kind: QuickActionKind.transformAndPaste,
        transformedText: TextTransforms.base64EncodeText(text),
      ),
    );
  }

  actions.addAll([
    QuickAction(
      id: 'toggle_pin',
      label: item.isPinned ? 'Unpin Item' : 'Pin Item',
      subtitle: 'pinned items stay at the top and are never pruned',
      kind: QuickActionKind.togglePin,
      shortcutHint: Platform.isMacOS ? '⌘P' : '⌃⇧P',
    ),
    const QuickAction(
      id: 'delete_item',
      label: 'Delete Item',
      subtitle: 'permanently remove from local history',
      kind: QuickActionKind.deleteItem,
      shortcutHint: '⌃D',
      isDanger: true,
    ),
  ]);

  return actions;
}

/// Floating keyboard-driven command palette triggered via Cmd+K / Ctrl+K.
class ActionPaletteOverlay extends StatefulWidget {
  const ActionPaletteOverlay({
    super.key,
    required this.item,
    required this.onExecute,
    required this.onClose,
  });

  final ClipboardItem item;
  final ValueChanged<QuickAction> onExecute;
  final VoidCallback onClose;

  @override
  State<ActionPaletteOverlay> createState() => _ActionPaletteOverlayState();
}

class _ActionPaletteOverlayState extends State<ActionPaletteOverlay> {
  final TextEditingController _filterController = TextEditingController();
  late final FocusNode _filterFocusNode;
  final ScrollController _scrollController = ScrollController();

  late List<QuickAction> _allActions;
  List<QuickAction> _filtered = const [];
  int _selectedIndex = 0;

  static const double _rowHeight = 36.0;

  @override
  void initState() {
    super.initState();
    _allActions = buildQuickActionsForItem(widget.item);
    _filtered = _allActions;
    _filterFocusNode = FocusNode(onKeyEvent: _handleKey);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _filterFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _filterController.dispose();
    _filterFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _applyFilter(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = _allActions;
      } else {
        _filtered = _allActions
            .where(
              (a) =>
                  a.label.toLowerCase().contains(q) ||
                  a.subtitle.toLowerCase().contains(q),
            )
            .toList();
      }
      _selectedIndex = 0;
    });
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    final hardware = HardwareKeyboard.instance;
    final isControl = hardware.isControlPressed;
    final isMeta = hardware.isMetaPressed;
    final isPrimaryMod =
        Platform.isMacOS ? (isMeta && !isControl) : (isControl && !isMeta);

    if (key == LogicalKeyboardKey.escape ||
        (isPrimaryMod && key == LogicalKeyboardKey.keyK)) {
      widget.onClose();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowDown ||
        (isControl && !isMeta && key == LogicalKeyboardKey.keyN)) {
      _move(1);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowUp ||
        (isControl && !isMeta && key == LogicalKeyboardKey.keyP)) {
      _move(-1);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (_filtered.isNotEmpty) {
        final idx = _selectedIndex.clamp(0, _filtered.length - 1);
        widget.onExecute(_filtered[idx]);
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _move(int delta) {
    if (_filtered.isEmpty) return;
    setState(() {
      _selectedIndex = (_selectedIndex + delta).clamp(0, _filtered.length - 1);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureVisible());
  }

  void _ensureVisible() {
    if (!_scrollController.hasClients || _filtered.isEmpty) return;
    final top = _selectedIndex * _rowHeight;
    final bottom = top + _rowHeight;
    final viewport = _scrollController.position.viewportDimension;
    final offset = _scrollController.offset;
    if (top < offset) {
      _scrollController.jumpTo(top);
    } else if (bottom > offset + viewport) {
      _scrollController.jumpTo(
        (bottom - viewport).clamp(0.0, _scrollController.position.maxScrollExtent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.52),
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () {},
          child: Container(
            width: 440,
            constraints: const BoxConstraints(maxHeight: 340),
            decoration: BoxDecoration(
              color: OmarchyTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: OmarchyTheme.borderActive, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x88000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search header
                Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: OmarchyTheme.border, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        ':',
                        style: OmarchyTheme.mono(
                          size: 13.5,
                          weight: FontWeight.w700,
                          color: OmarchyTheme.accent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _filterController,
                          focusNode: _filterFocusNode,
                          autofocus: true,
                          onChanged: _applyFilter,
                          cursorColor: OmarchyTheme.accent,
                          style: OmarchyTheme.mono(size: 12.5),
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: 'run action or transform...',
                            hintStyle: OmarchyTheme.mono(
                              size: 12,
                              color: OmarchyTheme.textMuted,
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      Text(
                        'esc',
                        style: OmarchyTheme.mono(
                          size: 10.5,
                          color: OmarchyTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                // Action list
                Flexible(
                  child: _filtered.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'no matching actions',
                            style: OmarchyTheme.mono(
                              size: 12,
                              color: OmarchyTheme.textMuted,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemExtent: _rowHeight,
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final action = _filtered[index];
                            final selected = index == _selectedIndex;
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => widget.onExecute(action),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? OmarchyTheme.selectionBg
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              action.label,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: OmarchyTheme.mono(
                                                size: 12,
                                                weight: selected
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                                color: selected
                                                    ? OmarchyTheme.selectionFg
                                                    : (action.isDanger
                                                        ? OmarchyTheme.danger
                                                        : OmarchyTheme
                                                            .textPrimary),
                                              ),
                                            ),
                                            Text(
                                              action.subtitle,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: OmarchyTheme.mono(
                                                size: 10,
                                                color: selected
                                                    ? OmarchyTheme.selectionFg
                                                        .withValues(alpha: 0.72)
                                                    : OmarchyTheme.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (action.shortcutHint != null) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          action.shortcutHint!,
                                          style: OmarchyTheme.mono(
                                            size: 10.5,
                                            color: selected
                                                ? OmarchyTheme.selectionFg
                                                    .withValues(alpha: 0.8)
                                                : OmarchyTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
