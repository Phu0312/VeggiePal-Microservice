import 'package:dio/dio.dart' show ProgressCallback;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:VeggiePal/core/constants/endpoints.dart';
import 'package:VeggiePal/core/network/api_client.dart';
import 'package:VeggiePal/features/admin/data/admin_models.dart';
import 'package:VeggiePal/features/admin/data/admin_repository.dart';
import 'package:VeggiePal/features/admin/presentation/moderation_tab.dart';

/// ApiClient giả: ghi lại lời gọi và trả kết quả theo đường dẫn, không đụng tới mạng.
class FakeApi extends ApiClient {
  final calls = <String>[];
  final queries = <String, Map<String, dynamic>?>{};
  final bodies = <String, Object?>{};
  final results = <String, Object?>{};
  Object? error; // ném lỗi này ở lần ghi (PUT / DELETE) tiếp theo

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    calls.add('GET $path');
    queries[path] = query;
    return results[path];
  }

  @override
  Future<dynamic> put(String path, {Object? body}) async {
    calls.add('PUT $path');
    bodies[path] = body;
    final e = error;
    if (e != null) {
      error = null;
      throw e;
    }
    return null;
  }

  @override
  Future<dynamic> delete(String path) async {
    calls.add('DELETE $path');
    return null;
  }

  @override
  Future<dynamic> post(String path,
      {Object? body, Map<String, String>? headers, ProgressCallback? onSendProgress, Duration? receiveTimeout}) async {
    calls.add('POST $path');
    bodies[path] = body;
    return results[path];
  }
}

Map<String, dynamic> _case(int id, {String type = 'BLOG'}) => {
      'caseId': id,
      'contentType': type,
      'externalContentId': 40 + id,
      'authorId': 7,
      'content': 'Món này dùng nước mắm',
      'decision': 'REVIEW_REQUIRED',
      'categories': ['animal_derived'],
      'reason': 'Có nguyên liệu nguồn gốc động vật',
      'confidence': 0.72,
      'createdAt': '2026-10-28T09:00:00',
    };

