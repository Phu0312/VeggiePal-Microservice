import 'package:dio/dio.dart' show ProgressCallback;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:VeggiePal/core/constants/endpoints.dart';
import 'package:VeggiePal/core/network/api_client.dart';
import 'package:VeggiePal/features/auth/data/auth_models.dart';
import 'package:VeggiePal/features/auth/data/auth_repository.dart';
import 'package:VeggiePal/features/auth/presentation/auth_controller.dart';
import 'package:VeggiePal/core/storage/session_store.dart';
import 'package:VeggiePal/features/payment/data/payment_models.dart';
import 'package:VeggiePal/features/payment/data/payment_repository.dart';
import 'package:VeggiePal/features/payment/data/subscription_controller.dart';
import 'package:VeggiePal/features/payment/presentation/checkout_screen.dart';
import 'package:VeggiePal/features/payment/presentation/pricing_screen.dart';

/// ApiClient giả: trả kết quả theo đường dẫn (có thể là hàm để đổi theo thời gian), không đụng tới mạng.
class FakeApi extends ApiClient {
  final calls = <String>[];
  final bodies = <String, Object?>{};
  final results = <String, Object? Function()>{};
  final errors = <String, ApiException>{};

  /// Gắn kết quả cho một đường dẫn (dùng trong chuỗi cascade).
  void on(String path, Object? Function() answer) => results[path] = answer;

  Object? _answer(String method, String path) {
    calls.add('$method $path');
    final e = errors[path];
    if (e != null) throw e;
    return results[path]?.call();
  }

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async => _answer('GET', path);

  @override
  Future<dynamic> post(String path,
      {Object? body, Map<String, String>? headers, ProgressCallback? onSendProgress, Duration? receiveTimeout}) async {
    bodies[path] = body;
    return _answer('POST', path);
  }
}

Map<String, dynamic> _order({
  int id = 11,
  String status = 'PENDING',
  String planCode = 'PLUS',
  DateTime? expiredAt,
  String? qr = '00020101021238570010A000000727',
}) =>
    {
      'id': id,
      'orderCode': 123456,
      'planCode': planCode,
      'amount': 29000,
      'status': status,
      'checkoutUrl': 'https://pay.payos.vn/web/abc',
      'qrCode': qr,
      'accountName': 'CONG TY VEGGIEPAL',
      'accountNumber': '0123456789',
      'bin': '970422',
      'description': 'VeggiePal PLUS',
      'expiredAt': (expiredAt ?? DateTime.now().add(const Duration(minutes: 10))).toUtc().toIso8601String(),
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'paidAt': status == 'PAID' ? DateTime.now().toUtc().toIso8601String() : null,
    };

const _plans = [
  {'id': 1, 'code': 'FREE', 'price': 0, 'durationDays': 0, 'chatPerDay': 5, 'mealPlansPerMonth': 2, 'videosPerMonth': 0},
  {'id': 2, 'code': 'PLUS', 'price': 29000, 'durationDays': 30, 'chatPerDay': 20, 'mealPlansPerMonth': 8, 'videosPerMonth': 3},
  {'id': 3, 'code': 'PRO', 'price': 59000, 'durationDays': 30, 'chatPerDay': 50, 'mealPlansPerMonth': 20, 'videosPerMonth': 8},
];

Map<String, dynamic> _sub(String code) => {
      'planCode': code,
      'startedAt': code == 'FREE' ? null : '2026-10-01T00:00:00Z',
      'expiresAt': code == 'FREE' ? null : '2026-12-01T00:00:00Z',
      'chatPerDay': code == 'PRO' ? 50 : (code == 'PLUS' ? 20 : 5),
      'mealPlansPerMonth': code == 'PRO' ? 20 : (code == 'PLUS' ? 8 : 2),
      'videosPerMonth': code == 'PRO' ? 8 : (code == 'PLUS' ? 3 : 0),
    };

