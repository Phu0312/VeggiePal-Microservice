import 'package:dio/dio.dart' show ProgressCallback;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:VeggiePal/core/constants/endpoints.dart';
import 'package:VeggiePal/core/network/api_client.dart';
import 'package:VeggiePal/core/storage/session_store.dart';
import 'package:VeggiePal/features/auth/data/auth_models.dart';
import 'package:VeggiePal/features/auth/data/auth_repository.dart';
import 'package:VeggiePal/features/auth/presentation/auth_controller.dart';
import 'package:VeggiePal/features/home/data/recommendation_controller.dart';
import 'package:VeggiePal/features/home/data/recommendation_repository.dart';
import 'package:VeggiePal/features/home/presentation/home_highlights.dart';
import 'package:VeggiePal/features/recipe/data/recipe_repository.dart';

/// ApiClient giả: trả kết quả theo đường dẫn (hàm, để đổi theo kịch bản), không đụng tới mạng.
class FakeApi extends ApiClient {
  final calls = <String>[];
  final queries = <String, Map<String, dynamic>?>{};
  final results = <String, Object? Function()>{};

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    calls.add(path);
    queries[path] = query;
    return results[path]?.call();
  }

  @override
  Future<dynamic> post(String path,
          {Object? body, Map<String, String>? headers, ProgressCallback? onSendProgress, Duration? receiveTimeout}) async =>
      null;
}

Map<String, dynamic> _recipe(int id, String title) => {
      'id': id,
      'userId': 9,
      'title': title,
      'imageUrl': 'https://img/$id.jpg',
      'servings': 2,
      'prepTime': 10,
      'cookTime': 20,
      'status': 'PUBLISHED',
      'ingredients': [
        {
          'ingredientId': 1,
          'ingredientName': 'Đậu hũ',
          'quantity': 200,
          'unit': 'GRAM',
          'caloriesPer100g': 100,
          'proteinPer100g': 10,
          'carbsPer100g': 4,
          'fatPer100g': 5,
          'vegan': true,
          'allergen': false,
        }
      ],
      'steps': [
        {'stepNumber': 1, 'instruction': 'Chiên'}
      ],
    };

Map<String, dynamic> _rec(String type, int id, String title, String reason) => {
      'type': type,
      'id': id,
      'reason': reason,
      'content': type == 'RECIPE'
          ? _recipe(id, title)
          : {'id': id, 'title': title, 'thumbnailUrl': 'https://img/b$id.jpg', 'authorId': 4, 'viewCount': 3},
    };