void main() {
  setUp(() => dotenv.loadFromString(envString: 'APP=test'));

  test('formatVnd / formatCount ngăn cách hàng nghìn bằng dấu chấm', () {
    expect(formatVnd(0), '0 ₫');
    expect(formatVnd(29000), '29.000 ₫');
    expect(formatVnd(1250000), '1.250.000 ₫');
    expect(formatVnd(-59000), '-59.000 ₫');
    expect(formatCount(12450), '12.450');
  });

  test('ModerationCase đọc lớp vi phạm, độ tin cậy và loại nội dung', () {
    final c = ModerationCase.fromJson(_case(3, type: 'COMMENT'));
    expect(c.typeLabel, 'Bình luận');
    expect(c.categories, ['animal_derived']);
    expect(c.confidence, 0.72);
    expect(c.externalContentId, 43);
  });

  test('UsageSummary tính tổng token và tỉ lệ lỗi', () {
    final s = UsageSummary.fromJson({
      'periodDays': 7,
      'requests': 200,
      'promptTokens': 1000,
      'completionTokens': 500,
      'averageLatencyMs': 812.5,
      'failedRequests': 10,
    });
    expect(s.totalTokens, 1500);
    expect(s.failureRate, 0.05);
    expect(const UsageSummary(7, 0, 0, 0, 0, 0).failureRate, 0);
  });

  test('UsageLog: khách có userId null, trạng thái khác SUCCESS là lỗi', () {
    final l = UsageLog.fromJson(
        {'id': 1, 'userId': null, 'feature': 'CHAT', 'model': 'm', 'status': 'FAILED', 'latencyMs': 90});
    expect(l.userId, isNull);
    expect(l.failed, isTrue);
    expect(aiFeatureLabel('CHAT'), 'Chatbot');
    expect(aiFeatureLabel('LẠ'), 'LẠ');
  });

  test('PaymentOrder, Revenue và PaymentStatistics', () {
    final o = PaymentOrder.fromJson({
      'id': 1,
      'orderCode': 99,
      'userId': 5,
      'planCode': 'PLUS',
      'amount': 29000,
      'status': 'PAID',
      'createdAt': '2026-10-20T08:00:00Z',
    });
    expect(o.amount, 29000);
    expect(o.createdAt!.isUtc, isFalse); // đổi sang giờ máy
    expect(paymentStatusLabel('PAID'), 'Đã thanh toán');

    final r = Revenue.fromJson({
      'totalRevenue': 87000,
      'paidTransactions': 3,
      'groupBy': 'DAY',
      'points': [
        {'period': '2026-10-20', 'transactionCount': 2, 'revenue': 58000},
        {'period': '2026-10-21', 'transactionCount': 1, 'revenue': 29000},
      ],
    });
    expect(r.points.map((p) => p.revenue), [58000, 29000]);

    final st = PaymentStatistics.fromJson({
      'statusDistribution': [
        {'key': 'PAID', 'count': 3, 'amount': 87000}
      ],
      'planDistribution': [
        {'key': 'PLUS', 'count': 2, 'amount': 58000}
      ],
      'transactionTrend': [],
    });
    expect(st.byStatus.single.key, 'PAID');
    expect(st.byPlan.single.amount, 58000);
  });

  group('AdminRepository', () {
    test('duyệt / từ chối gửi decision đúng; lý do trống thì không gửi', () async {
      final api = FakeApi();
      final repo = AdminRepository(api);
      await repo.review(3, approve: true);
      expect(api.bodies[Endpoints.aiModerationCase(3)], {'decision': 'APPROVED'});
      await repo.review(3, approve: false, reason: '  Vi phạm  ');
      expect(api.bodies[Endpoints.aiModerationCase(3)], {'decision': 'REJECTED', 'reason': 'Vi phạm'});
    });

    test('bỏ qua dùng DELETE, lý do được mã hoá trong query', () async {
      final api = FakeApi();
      await AdminRepository(api).dismiss(4);
      await AdminRepository(api).dismiss(4, reason: 'Báo nhầm & trùng');
      expect(api.calls, [
        'DELETE /ai/admin/moderation/4',
        'DELETE /ai/admin/moderation/4?reason=B%C3%A1o+nh%E1%BA%A7m+%26+tr%C3%B9ng',
      ]);
    });

    test('thanh toán gửi mốc thời gian dạng UTC và mã gói', () async {
      final api = FakeApi()
        ..results[Endpoints.adminPaymentSummary] = {
          'totalRevenue': 58000,
          'totalTransactions': 4,
          'paidTransactions': 2,
          'pendingTransactions': 1,
          'cancelledTransactions': 1,
          'failedTransactions': 0,
          'averagePaidAmount': 29000,
        };
      final from = DateTime.utc(2026, 10, 1, 3);
      final s = await AdminRepository(api).paymentSummary(from: from, planCode: 'PLUS');
      expect(s.totalRevenue, 58000);
      final q = api.queries[Endpoints.adminPaymentSummary]!;
      expect(q['from'], '2026-10-01T03:00:00.000Z');
      expect(q['planCode'], 'PLUS');
    });

    test('nhật ký AI chỉ gửi bộ lọc đã chọn', () async {
      final api = FakeApi()
        ..results[Endpoints.aiUsageLogs] = {'items': [], 'page': 0, 'totalPages': 0, 'totalElements': 0};
      await AdminRepository(api).usageLogs(feature: 'CHAT', page: 2);
      expect(api.queries[Endpoints.aiUsageLogs], {'feature': 'CHAT', 'page': 2, 'size': 20});
    });

    test('IngredientPayload gửi đủ trường đúng tên của backend', () {
      final json = const IngredientPayload(
              name: ' Đậu hũ ', description: ' trắng ', calories: 76, protein: 8.1, carbs: 1.9, fat: 4.8, vegan: true)
          .toJson();
      expect(json['name'], 'Đậu hũ');
      expect(json['description'], 'trắng');
      expect(json['caloriesPer100g'], 76);
      expect(json['fiberPer100g'], isNull);
      expect(json['allergen'], false);
      expect(json['active'], true);
    });
  });

  group('ModerationTab', () {
    Future<FakeApi> boot(WidgetTester tester) async {
      final api = FakeApi()..results[Endpoints.aiModeration] = [_case(1), _case(2, type: 'VIDEO')];
      await tester.pumpWidget(Provider<AdminRepository>.value(
        value: AdminRepository(api),
        child: const MaterialApp(home: Scaffold(body: ModerationTab())),
      ));
      await tester.pumpAndSettle();
      return api;
    }

    testWidgets('hiện các ca đang chờ với lý do của AI', (tester) async {
      await boot(tester);
      expect(find.text('Bài viết #41'), findsOneWidget);
      expect(find.text('Video #42'), findsOneWidget);
      expect(find.textContaining('Có nguyên liệu nguồn gốc động vật'), findsNWidgets(2));
      expect(find.textContaining('72%'), findsNWidgets(2));
    });

    testWidgets('từ chối kèm lý do thì ca rời khỏi hàng đợi', (tester) async {
      final api = await boot(tester);
      await tester.tap(find.text('Từ chối').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Vi phạm quy định');
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.widgetWithText(FilledButton, 'Từ chối')));
      await tester.pumpAndSettle();

      expect(api.bodies[Endpoints.aiModerationCase(1)], {'decision': 'REJECTED', 'reason': 'Vi phạm quy định'});
      expect(find.text('Bài viết #41'), findsNothing);
      expect(find.text('Video #42'), findsOneWidget);
    });

    testWidgets('hủy hộp thoại thì không gọi backend', (tester) async {
      final api = await boot(tester);
      await tester.tap(find.text('Duyệt').first);
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Hủy')));
      await tester.pumpAndSettle();
      expect(api.calls.where((c) => c.startsWith('PUT')), isEmpty);
      expect(find.text('Bài viết #41'), findsOneWidget);
    });

    testWidgets('ca đã được xử lý ở nơi khác (6013): báo lỗi rồi tải lại hàng đợi', (tester) async {
      final api = await boot(tester);
      api.error = ApiException('Ca kiểm duyệt này đã được xử lý.', code: 6013, statusCode: 409);
      api.results[Endpoints.aiModeration] = [_case(2, type: 'VIDEO')]; // ca 1 đã được người khác xử lý
      await tester.tap(find.text('Duyệt').first);
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.widgetWithText(FilledButton, 'Duyệt')));
      await tester.pumpAndSettle();

      expect(find.text('Ca kiểm duyệt này đã được xử lý.'), findsOneWidget); // popup lỗi
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();
      expect(find.text('Bài viết #41'), findsNothing);
      expect(find.text('Video #42'), findsOneWidget);
    });
  });
}
