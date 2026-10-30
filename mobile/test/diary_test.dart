import 'package:dio/dio.dart' show ProgressCallback;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:VeggiePal/core/constants/endpoints.dart';
import 'package:VeggiePal/core/network/api_client.dart';
import 'package:VeggiePal/features/nutrition/data/diary_models.dart';
import 'package:VeggiePal/features/nutrition/data/diary_repository.dart';
import 'package:VeggiePal/features/nutrition/presentation/add_food_sheet.dart';
import 'package:VeggiePal/features/nutrition/presentation/diary_screen.dart';

/// ApiClient giả: ghi lại lời gọi, query và body; trả kết quả theo đường dẫn; có thể ném lỗi ở lần gọi kế tiếp.
class _Api extends ApiClient {
  final calls = <String>[];
  final queries = <String, Map<String, dynamic>?>{};
  final bodies = <String, Object?>{};
  final results = <String, Object?>{};
  Object? error;

  Object? _hit(String method, String path, [Map<String, dynamic>? q]) {
    calls.add('$method $path');
    queries[path] = q;
    final e = error;
    if (e != null) {
      error = null;
      throw e;
    }
    return results[path];
  }

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async => _hit('GET', path, query);

  @override
  Future<dynamic> post(String path,
      {Object? body, Map<String, String>? headers, ProgressCallback? onSendProgress, Duration? receiveTimeout}) async {
    bodies[path] = body;
    return _hit('POST', path);
  }

  @override
  Future<dynamic> put(String path, {Object? body}) async {
    bodies[path] = body;
    return _hit('PUT', path);
  }

  @override
  Future<dynamic> delete(String path) async => _hit('DELETE', path);
}

Map<String, dynamic> _entry(int id, String meal, String name, int kcal) => {
      'id': id,
      'logDate': '2026-10-30',
      'mealType': meal,
      'foodName': name,
      'recipeId': null,
      'calories': kcal,
      'proteinG': 10,
      'carbsG': 20.5,
      'fatG': 5,
      'fiberG': 2,
    };

Map<String, dynamic> _summary({int consumed = 650, int target = 2000, int water = 500}) => {
      'date': '2026-10-30',
      'consumedCalories': consumed,
      'targetCalories': target,
      'remainingCalories': (target - consumed).clamp(0, target),
      'caloriesBurned': 120,
      'proteinG': 30.0,
      'targetProteinG': 100.0,
      'carbsG': 70.5,
      'targetCarbsG': 250.0,
      'fatG': 15.0,
      'targetFatG': 66.7,
      'fiberG': 6.0,
      'waterMl': water,
      'waterTargetMl': 2000,
      'waterGlasses': 2,
      'exerciseMinutes': 30,
      'steps': 4500,
      'activityNote': 'Đi bộ buổi sáng',
      'entries': [
        _entry(1, 'BREAKFAST', 'Phở chay', 400),
        _entry(2, 'LUNCH', 'Cơm gạo lứt', 250),
      ],
    };

