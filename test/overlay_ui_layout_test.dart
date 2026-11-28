import 'package:clipm/core/constants/app_constants.dart';
import 'package:clipm/core/theme/omarchy_theme.dart';
import 'package:clipm/data/database/app_database.dart';
import 'package:clipm/data/database/daos/clipboard_dao.dart';
import 'package:clipm/data/database/tables/clipboard_items.dart';
import 'package:clipm/ui/widgets/search_header.dart';
import 'package:clipm/ui/widgets/status_footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('StatusFooter vertically centers metadata and shortcut hints', (
    WidgetTester tester,
  ) async {
    final now = DateTime(2026, 11, 28, 10, 50, 51);
    final item = ClipboardItem(
      id: 1,
      type: ClipboardItemType.text,
      plainText: 'Sample clipboard entry',
      contentHash: 'hash',
      sourceApp: 'Finder',
      charCount: 22,
      isPinned: false,
      createdAt: now,
      lastUsedAt: now,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: OmarchyTheme.build(),
        home: Scaffold(
          body: SizedBox(
            width: AppConstants.overlayWindowSize.width,
            child: StatusFooter(item: item),
          ),
        ),
      ),
    );

    final footerRect = tester.getRect(find.byType(StatusFooter));
    final metaRect = tester.getRect(
      find.text('TEXT | 22 chars | Finder | 2026-11-28 10:50:51'),
    );
    final hintsRect = tester.getRect(
      find.textContaining('paste', findRichText: true),
    );

    // Content sits centered inside the 29px inner height below the 1px top border.
    final innerCenterY = footerRect.top + 1 + (footerRect.height - 1) / 2;
    expect((metaRect.center.dy - innerCenterY).abs(), lessThanOrEqualTo(0.5));
    expect((hintsRect.center.dy - innerCenterY).abs(), lessThanOrEqualTo(0.5));
    expect((metaRect.center.dy - hintsRect.center.dy).abs(), lessThanOrEqualTo(0.1));
  });

  testWidgets('SearchHeader uses a thin cursor and vertically aligns chips', (
    WidgetTester tester,
  ) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    addTearDown(() {
      controller.dispose();
      focusNode.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: OmarchyTheme.build(),
        home: Scaffold(
          body: SizedBox(
            width: AppConstants.overlayWindowSize.width,
            child: SearchHeader(
              controller: controller,
              focusNode: focusNode,
              matchedCount: 57,
              totalCount: 57,
              filterMode: ClipboardFilterMode.all,
              onFilterChanged: (_) {},
              isPaused: false,
              onTogglePause: () {},
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.cursorWidth, lessThanOrEqualTo(2.0));

    final allRect = tester.getRect(find.text('ALL'));
    final countRect = tester.getRect(find.text('57/57'));
    expect((allRect.center.dy - countRect.center.dy).abs(), lessThanOrEqualTo(0.5));
  });
}
