import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:VeggiePal/main.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _boot(WidgetTester tester) async {
  dotenv.loadFromString(envString: 'APP=test');
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(const VeggiePalApp());
  // Cho các request tới localhost thất bại thật (server tắt).
  await tester.runAsync(() => Future.delayed(const Duration(seconds: 2)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Không lấy được dữ liệu từ backend thì hiện popup lỗi, không có mock data', (tester) async {
    await _boot(tester);

    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Không thể lấy dữ liệu'), findsOneWidget); // popup lỗi (không bị chồng nhiều lần)
    expect(find.text('Bún riêu chay thanh đạm'), findsNothing); // không còn video mock
  });

  testWidgets('Navbar 5 mục, đổi tab, đổi giao diện sáng/tối và mở chuông thông báo', (tester) async {
    await _boot(tester);
    // Đóng popup lỗi khi mở app (nếu có; bộ nhớ dedupe popup dùng chung giữa các test).
    if (find.text('Đóng').evaluate().isNotEmpty) {
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();
    }

    for (final l in ['Trang chủ', 'Quán chay', 'Trợ lý AI', 'Thực đơn', 'Hồ sơ']) {
      expect(find.text(l), findsOneWidget, reason: l);
    }

    await tester.tap(find.text('Hồ sơ'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn chưa đăng nhập'), findsOneWidget);

    // Nút tròn giữa mở tab Trợ lý AI.
    await tester.tap(find.byIcon(LucideIcons.sparkles));
    await tester.pumpAndSettle();
    expect(find.textContaining('Dùng thử: còn'), findsOneWidget);

    // Đổi sang giao diện tối.
    expect(Theme.of(tester.element(find.byType(Scaffold).first)).brightness, Brightness.light);
    await tester.tap(find.byIcon(LucideIcons.moon));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(Scaffold).first)).brightness, Brightness.dark);

    // Khách bấm chuông -> mời đăng nhập.
    await tester.tap(find.byIcon(LucideIcons.bell));
    await tester.pumpAndSettle();
    expect(find.text('Đăng nhập để nhận thông báo về bài viết của bạn.'), findsOneWidget);
  });
}
