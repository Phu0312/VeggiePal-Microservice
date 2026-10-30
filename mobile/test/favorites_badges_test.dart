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
import 'package:VeggiePal/features/profile/data/favorites_controller.dart';
import 'package:VeggiePal/features/profile/data/profile_models.dart';
import 'package:VeggiePal/features/profile/data/profile_repository.dart';
import 'package:VeggiePal/features/profile/presentation/badges_screen.dart';
import 'package:VeggiePal/features/profile/presentation/favorite_button.dart';
import 'package:VeggiePal/features/profile/presentation/favorites_screen.dart';

/// ApiClient giả: ghi lại lời gọi, trả kết quả theo đường dẫn, có thể ném lỗi ở lần ghi kế tiếp.
class _Api extends ApiClient {
  final calls = <String>[];
  final queries = <String, Map<String, dynamic>?>{};
  final bodies = <String, Object?>{};
  final results = <String, Object?>{};
  Object? writeError;

  Object? _hit(String method, String path, [Map<String, dynamic>? q]) {
    calls.add('$method $path');
    queries[path] = q;
    return results[path];
  }

  void _maybeFail() {
    final e = writeError;
    if (e != null) {
      writeError = null;
      throw e;
    }
  }

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async => _hit('GET', path, query);

  @override
  Future<dynamic> post(String path,
      {Object? body, Map<String, String>? headers, ProgressCallback? onSendProgress, Duration? receiveTimeout}) async {
    _maybeFail();
    bodies[path] = body;
    calls.add('POST $path');
    // Giả lập BE: trả lại mục vừa lưu.
    return body is Map ? {'id': 99, 'createdAt': '2026-10-30T08:00:00', ...body} : null;
  }

  @override
  Future<dynamic> delete(String path) async {
    _maybeFail();
    return _hit('DELETE', path);
  }
}

Map<String, dynamic> _fav(int id, String type, int targetId, String title) =>
    {'id': id, 'targetType': type, 'targetId': targetId, 'title': title, 'imageUrl': null, 'createdAt': '2026-10-29T08:00:00'};

final _favList = [
  _fav(1, 'RECIPE', 10, 'Đậu hũ sốt cà'),
  _fav(2, 'BLOG', 20, 'Ăn chay mỗi ngày'),
  _fav(3, 'RECIPE', 11, 'Canh nấm'),
  _fav(4, 'WIDGET', 1, 'Loại lạ'), // loại mà app chưa biết phải bị bỏ qua
];

const _user = AuthSession('t', AuthUser(id: 7, email: 'an@gmail.com', fullName: 'An', role: UserRole.user));

