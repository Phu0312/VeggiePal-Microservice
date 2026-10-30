import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Chọn [target] ở ô FilterDropdown đang hiện [current]: mở danh sách rồi bấm mục cần chọn.
/// Dùng pump có thời gian thay vì pumpAndSettle vì vài màn hình có vòng quay tải dữ liệu chạy mãi.
Future<void> pickFilter(WidgetTester tester, String current, String target) async {
  await tester.tap(find.descendant(of: find.byType(InkWell), matching: find.text(current)).first);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.tap(find.widgetWithText(MenuItemButton, target));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}
