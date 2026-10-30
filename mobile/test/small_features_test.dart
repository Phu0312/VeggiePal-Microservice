import 'package:dio/dio.dart' show ProgressCallback;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:VeggiePal/core/constants/endpoints.dart';
import 'package:VeggiePal/core/network/api_client.dart';
import 'package:VeggiePal/features/menu_planner/data/meal_plan_models.dart';
import 'package:VeggiePal/features/menu_planner/data/meal_plan_repository.dart';
import 'package:VeggiePal/features/menu_planner/presentation/plan_view.dart';
import 'package:VeggiePal/features/places/data/places_repository.dart';
import 'package:VeggiePal/features/places/data/user_location.dart';
import 'package:VeggiePal/features/places/presentation/places_map.dart';
import 'package:VeggiePal/features/places/presentation/places_screen.dart';
import 'package:VeggiePal/features/video/data/video_models.dart';
import 'package:VeggiePal/features/video/data/video_repository.dart';
import 'package:VeggiePal/features/video/presentation/video_nutrition_widgets.dart';
import 'support/blank_tiles.dart';

/// ApiClient giả: ghi lại đường dẫn, query, body và trả kết quả theo đường dẫn.
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
  Future<dynamic> put(String path, {Object? body}) async {
    bodies[path] = body;
    return _hit('PUT', path);
  }

  @override
  Future<dynamic> delete(String path) async => _hit('DELETE', path);
}

Map<String, dynamic> _place(int id, String name, double km) => {
      'id': id,
      'name': name,
      'address': '$id Lê Lợi, Quận 1',
      'latitude': 10.77,
      'longitude': 106.69,
      'rating': 4.5,
      'veganOnly': true,
      'distanceKm': km,
    };

class _Location implements LocationSource {
  @override
  Future<LocationPermission> permission() async => LocationPermission.denied;
  @override
  Future<LocationPermission> requestPermission() async => LocationPermission.denied;
  @override
  Future<bool> serviceEnabled() async => true;
  @override
  Future<LatLngPair> currentPosition() async => (lat: 10.77, lng: 106.69);
  @override
  Future<bool> openAppSettings() async => true;
  @override
  Future<bool> openLocationSettings() async => true;
}

