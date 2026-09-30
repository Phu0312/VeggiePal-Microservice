import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App khởi động, rơi về mock data khi không có server', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const VeggiePalApp());

    // Cho các request tới localhost thất bại thật (server tắt) để kích hoạt Mock Fallback.
    await tester.runAsync(() => Future.delayed(const Duration(seconds: 2)));
    await tester.pumpAndSettle();

    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Thực đơn'), findsOneWidget);
    expect(find.text('Bún riêu chay thanh đạm'), findsOneWidget); // video mock hiển thị
  });
}