void main() {
  setUp(() => dotenv.loadFromString(envString: 'APP=test'));

  group('ProfileRepository: yêu thích và huy hiệu', () {
    test('favorites chỉ gửi type khi lọc và bỏ qua loại lạ', () async {
      final api = _Api()..results[Endpoints.myFavorites] = _favList;
      final repo = ProfileRepository(api);

      final all = await repo.favorites();
      expect(api.queries[Endpoints.myFavorites], isEmpty);
      expect(all.map((e) => e.targetId), [10, 20, 11]);
      expect(all.first.type, FavoriteType.recipe);

      await repo.favorites(type: FavoriteType.video);
      expect(api.queries[Endpoints.myFavorites], {'type': 'VIDEO'});
    });

    test('saveFavorite cắt tiêu đề quá dài và bỏ ảnh quá dài; removeFavorite dùng loại + mã trong đường dẫn', () async {
      final api = _Api();
      final repo = ProfileRepository(api);
      await repo.saveFavorite(FavoriteType.blog, 5, 'x' * 300, 'https://a/${'b' * 600}');
      final body = api.bodies[Endpoints.myFavorites] as Map;
      expect(body['targetType'], 'BLOG');
      expect(body['targetId'], 5);
      expect((body['title'] as String).length, 255);
      expect(body.containsKey('imageUrl'), isFalse);

      await repo.removeFavorite(FavoriteType.recipe, 10);
      expect(api.calls.last, 'DELETE /users/me/favorites/RECIPE/10');
    });

    test('badges đọc số đã đạt và từng huy hiệu', () async {
      final api = _Api()
        ..results[Endpoints.myBadges] = {
          'earnedCount': 2,
          'totalCount': 6,
          'badges': [
            {'code': 'GREEN_STARTER', 'title': 'Khởi Đầu', 'description': 'd', 'icon': 'sprout', 'earned': true, 'earnedAt': '2026-10-01T00:00:00'},
            {'code': 'AI_MASTER_CHEF', 'title': 'AI', 'description': 'd2', 'icon': 'sparkles', 'earned': false},
          ],
        };
      final c = await ProfileRepository(api).badges();
      expect((c.earnedCount, c.totalCount), (2, 6));
      expect(c.badges.first.earned, isTrue);
      expect(c.badges.first.earnedAt, isNotNull);
      expect(c.badges.last.earned, isFalse);
      expect(badgeIcon('sprout'), isNot(badgeIcon('khong-co')));
    });
  });

  group('FavoritesController', () {
    test('tải khi đăng nhập, thêm / bỏ mục và phân theo loại', () async {
      final api = _Api()..results[Endpoints.myFavorites] = _favList;
      final c = FavoritesController(ProfileRepository(api))..bindUser(7);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(c.loaded, isTrue);
      expect(c.ofType(FavoriteType.recipe).length, 2);
      expect(c.isFavorite(FavoriteType.blog, 20), isTrue);
      expect(c.isFavorite(FavoriteType.video, 20), isFalse);

      expect(await c.toggle(FavoriteType.video, 30, title: 'Video mới'), isNull);
      expect(c.isFavorite(FavoriteType.video, 30), isTrue);
      expect(c.items.first.targetId, 30); // mục mới lưu nằm đầu

      expect(await c.toggle(FavoriteType.video, 30, title: 'Video mới'), isNull);
      expect(c.isFavorite(FavoriteType.video, 30), isFalse);
      expect(api.calls.last, 'DELETE /users/me/favorites/VIDEO/30');
    });

    test('lỗi từ BE được trả về dạng thông báo và không đổi danh sách', () async {
      final api = _Api()..results[Endpoints.myFavorites] = _favList;
      final c = FavoritesController(ProfileRepository(api))..bindUser(7);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      api.writeError = ApiException('Không lưu được', code: 1031);
      final before = c.items.length;
      expect(await c.toggle(FavoriteType.blog, 77, title: 't'), isNotNull);
      expect(c.items.length, before);
    });

    test('đăng xuất thì xoá danh sách', () async {
      final api = _Api()..results[Endpoints.myFavorites] = _favList;
      final c = FavoritesController(ProfileRepository(api))..bindUser(7);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      c.bindUser(null);
      expect(c.items, isEmpty);
      expect(c.loaded, isFalse);
    });
  });

  group('màn hình', () {
    Future<(_Api, FavoritesController)> mount(WidgetTester tester, Widget child, {bool loggedIn = true}) async {
      final api = _Api()
        ..results[Endpoints.myFavorites] = _favList
        ..results[Endpoints.myBadges] = {
          'earnedCount': 1,
          'totalCount': 2,
          'badges': [
            {'code': 'GREEN_STARTER', 'title': 'Khởi Đầu Sống Xanh', 'description': 'Gia nhập cộng đồng', 'icon': 'sprout', 'earned': true, 'earnedAt': '2026-10-01T00:00:00'},
            {'code': 'AI_MASTER_CHEF', 'title': 'AI Master Chef', 'description': 'Tối ưu công thức', 'icon': 'sparkles', 'earned': false},
          ],
        };
      if (loggedIn) api.token = 't';
      final auth = AuthController(api, AuthRepository(api), SessionStore(), initial: loggedIn ? _user : null);
      final favorites = FavoritesController(ProfileRepository(api))..bindUser(loggedIn ? 7 : null);
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<ProfileRepository>.value(value: ProfileRepository(api)),
          ChangeNotifierProvider<AuthController>.value(value: auth),
          ChangeNotifierProvider<FavoritesController>.value(value: favorites),
        ],
        child: MaterialApp(home: child),
      ));
      await tester.pumpAndSettle();
      return (api, favorites);
    }

    testWidgets('Yêu thích: tab theo loại kèm số lượng, bỏ lưu một mục', (tester) async {
      final (api, favorites) = await mount(tester, const FavoritesScreen());
      expect(find.text('Công thức (2)'), findsOneWidget);
      expect(find.text('Bài viết (1)'), findsOneWidget);
      expect(find.text('Video (0)'), findsOneWidget);
      expect(find.text('Đậu hũ sốt cà'), findsOneWidget);
      expect(find.text('Canh nấm'), findsOneWidget);

      await tester.tap(find.byTooltip('Bỏ khỏi yêu thích').first);
      await tester.pumpAndSettle();
      expect(api.calls.last, 'DELETE /users/me/favorites/RECIPE/10');
      expect(favorites.isFavorite(FavoriteType.recipe, 10), isFalse);
      expect(find.text('Công thức (1)'), findsOneWidget);

      await tester.tap(find.text('Video (0)'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Chưa lưu video nào'), findsOneWidget);
    });

    testWidgets('Huy hiệu: số đã đạt, huy hiệu đạt có ngày, chưa đạt hiện điều kiện', (tester) async {
      await mount(tester, const BadgesScreen());
      expect(find.text('Đã đạt 1/2 huy hiệu'), findsOneWidget);
      expect(find.text('Khởi Đầu Sống Xanh'), findsOneWidget);
      expect(find.textContaining('Đạt ngày 01/10/2026'), findsOneWidget);
      expect(find.text('AI Master Chef'), findsOneWidget);
      expect(find.text('Tối ưu công thức'), findsOneWidget);
    });

    testWidgets('FavoriteButton: bấm lưu rồi bấm lại để bỏ lưu', (tester) async {
      final (api, favorites) = await mount(
          tester,
          const Scaffold(
              body: FavoriteButton(type: FavoriteType.recipe, targetId: 55, title: 'Phở chay')));
      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();
      expect(api.bodies[Endpoints.myFavorites], containsPair('targetId', 55));
      expect(favorites.isFavorite(FavoriteType.recipe, 55), isTrue);
      expect(find.byIcon(Icons.bookmark), findsOneWidget);

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();
      expect(api.calls.last, 'DELETE /users/me/favorites/RECIPE/55');
      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    });

    testWidgets('FavoriteButton: khách bấm thì mở màn đăng nhập, không gọi BE', (tester) async {
      final (api, _) = await mount(
          tester,
          const Scaffold(
              body: FavoriteButton(type: FavoriteType.recipe, targetId: 55, title: 'Phở chay')),
          loggedIn: false);
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();
      expect(api.calls.where((c) => c.startsWith('POST')), isEmpty);
      expect(find.text('Đăng nhập'), findsWidgets);
    });
  });
}