void main() {
  setUp(() => dotenv.loadFromString(envString: 'APP=test'));

  group('Recommendation', () {
    test('công thức lấy ảnh từ imageUrl, bài viết từ thumbnailUrl; chuyển được về model gốc', () {
      final r = Recommendation.fromJson(_rec('RECIPE', 5, 'Đậu hũ sốt cà', 'Hợp khẩu vị'));
      expect(r.isRecipe, isTrue);
      expect(r.typeLabel, 'Công thức');
      expect(r.imageUrl, 'https://img/5.jpg');
      expect(r.toRecipe().servings, 2);
      expect(r.toRecipe().id, 5);

      final b = Recommendation.fromJson(_rec('BLOG', 8, 'Mẹo nấu chay', 'Giàu đạm'));
      expect(b.isBlog, isTrue);
      expect(b.typeLabel, 'Bài viết');
      expect(b.imageUrl, 'https://img/b8.jpg');
      expect(b.toBlog().id, 8);
      expect(b.toBlog().title, 'Mẹo nấu chay');
    });

    test('repository bỏ các gợi ý không có tên và gửi limit / interest', () async {
      final api = FakeApi()
        ..results[Endpoints.aiRecommendations] = () => [
              _rec('RECIPE', 1, 'Món A', 'x'),
              {'type': 'BLOG', 'id': 2, 'reason': 'y', 'content': {'id': 2}}, // thiếu tên
            ];
      api.token = 't';
      final list = await RecommendationRepository(api).recommend(interest: ' đạm ', limit: 4);
      expect(list.map((e) => e.id), [1]);
      expect(api.queries[Endpoints.aiRecommendations], {'interest': 'đạm', 'limit': 4});
    });
  });

  group('RecommendationController', () {
    late FakeApi api;
    late DateTime now;
    late RecommendationController ctrl;

    setUp(() {
      api = FakeApi()..results[Endpoints.aiRecommendations] = () => [_rec('RECIPE', 1, 'Món A', 'x')];
      api.token = 't';
      now = DateTime(2026, 10, 29, 9);
      ctrl = RecommendationController(RecommendationRepository(api), clock: () => now);
    });

    int calls() => api.calls.where((c) => c == Endpoints.aiRecommendations).length;

    test('chưa đăng nhập thì không gọi AI', () async {
      await ctrl.ensureLoaded();
      expect(calls(), 0);
    });

    test('dùng lại kết quả còn mới (5 phút), gọi lại khi đã cũ, refresh luôn lấy mới', () async {
      ctrl.bindUser(1);
      await ctrl.ensureLoaded();
      await ctrl.ensureLoaded();
      expect(calls(), 1);
      expect(ctrl.items.single.title, 'Món A');

      now = now.add(const Duration(minutes: 4));
      await ctrl.ensureLoaded();
      expect(calls(), 1);

      now = now.add(const Duration(minutes: 2));
      await ctrl.ensureLoaded();
      expect(calls(), 2);

      await ctrl.refresh();
      expect(calls(), 3);
    });

    test('lỗi: giữ thông báo, không tự gọi lại cho tới khi bấm Thử lại', () async {
      api.results[Endpoints.aiRecommendations] = () => throw ApiException('Hết hạn mức', code: 6003, statusCode: 429);
      ctrl.bindUser(1);
      await ctrl.ensureLoaded();
      expect(ctrl.error, isNotNull);
      expect(ctrl.items, isEmpty);

      await ctrl.ensureLoaded(); // lỗi vừa xảy ra: không gọi lại ngay (tránh gọi liên tục mỗi lần dựng màn hình)
      expect(calls(), 1);
      await ctrl.refresh();
      expect(calls(), 2);
    });

    test('đăng xuất xoá gợi ý của tài khoản trước', () async {
      ctrl.bindUser(1);
      await ctrl.refresh();
      expect(ctrl.items, isNotEmpty);
      ctrl.bindUser(null);
      expect(ctrl.items, isEmpty);
      expect(ctrl.hasLoaded, isFalse);
    });
  });

  group('HomeHighlights', () {
    Future<FakeApi> boot(WidgetTester tester, {required bool loggedIn, List<Object?>? recs}) async {
      final api = FakeApi()
        ..results[Endpoints.recipes] = (() => {
              'content': [_recipe(1, 'Đậu hũ sốt cà'), _recipe(2, 'Canh nấm')],
              'page': 0,
              'totalPages': 1,
              'totalElements': 2,
            })
        ..results[Endpoints.aiRecommendations] =
            (() => recs ?? [_rec('RECIPE', 1, 'Đậu hũ sốt cà', 'Giàu đạm, hợp người tập gym'), _rec('BLOG', 9, 'Mẹo nấu chay', 'Dễ làm')]);
      if (loggedIn) api.token = 't';
      final auth = AuthController(api, AuthRepository(api), SessionStore(),
          initial: loggedIn
              ? const AuthSession('t', AuthUser(id: 3, email: 'a@b.c', fullName: 'An', role: UserRole.user))
              : null);
      final recCtrl = RecommendationController(RecommendationRepository(api))..bindUser(loggedIn ? 3 : null);
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<RecipeRepository>.value(value: RecipeRepository(api)),
          ChangeNotifierProvider<AuthController>.value(value: auth),
          ChangeNotifierProvider<RecommendationController>.value(value: recCtrl),
        ],
        child: const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: HomeHighlights()))),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      return api;
    }

    testWidgets('khách thấy công thức mới và lời mời đăng nhập, không gọi AI', (tester) async {
      final api = await boot(tester, loggedIn: false);
      expect(find.text('Món chay mới'), findsOneWidget);
      expect(find.text('Đậu hũ sốt cà'), findsOneWidget);
      expect(find.text('Canh nấm'), findsOneWidget);
      expect(find.textContaining('Đăng nhập để AI chọn'), findsOneWidget);
      expect(api.calls.contains(Endpoints.aiRecommendations), isFalse);
      expect(api.queries[Endpoints.recipes], {'page': 0, 'size': 6});
    });

    testWidgets('thành viên thấy gợi ý của AI kèm lý do và loại nội dung', (tester) async {
      final api = await boot(tester, loggedIn: true);
      expect(find.text('Gợi ý dành riêng cho bạn'), findsOneWidget);
      expect(find.text('Công thức'), findsOneWidget); // nhãn loại trên thẻ gợi ý
      expect(find.text('Bài viết'), findsOneWidget);
      expect(find.text('Giàu đạm, hợp người tập gym'), findsOneWidget);
      expect(find.text('Mẹo nấu chay'), findsOneWidget);
      expect(api.calls.where((c) => c == Endpoints.aiRecommendations).length, 1);
    });

    testWidgets('AI không có gợi ý nào thì báo trạng thái rỗng', (tester) async {
      await boot(tester, loggedIn: true, recs: const []);
      expect(find.textContaining('Chưa có gợi ý phù hợp'), findsOneWidget);
    });
  });
}
