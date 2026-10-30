import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:VeggiePal/core/constants/endpoints.dart';
import 'package:VeggiePal/core/network/api_client.dart';
import 'package:VeggiePal/core/storage/session_store.dart';
import 'package:VeggiePal/features/auth/data/auth_repository.dart';
import 'package:VeggiePal/features/auth/presentation/auth_controller.dart';
import 'package:VeggiePal/features/payment/data/payment_models.dart';
import 'package:VeggiePal/features/payment/data/payment_repository.dart';
import 'package:VeggiePal/features/payment/data/subscription_controller.dart';
import 'package:VeggiePal/features/payment/presentation/quota_meter.dart';
import 'package:VeggiePal/features/recipe/data/recipe_models.dart';
import 'package:VeggiePal/features/recipe/data/recipe_repository.dart';
import 'package:VeggiePal/features/recipe/presentation/recipes_tab.dart';

/// ApiClient giả: ghi lại lời gọi và query, trả kết quả theo đường dẫn.
class _Api extends ApiClient {
  final calls = <String>[];
  final queries = <String, Map<String, dynamic>?>{};
  final bodies = <String, Object?>{};
  final results = <String, Object?>{};

  Object? _hit(String method, String path, [Map<String, dynamic>? q]) {
    calls.add('$method $path');
    queries[path] = q;
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
  Future<dynamic> delete(String path) async => _hit('DELETE', path);
}

Map<String, dynamic> _quota({int chatUsed = 17, int videoLimit = 0}) => {
      'planCode': 'PLUS',
      'mealPlan': {
        'feature': 'MEAL_PLAN',
        'period': 'MONTHLY',
        'limit': 8,
        'used': 3,
        'remaining': 5,
        'resetsAt': '2026-11-01'
      },
      'chat': {
        'feature': 'CHAT',
        'period': 'DAILY',
        'limit': 20,
        'used': chatUsed,
        'remaining': 20 - chatUsed,
        'resetsAt': '2026-10-31'
      },
      'video': {
        'feature': 'VIDEO',
        'period': 'MONTHLY',
        'limit': videoLimit,
        'used': 0,
        'remaining': videoLimit,
        'resetsAt': '2026-11-01'
      },
    };

Map<String, dynamic> _recipe(int id, {int likes = 0}) => {
      'id': id,
      'userId': 3,
      'title': 'Đậu hũ sốt cà $id',
      'servings': 2,
      'status': 'PUBLISHED',
      'likeCount': likes,
      'ingredients': [],
      'steps': [],
    };

/// Trả `/recipes` theo số trang trong query (mỗi trang một danh sách, tổng cộng [pages].length trang).
class _PagedApi extends _Api {
  final Map<int, List<Map<String, dynamic>>> pages;
  _PagedApi(this.pages);

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    super._hit('GET', path, query);
    final n = (query?['page'] as int?) ?? 0;
    return {'content': pages[n] ?? const [], 'page': n, 'totalPages': pages.length};
  }
}

/// PaymentRepository giả: gói cố định, hạn mức lấy từ biến, đếm số lần gọi.
class _PayRepo extends PaymentRepository {
  _PayRepo(super.api);
  Object? quotaError;
  int quotaCalls = 0;
  Map<String, dynamic> quotaJson = _quota();

  @override
  Future<Subscription> mySubscription() async => Subscription.fromJson(
      {'planCode': 'PLUS', 'chatPerDay': 20, 'mealPlansPerMonth': 8, 'videosPerMonth': 0});

  @override
  Future<QuotaOverview> myQuotas() async {
    quotaCalls++;
    final e = quotaError;
    if (e != null) throw e;
    return QuotaOverview.fromJson(quotaJson);
  }
}