/// Màn hình rất cao để ListView dựng sẵn toàn bộ nội dung (danh sách chỉ dựng phần đang nhìn thấy).
void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() => dotenv.loadFromString(envString: 'APP=test'));

  group('mô hình', () {
    test('Plan và Subscription đọc hạn mức; gói FREE không có hạn', () {
      final plus = Plan.fromJson(Map<String, dynamic>.from(_plans[1]));
      expect(plus.isFree, isFalse);
      expect(plus.videosPerMonth, 3);
      expect(Plan.fromJson(Map<String, dynamic>.from(_plans[0])).isFree, isTrue);

      final free = Subscription.fromJson(_sub('FREE'));
      expect(free.isPaid, isFalse);
      expect(free.expiresAt, isNull);
      expect(Subscription.fromJson(_sub('PRO')).expiresAt, isNotNull);
      expect(planName('PRO'), 'Gói Pro Chuyên Sâu');
    });

    test('UserOrder.isPayable: cần PENDING, có mã QR và chưa quá hạn', () {
      final now = DateTime.now();
      expect(UserOrder.fromJson(_order()).isPayable(now), isTrue);
      expect(UserOrder.fromJson(_order(status: 'PAID')).isPayable(now), isFalse);
      expect(UserOrder.fromJson(_order(qr: null)).isPayable(now), isFalse);
      expect(
          UserOrder.fromJson(_order(expiredAt: now.subtract(const Duration(minutes: 1)))).isPayable(now), isFalse);
    });

    test('đọc id từ orderId, tên ngân hàng theo BIN, đếm ngược không âm', () {
      final o = UserOrder.fromJson({..._order(), 'id': null, 'orderId': 77});
      expect(o.id, 77);
      expect(o.bankName, 'MB Bank');
      expect(bankNameOf('123456'), contains('123456'));
      expect(bankNameOf(null), '-');
      final t = DateTime(2026, 10, 29, 12);
      expect(formatCountdown(t.add(const Duration(minutes: 9, seconds: 5)), t), '09:05');
      expect(formatCountdown(t.subtract(const Duration(minutes: 1)), t), '00:00');
      expect(orderStatusLabel('PENDING'), 'Chưa thanh toán');
    });
  });

  group('PaymentRepository', () {
    test('mã lỗi 6003 là "không thấy đơn hàng" chứ không phải hết lượt AI', () async {
      final api = FakeApi()
        ..errors[Endpoints.paymentOrder(5)] =
            ApiException('Bạn đã hết lượt sử dụng tính năng AI theo gói hiện tại.', code: 6003, statusCode: 404);
      api.token = 't';
      await expectLater(PaymentRepository(api).order(5),
          throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Không tìm thấy đơn hàng.')));
    });

    test('lỗi ngoài dải payment được giữ nguyên', () async {
      final api = FakeApi()..errors[Endpoints.paymentHistory] = ApiException('Phiên hết hạn', code: 1008, statusCode: 401);
      api.token = 't';
      await expectLater(PaymentRepository(api).history(), throwsA(isA<ApiException>().having((e) => e.message, 'm', 'Phiên hết hạn')));
    });

    test('checkout gửi planCode; chưa đăng nhập thì không gọi máy chủ', () async {
      final api = FakeApi()..on(Endpoints.paymentCheckout, () => _order());
      await expectLater(PaymentRepository(api).checkout('PLUS'), throwsA(isA<ApiException>()));
      expect(api.calls, isEmpty);

      api.token = 't';
      final o = await PaymentRepository(api).checkout('PLUS');
      expect(api.bodies[Endpoints.paymentCheckout], {'planCode': 'PLUS'});
      expect(o.planCode, 'PLUS');
    });
  });

  test('SubscriptionController tải gói khi đăng nhập và xoá khi đăng xuất', () async {
    final api = FakeApi()..on(Endpoints.mySubscription, () => _sub('PLUS'));
    api.token = 't';
    final c = SubscriptionController(PaymentRepository(api))..bindUser(3);
    await pumpEventQueue();
    expect(c.subscription!.planCode, 'PLUS');
    c.bindUser(null);
    expect(c.subscription, isNull);
  });

  group('CheckoutScreen', () {
    Future<(FakeApi, SubscriptionController)> boot(WidgetTester tester, UserOrder order) async {
      final api = FakeApi()
        ..on(Endpoints.mySubscription, () => _sub('PLUS'))
        ..on(Endpoints.paymentOrder(order.id), () => _order(id: order.id));
      api.token = 't';
      useTallScreen(tester);
      final sub = SubscriptionController(PaymentRepository(api))..bindUser(3);
      await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<PaymentRepository>.value(value: PaymentRepository(api)),
          ChangeNotifierProvider<SubscriptionController>.value(value: sub),
        ],
        // Mở từ một màn trước để Navigator.pop của màn thanh toán có chỗ quay về.
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => CheckoutScreen(order: order))),
              child: const Text('mở'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('mở'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      return (api, sub);
    }

    testWidgets('hiện mã QR, số tiền và thông tin chuyển khoản', (tester) async {
      await boot(tester, UserOrder.fromJson(_order()));
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('29.000 ₫'), findsOneWidget);
      expect(find.text('0123456789'), findsOneWidget);
      expect(find.text('MB Bank'), findsOneWidget);
      expect(find.textContaining('Hết hạn sau'), findsOneWidget);
      // Rời màn hình: dừng bộ hẹn giờ để bài test kết thúc sạch.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('khi đơn chuyển sang PAID thì báo thành công và tải lại gói', (tester) async {
      final (api, sub) = await boot(tester, UserOrder.fromJson(_order()));
      api.results[Endpoints.paymentOrder(11)] = () => _order(status: 'PAID');
      await tester.pump(const Duration(seconds: 3)); // lần hỏi lại kế tiếp
      await tester.pump();
      await tester.pump();

      expect(find.text('Thanh toán thành công'), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
      expect(sub.subscription?.planCode, 'PLUS');
      // Gói được tải lại: một lần khi gắn tài khoản, một lần sau khi đơn PAID.
      expect(api.calls.where((c) => c == 'GET ${Endpoints.mySubscription}').length, 2);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('đơn quá hạn thì mời tạo lại mã và dùng đơn mới', (tester) async {
      final expired = UserOrder.fromJson(_order(expiredAt: DateTime.now().subtract(const Duration(minutes: 1))));
      final (api, _) = await boot(tester, expired);
      api.results[Endpoints.paymentCheckout] = () => _order(id: 12);
      api.results[Endpoints.paymentOrder(11)] = () => _order(id: 11, status: 'PENDING', expiredAt: DateTime.now().subtract(const Duration(minutes: 1)));
      expect(find.text('Mã QR đã hết hạn'), findsOneWidget);

      await tester.tap(find.text('Tạo lại mã'));
      await tester.pump();
      await tester.pump();

      expect(api.bodies[Endpoints.paymentCheckout], {'planCode': 'PLUS'});
      expect(find.byType(QrImageView), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('huỷ đơn: xác nhận rồi đóng màn hình', (tester) async {
      final (api, _) = await boot(tester, UserOrder.fromJson(_order()));
      api.results[Endpoints.paymentOrderCancel(11)] = () => _order(status: 'CANCELLED');

      await tester.tap(find.text('Huỷ thanh toán'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Huỷ đơn'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600)); // hiệu ứng đóng màn hình

      expect(api.calls, contains('POST ${Endpoints.paymentOrderCancel(11)}'));
      expect(find.byType(QrImageView), findsNothing);
      expect(find.text('mở'), findsOneWidget); // đã quay về màn trước
    });
  });

  group('PricingScreen', () {
    Future<FakeApi> boot(WidgetTester tester, {String current = 'FREE'}) async {
      final api = FakeApi()
        ..on(Endpoints.paymentPlans, () => _plans)
        ..on(Endpoints.mySubscription, () => _sub(current))
        ..on(Endpoints.paymentCheckout, () => _order(planCode: 'PRO'));
      api.token = 't';
      final auth = AuthController(api, AuthRepository(api), SessionStore(),
          initial: const AuthSession('t', AuthUser(id: 3, email: 'a@b.c', fullName: 'An', role: UserRole.user)));
      useTallScreen(tester);
      final sub = SubscriptionController(PaymentRepository(api))..bindUser(3);
      await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<PaymentRepository>.value(value: PaymentRepository(api)),
          ChangeNotifierProvider<AuthController>.value(value: auth),
          ChangeNotifierProvider<SubscriptionController>.value(value: sub),
        ],
        child: const MaterialApp(home: PricingScreen()),
      ));
      await tester.pumpAndSettle();
      return api;
    }

    testWidgets('liệt kê 3 gói với hạn mức và gói hiện tại', (tester) async {
      await boot(tester, current: 'PLUS');
      expect(find.text('Gói Khám Phá'), findsOneWidget);
      expect(find.text('29.000 ₫'), findsOneWidget);
      expect(find.text('59.000 ₫'), findsOneWidget);
      expect(find.textContaining('Hạn sử dụng đến'), findsOneWidget);
      expect(find.text('Gia hạn gói'), findsOneWidget); // đang dùng PLUS
      expect(find.text('Không có bóc tách công thức từ video'), findsOneWidget); // gói FREE
    });

    testWidgets('chọn gói khi đang dùng gói trả phí khác phải xác nhận trước', (tester) async {
      final api = await boot(tester, current: 'PLUS');
      await tester.tap(find.text('Chọn Gói Pro Chuyên Sâu'));
      await tester.pumpAndSettle();

      expect(find.textContaining('thay thế gói hiện tại'), findsOneWidget);
      expect(api.calls.where((c) => c.startsWith('POST')), isEmpty); // chưa tạo đơn

      await tester.tap(find.text('Tiếp tục'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(api.bodies[Endpoints.paymentCheckout], {'planCode': 'PRO'});
      expect(find.byType(QrImageView), findsOneWidget); // mở màn thanh toán
      await tester.pumpWidget(const SizedBox());
    });
  });
}