void main() {
  setUp(() => dotenv.loadFromString(envString: 'APP=test'));

  group('video: vote và dinh dưỡng', () {
    test('Video đọc voteScore và nutrition; không có nutrition thì null', () {
      final v = Video.fromJson({
        'id': 5,
        'title': 'Phở chay',
        'sourceType': 'YOUTUBE',
        'videoUrl': 'u',
        'status': 'PUBLISHED',
        'voteScore': 7,
        'nutrition': {
          'servingLabel': '1 tô',
          'kcal': 320,
          'proteinG': 12.5,
          'carbsG': 40,
          'fatG': 8,
          'ingredients': [
            {'name': 'Đậu hũ', 'amount': '200g'},
            {'name': 'Hành lá'},
          ],
        },
      });
      expect(v.voteScore, 7);
      expect(v.nutrition!.kcal, 320);
      expect(v.nutrition!.protein, 12.5);
      expect(v.nutrition!.ingredients.map((i) => i.name), ['Đậu hũ', 'Hành lá']);
      expect(v.nutrition!.ingredients.last.amount, isNull);
      expect(Video.fromJson({'id': 1, 'sourceType': 'YOUTUBE', 'videoUrl': 'u', 'status': 'DRAFT'}).nutrition, isNull);
      expect(v.withNutrition(null).nutrition, isNull);
    });

    test('nguyên liệu nhập mỗi dòng "tên | lượng" được đọc và ghi lại đối xứng', () {
      final items = VideoNutrition.parseIngredientLines('Đậu hũ | 200g\r\n\r\n  Cà chua  \n | bỏ qua\nHành | ');
      expect(items.map((i) => (i.name, i.amount)), [('Đậu hũ', '200g'), ('Cà chua', null), ('Hành', null)]);
      expect(VideoNutrition.ingredientLines(items), 'Đậu hũ | 200g\nCà chua\nHành');
    });

    test('repository gọi đúng đường dẫn vote, bỏ vote, vote của tôi và sửa dinh dưỡng', () async {
      final api = _Api()
        ..results[Endpoints.videoVote(5)] = {'videoId': 5, 'myVote': 1, 'voteScore': 8}
        ..results[Endpoints.myVideoVotes] = [
          {'videoId': 5, 'myVote': -1},
        ]
        ..results[Endpoints.videoNutrition(5)] = {'kcal': 300, 'ingredients': []};
      final repo = VideoRepository(api);

      final v = await repo.vote(5, 1);
      expect((v.myVote, v.voteScore), (1, 8));
      expect(api.bodies[Endpoints.videoVote(5)], {'value': 1});
      await repo.removeVote(5);
      expect(api.calls.last, 'DELETE /videos/5/vote');

      final mine = await repo.myVotes([5, 6]);
      expect(api.queries[Endpoints.myVideoVotes], {'videoIds': [5, 6]});
      expect(mine.single.myVote, -1);
      expect(await repo.myVotes([]), isEmpty);

      final saved = await repo.updateNutrition(5, const VideoNutrition(kcal: 300, ingredients: [VideoIngredient('Đậu hũ', '200g')]));
      expect(saved!.kcal, 300);
      expect(api.bodies[Endpoints.videoNutrition(5)], containsPair('kcal', 300));
      expect((api.bodies[Endpoints.videoNutrition(5)] as Map)['ingredients'], [
        {'name': 'Đậu hũ', 'amount': '200g'}
      ]);
    });

    testWidgets('VideoNutritionCard: hiện macro và nguyên liệu; chưa khai báo thì chỉ chủ video thấy nút sửa', (tester) async {
      var edits = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(children: [
            VideoNutritionCard(
              nutrition: const VideoNutrition(
                  servingLabel: '1 tô', kcal: 320, protein: 12.5, ingredients: [VideoIngredient('Đậu hũ', '200g')]),
              onEdit: () => edits++,
            ),
            const VideoNutritionCard(nutrition: null),
          ]),
        ),
      ));
      expect(find.text('Dinh dưỡng • 1 tô'), findsOneWidget);
      expect(find.text('320'), findsOneWidget);
      expect(find.text('12.5'), findsOneWidget);
      expect(find.text('• Đậu hũ — 200g'), findsOneWidget);
      await tester.tap(find.byTooltip('Sửa dinh dưỡng'));
      expect(edits, 1);
      expect(find.text('Người đăng chưa khai báo dinh dưỡng cho video này.'), findsNothing); // thẻ thứ hai tự ẩn
    });

    testWidgets('sheet sửa dinh dưỡng: số âm bị chặn, hợp lệ thì PUT và trả kết quả', (tester) async {
      final api = _Api()..results[Endpoints.videoNutrition(5)] = {'servingLabel': '2 người', 'kcal': 450, 'ingredients': []};
      VideoNutrition? result;
      await tester.pumpWidget(Provider<VideoRepository>.value(
        value: VideoRepository(api),
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await showEditVideoNutrition(context, 5, null),
              child: const Text('mở'),
            ),
          ),
        ),
      ));
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.tap(find.text('mở'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Năng lượng'), '-3');
      await tester.tap(find.text('Lưu'));
      await tester.pump();
      expect(find.text('Nhập số từ 0 trở lên'), findsOneWidget);
      expect(api.bodies.containsKey(Endpoints.videoNutrition(5)), isFalse);

      await tester.enterText(find.widgetWithText(TextFormField, 'Năng lượng'), '450');
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(api.bodies[Endpoints.videoNutrition(5)], containsPair('kcal', 450));
      expect(result?.servingLabel, '2 người');
    });
  });

  group('quán chay: tìm trên toàn bộ', () {
    test('search gửi từ khoá cùng toạ độ và xếp gần nhất trước', () async {
      final api = _Api()
        ..results[Endpoints.restaurantsSearch] = [_place(1, 'Chay A', 4.2), _place(2, 'Chay B', 0.8), _place(3, 'Chay C', 12.5)];
      final places = await PlacesRepository(api).search(keyword: ' chay ', lat: 10.77, lng: 106.69, veganOnly: true);
      expect(api.queries[Endpoints.restaurantsSearch], {'keyword': 'chay', 'veganOnly': true, 'lat': 10.77, 'lng': 106.69});
      expect(places.map((p) => p.id), [2, 1, 3]);
    });

    testWidgets('Enter tìm trên toàn bộ quán và khoá bán kính; xoá tìm kiếm quay về quanh vị trí', (tester) async {
      final api = _Api()
        ..results[Endpoints.restaurantsNearby] = [_place(1, 'Quán gần', 0.5)]
        ..results[Endpoints.restaurantsSearch] = [_place(9, 'Quán xa Đà Lạt', 11.0)];
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<PlacesRepository>.value(value: PlacesRepository(api)),
          Provider<LocationSource>.value(value: _Location()),
          Provider<MapTiles>.value(value: blankMapTiles()),
        ],
        child: const MaterialApp(home: Scaffold(body: PlacesScreen())),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Quán gần'), findsOneWidget);

      await tester.enterText(find.byType(SearchBar), 'đà lạt');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(api.calls.last, 'GET /restaurants/search');
      expect(find.text('Quán xa Đà Lạt'), findsOneWidget);
      expect(find.text('Quán gần'), findsNothing);
      expect(find.textContaining('không giới hạn bán kính'), findsOneWidget);
      expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '3 km')).onSelected, isNull);

      await tester.tap(find.text('Xoá tìm kiếm'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(api.calls.last, 'GET /restaurants/nearby');
      expect(find.text('Quán gần'), findsOneWidget);
      expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '3 km')).onSelected, isNotNull);
    });
  });

  group('thực đơn: khôi phục phiên bản', () {
    test('restoreVersion gọi POST .../versions/{n}/restore và trả thực đơn hiện tại mới', () async {
      final api = _Api()
        ..token = 't'
        ..results[Endpoints.aiMealPlanRestore(4, 2)] = {
          'id': 4,
          'name': 'Tuần giảm cân',
          'goal': 'LOSE',
          'version': 5,
          'isFavorite': false,
          'plan': {'days': []},
        };
      final restored = await MealPlanRepository(api).restoreVersion(4, 2);
      expect(api.calls.single, 'POST /ai/meal-plans/4/versions/2/restore');
      expect((restored.id, restored.version), (4, 5));
      expect(restored.viewingVersion, isNull);
    });

    MealPlan plan({int? viewing}) => MealPlan(
        id: 4,
        name: 'Tuần giảm cân',
        goal: 'LOSE',
        goalType: 'LOSE',
        version: 5,
        isFavorite: false,
        createdAt: null,
        days: const [],
        viewingVersion: viewing);

    testWidgets('chỉ khi đang xem bản cũ mới có nút "Khôi phục phiên bản này"', (tester) async {
      var restores = 0;
      Widget view(MealPlan p, {VoidCallback? restore}) => MaterialApp(
            home: Scaffold(
              body: PlanView(
                plan: p,
                selectedDay: 'MONDAY',
                onSelectDay: (_) {},
                onMealTap: (_, _) {},
                onToggleFavorite: () {},
                onLeaveVersion: () {},
                onRestoreVersion: restore,
              ),
            ),
          );

      await tester.pumpWidget(view(plan()));
      expect(find.text('Khôi phục phiên bản này'), findsNothing);

      await tester.pumpWidget(view(plan(viewing: 2), restore: () => restores++));
      expect(find.text('Đang xem phiên bản 2 (chỉ đọc).'), findsOneWidget);
      await tester.tap(find.text('Khôi phục phiên bản này'));
      expect(restores, 1);
    });
  });
}