void main() {
  setUp(() => dotenv.loadFromString(envString: 'APP=test'));

  group('hạn mức (quota)', () {
    test('FeatureQuota: nhãn theo kỳ, hết lượt và gói chưa có lượt', () {
      final q = QuotaOverview.fromJson(_quota(chatUsed: 20));
      expect(q.planCode, 'PLUS');
      expect(q.mealPlan.label, 'Còn 5/8 lượt tháng này');
      expect(q.chat.label, 'Còn 0/20 lượt hôm nay');
      expect(q.chat.exhausted, isTrue);
      expect(q.mealPlan.exhausted, isFalse);
      expect(q.video.label, 'Gói hiện tại chưa có lượt');
      expect(q.video.usedRatio, 1);
      expect(q.mealPlan.usedRatio, 3 / 8);
      expect(q.mealPlan.resetsAt, DateTime(2026, 11, 1));
    });

    test('PaymentRepository.myQuotas gọi /ai/quotas/me', () async {
      final api = _Api()
        ..token = 't'
        ..results[Endpoints.myQuotas] = _quota();
      final q = await PaymentRepository(api).myQuotas();
      expect(api.calls, ['GET /ai/quotas/me']);
      expect(q.chat.limit, 20);
    });

    test('SubscriptionController tải hạn mức sau gói; lỗi hạn mức không làm mất gói', () async {
      final repo = _PayRepo(_Api());
      final c = SubscriptionController(repo)..bindUser(7);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(c.subscription?.planCode, 'PLUS');
      expect(c.quota?.chat.remaining, 3);

      repo.quotaError = ApiException('mạng', isNetwork: true);
      repo.quotaJson = _quota(chatUsed: 20);
      await c.refresh();
      expect(c.subscription, isNotNull);
      expect(c.error, isNull);
      expect(c.quota?.chat.remaining, 3); // giữ giá trị cũ khi tải lại lỗi

      repo.quotaError = null;
      await c.refreshQuota();
      expect(c.quota?.chat.remaining, 0);

      c.bindUser(null);
      expect(c.quota, isNull);
    });

    testWidgets('QuotaMeter hiện nhãn và ngày đặt lại', (tester) async {
      final q = QuotaOverview.fromJson(_quota());
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: QuotaMeter(title: 'Hỏi trợ lý AI', quota: q.chat))));
      expect(find.text('Hỏi trợ lý AI'), findsOneWidget);
      expect(find.text('Còn 3/20 lượt hôm nay'), findsOneWidget);
      expect(find.text('Đặt lại ngày 31/10/2026'), findsOneWidget);
    });
  });

  group('công thức: thích, phổ biến, ảnh', () {
    test('Recipe đọc likeCount và withLikeCount giữ nguyên các trường khác', () {
      final r = Recipe.fromJson(_recipe(5, likes: 7));
      expect(r.likeCount, 7);
      final r2 = r.withLikeCount(8);
      expect(r2.likeCount, 8);
      expect(r2.title, r.title);
      expect(Recipe.fromJson({'id': 1, 'title': 'x'}).likeCount, 0);
    });

    test('popular gọi /recipes/popular có phân trang', () async {
      final api = _Api()
        ..results[Endpoints.recipesPopular] = {
          'content': [_recipe(1, likes: 9)],
          'page': 1,
          'totalPages': 3,
          'totalElements': 25
        };
      final p = await RecipeRepository(api).popular(page: 1);
      expect(api.queries[Endpoints.recipesPopular], {'page': 1, 'size': 10});
      expect(p.items.single.likeCount, 9);
      expect(p.hasMore, isTrue);
    });

    test('myLikes gửi danh sách id dạng 1,2 và đọc kết quả theo id', () async {
      final api = _Api()
        ..token = 't'
        ..results[Endpoints.myRecipeLikes] = [
          {'recipeId': 1, 'liked': true, 'likeCount': 4},
          {'recipeId': 2, 'liked': false, 'likeCount': 0},
        ];
      final m = await RecipeRepository(api).myLikes([1, 2]);
      expect(api.queries[Endpoints.myRecipeLikes], {'recipeIds': '1,2'});
      expect(m[1]!.liked, isTrue);
      expect(m[2]!.liked, isFalse);
      expect(await RecipeRepository(api).myLikes([]), isEmpty);
      expect(api.calls.length, 1); // danh sách rỗng không gọi mạng
    });

    test('setLike: POST khi thích, DELETE khi bỏ thích, trả tổng lượt mới', () async {
      final api = _Api()
        ..token = 't'
        ..results[Endpoints.recipeLike(3)] = {'recipeId': 3, 'liked': true, 'likeCount': 5};
      final repo = RecipeRepository(api);
      final a = await repo.setLike(3, true);
      expect((a.liked, a.likeCount), (true, 5));
      await repo.setLike(3, false);
      expect(api.calls, ['POST /recipes/3/like', 'DELETE /recipes/3/like']);
    });

    test('thích khi chưa đăng nhập bị chặn trước khi gọi mạng', () async {
      final api = _Api();
      await expectLater(RecipeRepository(api).setLike(3, true), throwsA(isA<ApiException>()));
      expect(api.calls, isEmpty);
    });

    test('uploadImage kiểm tra loại và dung lượng ảnh rồi trả imageUrl', () async {
      final api = _Api()
        ..token = 't'
        ..results[Endpoints.recipeImages] = {'imageUrl': 'https://res.cloudinary.com/x/a.jpg'};
      final repo = RecipeRepository(api);

      await expectLater(repo.uploadImage(Uint8List.fromList([1, 2, 3, 4, 5])),
          throwsA(isA<ApiException>().having((e) => e.message, 'm', contains('JPEG'))));
      final big = Uint8List(maxRecipeImageBytes + 1)..setAll(0, [0xFF, 0xD8, 0xFF, 0xE0]);
      await expectLater(repo.uploadImage(big),
          throwsA(isA<ApiException>().having((e) => e.message, 'm', contains('5MB'))));
      expect(api.calls, isEmpty);

      final jpeg = Uint8List(64)..setAll(0, [0xFF, 0xD8, 0xFF, 0xE0]);
      expect(await repo.uploadImage(jpeg), 'https://res.cloudinary.com/x/a.jpg');
      expect(api.bodies[Endpoints.recipeImages], isA<FormData>());
    });

    testWidgets('RecipesTab: chip "Phổ biến" dùng /recipes/popular, tìm từ khoá quay về mới nhất', (tester) async {
      final api = _Api()
        ..results[Endpoints.recipes] = {'content': [_recipe(1)], 'page': 0, 'totalPages': 1}
        ..results[Endpoints.recipesPopular] = {'content': [_recipe(2, likes: 12)], 'page': 0, 'totalPages': 1};
      final auth = AuthController(api, AuthRepository(api), SessionStore());
      await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<RecipeRepository>.value(value: RecipeRepository(api)),
          ChangeNotifierProvider<AuthController>.value(value: auth),
        ],
        child: const MaterialApp(home: Scaffold(body: RecipesTab())),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Đậu hũ sốt cà 1'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Phổ biến'));
      await tester.pumpAndSettle();
      expect(api.calls.last, 'GET /recipes/popular');
      expect(find.text('Đậu hũ sốt cà 2'), findsOneWidget);
      expect(find.textContaining('12 lượt thích'), findsOneWidget);

      await tester.enterText(find.byType(SearchBar), 'cà');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(api.calls.last, 'GET /recipes');
      expect(api.queries[Endpoints.recipes]?['keyword'], 'cà');
      expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Phổ biến')).onSelected, isNull);
    });

    testWidgets('RecipesTab: chip "Không dị ứng" bỏ công thức có nguyên liệu dễ gây dị ứng, đọc thêm trang cho đủ món', (tester) async {
      Map<String, dynamic> withAllergen(int id) => {
            ..._recipe(id),
            'ingredients': [
              {'ingredientId': 1, 'ingredientName': 'Đậu phộng', 'quantity': 10, 'unit': 'GRAM', 'allergen': true}
            ],
          };
      // Trang 0 chỉ có món dị ứng và 1 món ổn; trang 1 có thêm một món ổn.
      final api = _PagedApi({
        0: [withAllergen(1), _recipe(2)],
        1: [_recipe(3)],
      });
      final auth = AuthController(api, AuthRepository(api), SessionStore());
      await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<RecipeRepository>.value(value: RecipeRepository(api)),
          ChangeNotifierProvider<AuthController>.value(value: auth),
        ],
        child: const MaterialApp(home: Scaffold(body: RecipesTab())),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Đậu hũ sốt cà 1'), findsOneWidget);
      expect(find.text('Đậu hũ sốt cà 2'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilterChip, 'Không dị ứng'));
      await tester.pumpAndSettle();
      expect(find.text('Đậu hũ sốt cà 1'), findsNothing);
      expect(find.text('Đậu hũ sốt cà 2'), findsOneWidget);
      expect(find.text('Đậu hũ sốt cà 3'), findsOneWidget); // trang đầu chưa đủ món nên đọc tiếp trang sau
      expect(api.queries[Endpoints.recipes]?['page'], 1);

      await tester.tap(find.widgetWithText(FilterChip, 'Không dị ứng'));
      await tester.pumpAndSettle();
      expect(find.text('Đậu hũ sốt cà 1'), findsOneWidget); // bỏ lọc: hiện lại đủ
    });
  });
}