void main() {
  setUp(() => dotenv.loadFromString(envString: 'APP=test'));

  group('mô hình', () {
    test('DailySummary đọc tổng kết, nhóm món theo bữa và tính tỉ lệ', () {
      final s = DailySummary.fromJson(_summary());
      expect(s.consumedCalories, 650);
      expect(s.entriesOf(MealSlot.breakfast).single.name, 'Phở chay');
      expect(s.caloriesOf(MealSlot.lunch), 250);
      expect(s.entriesOf(MealSlot.dinner), isEmpty);
      expect(s.calorieRatio, 650 / 2000);
      expect(s.overTarget, isFalse);
      expect(s.activity.waterMl, 500);
      expect(s.activity.note, 'Đi bộ buổi sáng');
      expect(s.waterRatio, 0.25);
    });

    test('vượt mục tiêu: thanh chỉ chạm 100% nhưng cờ overTarget bật', () {
      final s = DailySummary.fromJson(_summary(consumed: 2600));
      expect(s.calorieRatio, 1);
      expect(s.overTarget, isTrue);
    });

    test('MealSlot: mã lạ về bữa phụ, bữa mặc định theo giờ', () {
      expect(MealSlot.fromCode('LUNCH'), MealSlot.lunch);
      expect(MealSlot.fromCode('???'), MealSlot.snack);
      expect(MealSlot.forTime(DateTime(2026, 1, 1, 7)), MealSlot.breakfast);
      expect(MealSlot.forTime(DateTime(2026, 1, 1, 12)), MealSlot.lunch);
      expect(MealSlot.forTime(DateTime(2026, 1, 1, 18)), MealSlot.dinner);
      expect(MealSlot.forTime(DateTime(2026, 1, 1, 23)), MealSlot.snack);
    });

    test('isoDate và FoodDraft.toJson chỉ gửi trường có giá trị', () {
      expect(isoDate(DateTime(2026, 3, 5)), '2026-03-05');
      final json = const FoodDraft(name: ' Đậu hũ ', meal: MealSlot.dinner, calories: 120, protein: 8.5).toJson(DateTime(2026, 3, 5));
      expect(json, {'logDate': '2026-03-05', 'mealType': 'DINNER', 'foodName': 'Đậu hũ', 'calories': 120, 'proteinG': 8.5});
    });

    test('parseAmount: rỗng là null, dấu phẩy được chấp nhận, số âm hoặc chữ là NaN', () {
      expect(parseAmount(''), isNull);
      expect(parseAmount(' 12,5 '), 12.5);
      expect(parseAmount('-1')!.isNaN, isTrue);
      expect(parseAmount('abc')!.isNaN, isTrue);
    });
  });

  group('DiaryRepository', () {
    test('summary gửi ngày dạng yyyy-MM-dd', () async {
      final api = _Api()..results[Endpoints.dailySummary] = _summary();
      final s = await DiaryRepository(api).summary(DateTime(2026, 10, 30));
      expect(api.queries[Endpoints.dailySummary], {'date': '2026-10-30'});
      expect(s.entries.length, 2);
    });

    test('ghi món, xoá món, thêm nước, lưu vận động đúng đường dẫn và nội dung', () async {
      final api = _Api()
        ..results[Endpoints.foodLogs] = _entry(9, 'DINNER', 'Canh nấm', 90)
        ..results[Endpoints.water] = {'waterMl': 750, 'waterTargetMl': 2000, 'waterGlasses': 3}
        ..results[Endpoints.dailyActivity] = {'exerciseMinutes': 45, 'steps': 0, 'caloriesBurned': 0};
      final repo = DiaryRepository(api);
      final d = DateTime(2026, 10, 30);

      final e = await repo.addFood(d, const FoodDraft(name: 'Canh nấm', meal: MealSlot.dinner, calories: 90));
      expect(e.id, 9);
      expect(api.bodies[Endpoints.foodLogs], {'logDate': '2026-10-30', 'mealType': 'DINNER', 'foodName': 'Canh nấm', 'calories': 90});

      await repo.deleteFood(9);
      expect(api.calls.last, 'DELETE /nutrition/me/food-logs/9');

      expect((await repo.addWater(d, 250)).waterMl, 750);
      expect(api.bodies[Endpoints.water], {'date': '2026-10-30', 'amountMl': 250});

      final a = await repo.saveActivity(d, exerciseMinutes: 45, note: 'Chạy bộ');
      expect(a.exerciseMinutes, 45);
      expect(api.bodies[Endpoints.dailyActivity], {'date': '2026-10-30', 'exerciseMinutes': 45, 'activityNote': 'Chạy bộ'});
    });

    test('mã lỗi của nutrition-service được dịch riêng (2010 không bị hiểu là nguyên liệu)', () async {
      final api = _Api()..error = ApiException('x', code: 2010, statusCode: 404);
      await expectLater(DiaryRepository(api).deleteFood(1),
          throwsA(isA<ApiException>().having((e) => e.message, 'm', contains('nhật ký'))));
      api.error = ApiException('Khác', code: 1008, statusCode: 401);
      await expectLater(DiaryRepository(api).deleteFood(1), throwsA(isA<ApiException>().having((e) => e.message, 'm', 'Khác')));
    });
  });

  group('DiaryScreen', () {
    late _Api api;

    Future<void> mount(WidgetTester tester) async {
      api = _Api()..results[Endpoints.dailySummary] = _summary();
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(Provider<DiaryRepository>.value(
        value: DiaryRepository(api),
        child: const MaterialApp(home: DiaryScreen()),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('hiện calo, macro, nước, vận động và món theo bữa', (tester) async {
      await mount(tester);
      expect(find.text('650'), findsOneWidget);
      expect(find.textContaining('/ 2000 kcal'), findsOneWidget);
      expect(find.text('Còn 1350 kcal'), findsOneWidget);
      expect(find.text('500 / 2000 ml'), findsOneWidget);
      expect(find.text('Đi bộ buổi sáng'), findsOneWidget);
      expect(find.text('Bữa sáng • 400 kcal'), findsOneWidget);
      expect(find.text('Phở chay'), findsOneWidget);
      expect(find.text('Cơm gạo lứt'), findsOneWidget);
      expect(find.text('Chưa ghi món nào.'), findsNWidgets(2)); // bữa tối và bữa phụ
      expect(api.queries[Endpoints.dailySummary]!['date'], isoDate(DateTime.now()));
    });

    testWidgets('thêm nước +250 ml gọi BE rồi tải lại tổng kết', (tester) async {
      await mount(tester);
      api.results[Endpoints.water] = {'waterMl': 750};
      await tester.tap(find.text('+250 ml'));
      await tester.pumpAndSettle();
      expect(api.bodies[Endpoints.water], {'date': isoDate(DateTime.now()), 'amountMl': 250});
      expect(api.calls.where((c) => c == 'GET /nutrition/me/daily-summary').length, 2);
    });

    testWidgets('xoá một món', (tester) async {
      await mount(tester);
      await tester.tap(find.byTooltip('Xoá Phở chay'));
      await tester.pumpAndSettle();
      expect(api.calls, contains('DELETE /nutrition/me/food-logs/1'));
    });

    testWidgets('ghi món: tên bắt buộc, số âm bị chặn, hợp lệ thì gửi đúng bữa đã chọn', (tester) async {
      await mount(tester);
      api.results[Endpoints.foodLogs] = _entry(5, 'DINNER', 'Canh nấm', 90);
      await tester.tap(find.byTooltip('Thêm món vào bữa tối'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ghi vào nhật ký'));
      await tester.pump();
      expect(find.text('Vui lòng nhập tên món'), findsOneWidget);
      expect(api.bodies.containsKey(Endpoints.foodLogs), isFalse);

      await tester.enterText(find.widgetWithText(TextFormField, 'Tên món'), 'Canh nấm');
      await tester.enterText(find.widgetWithText(TextFormField, 'Năng lượng'), '-5');
      await tester.tap(find.text('Ghi vào nhật ký'));
      await tester.pump();
      expect(find.text('Nhập số từ 0 trở lên'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, 'Năng lượng'), '90');
      await tester.tap(find.text('Ghi vào nhật ký'));
      await tester.pumpAndSettle();

      final body = api.bodies[Endpoints.foodLogs] as Map;
      expect(body['foodName'], 'Canh nấm');
      expect(body['mealType'], 'DINNER');
      expect(body['calories'], 90);
      expect(body.containsKey('proteinG'), isFalse);
    });

    testWidgets('sang ngày trước tải lại với ngày đó và không đi quá hôm nay', (tester) async {
      await mount(tester);
      final today = DateTime.now();
      expect(tester.widget<IconButton>(find.ancestor(of: find.byTooltip('Ngày sau'), matching: find.byType(IconButton)).first).onPressed, isNull);

      await tester.tap(find.byTooltip('Ngày trước'));
      await tester.pumpAndSettle();
      final yesterday = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 1));
      expect(api.queries[Endpoints.dailySummary]!['date'], isoDate(yesterday));
      expect(tester.widget<IconButton>(find.ancestor(of: find.byTooltip('Ngày sau'), matching: find.byType(IconButton)).first).onPressed, isNotNull);
    });

    testWidgets('lỗi tải hiện popup và nút thử lại', (tester) async {
      api = _Api()..error = ApiException('Máy chủ lỗi', code: 9999, statusCode: 500);
      await tester.pumpWidget(Provider<DiaryRepository>.value(
        value: DiaryRepository(api),
        child: const MaterialApp(home: DiaryScreen()),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Không tải được nhật ký'), findsOneWidget);
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();
      expect(find.text('Thử lại'), findsOneWidget);
    });
  });
}
