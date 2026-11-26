import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/omarchy_theme.dart';
import '../data/database/app_database.dart';
import '../providers/clipboard_ui_providers.dart';
import '../providers/service_providers.dart';
import 'widgets/history_list_pane.dart';
import 'widgets/preview_pane.dart';
import 'widgets/search_header.dart';
import 'widgets/status_footer.dart';

class ClipboardOverlayPage extends ConsumerStatefulWidget {
  const ClipboardOverlayPage({super.key});

  @override
  ConsumerState<ClipboardOverlayPage> createState() =>
      _ClipboardOverlayPageState();
}

class _ClipboardOverlayPageState extends ConsumerState<ClipboardOverlayPage> {
  final TextEditingController _searchController = TextEditingController();
  late final FocusNode _searchFocusNode;

  List<ClipboardItem> _latestItems = const [];

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode(onKeyEvent: _handleKeyEvent);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    final hardware = HardwareKeyboard.instance;
    final isControl = hardware.isControlPressed;
    final isMeta = hardware.isMetaPressed;
    final isShift = hardware.isShiftPressed;

    // Esc -> hide overlay and return focus to previous app
    if (key == LogicalKeyboardKey.escape) {
      ref
          .read(windowControllerServiceProvider)
          .hideOverlay(restoreFocus: true);
      return KeyEventResult.handled;
    }

    // Up / Down or Ctrl+P / Ctrl+N -> navigate list
    if (key == LogicalKeyboardKey.arrowDown ||
        (isControl && !isMeta && !isShift && key == LogicalKeyboardKey.keyN)) {
      _moveSelection(1);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowUp ||
        (isControl && !isMeta && !isShift && key == LogicalKeyboardKey.keyP)) {
      _moveSelection(-1);
      return KeyEventResult.handled;
    }

    // Enter / Shift+Enter -> paste selected item
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      final selected = _currentSelectedItem();
      if (selected != null) {
        ref.read(windowControllerServiceProvider).pasteItem(
              selected,
              forcePlainText: isShift,
            );
      }
      return KeyEventResult.handled;
    }

    // Cmd+P (macOS) or Ctrl+Shift+P (Windows/all) -> toggle pin
    final isPinShortcut = (Platform.isMacOS && isMeta && !isControl && key == LogicalKeyboardKey.keyP) ||
        (isControl && isShift && key == LogicalKeyboardKey.keyP);
    if (isPinShortcut) {
      final selected = _currentSelectedItem();
      if (selected != null) {
        ref.read(clipboardMonitorServiceProvider).togglePin(selected.id);
      }
      return KeyEventResult.handled;
    }

    // Ctrl+D, or Delete when search box is empty -> delete selected item
    final isDeleteShortcut =
        (isControl && !isMeta && key == LogicalKeyboardKey.keyD) ||
            (_searchController.text.isEmpty &&
                key == LogicalKeyboardKey.delete);
    if (isDeleteShortcut) {
      final selected = _currentSelectedItem();
      if (selected != null) {
        ref.read(clipboardMonitorServiceProvider).deleteItem(selected.id);
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _moveSelection(int delta) {
    if (_latestItems.isEmpty) return;
    final current = ref.read(selectedIndexProvider);
    final next = (current + delta).clamp(0, _latestItems.length - 1);
    ref.read(selectedIndexProvider.notifier).state = next;
  }

  ClipboardItem? _currentSelectedItem() {
    if (_latestItems.isEmpty) return null;
    final idx =
        ref.read(selectedIndexProvider).clamp(0, _latestItems.length - 1);
    return _latestItems[idx];
  }

  @override
  Widget build(BuildContext context) {
    // Re-focus search input and clear stale text whenever overlay is summoned.
    ref.listen<int>(overlayShowCounterProvider, (_, __) {
      _searchController.clear();
      _searchFocusNode.requestFocus();
    });

    final itemsAsync = ref.watch(clipboardItemsProvider);
    final totalCount = ref.watch(clipboardTotalCountProvider).valueOrNull ?? 0;
    final rawSelectedIndex = ref.watch(selectedIndexProvider);

    final items = itemsAsync.valueOrNull ?? const <ClipboardItem>[];
    _latestItems = items;

    final selectedIndex =
        items.isEmpty ? 0 : rawSelectedIndex.clamp(0, items.length - 1);
    final selectedItem = items.isEmpty ? null : items[selectedIndex];

    // ContinuousRectangleBorder implements Apple's smooth superellipse (Squircle)
    // curve. Its radius parameter maps ~2.2x to a standard circular radius.
    final squircleRadius = Platform.isMacOS ? 36.0 : 24.0;
    final squircleShape = ContinuousRectangleBorder(
      borderRadius: BorderRadius.circular(squircleRadius),
    );
    final squircleBorderShape = ContinuousRectangleBorder(
      borderRadius: BorderRadius.circular(squircleRadius),
      side: BorderSide(
        color: OmarchyTheme.borderActive.withValues(alpha: 0.9),
        width: 1,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(0.5),
        child: Container(
          decoration: ShapeDecoration(
            color: OmarchyTheme.bg,
            shape: squircleShape,
          ),
          foregroundDecoration: ShapeDecoration(
            shape: squircleBorderShape,
          ),
          child: ClipPath(
            clipper: ShapeBorderClipper(shape: squircleShape),
            child: Column(
            children: [
              SearchHeader(
                controller: _searchController,
                focusNode: _searchFocusNode,
                matchedCount: items.length,
                totalCount: totalCount,
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).state = value;
                  ref.read(selectedIndexProvider.notifier).state = 0;
                },
              ),
              Expanded(
                child: Row(
                  children: [
                    // Left Pane (40%): Compact History List
                    Expanded(
                      flex: 40,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: OmarchyTheme.surface,
                          border: Border(
                            right: BorderSide(color: OmarchyTheme.border, width: 1),
                          ),
                        ),
                        child: HistoryListPane(
                          items: items,
                          selectedIndex: selectedIndex,
                          onSelect: (index) {
                            ref.read(selectedIndexProvider.notifier).state = index;
                            _searchFocusNode.requestFocus();
                          },
                          onActivate: (item) {
                            ref
                                .read(windowControllerServiceProvider)
                                .pasteItem(item, forcePlainText: false);
                          },
                        ),
                      ),
                    ),
                    // Right Pane (60%): Full Preview + Status Footer
                    Expanded(
                      flex: 60,
                      child: Column(
                        children: [
                          Expanded(child: PreviewPane(item: selectedItem)),
                          StatusFooter(item: selectedItem),
                        ],
                      ),
                    ),
                  ],
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
