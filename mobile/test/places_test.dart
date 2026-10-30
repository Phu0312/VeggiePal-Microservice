import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:VeggiePal/core/constants/endpoints.dart';
import 'package:VeggiePal/core/network/api_client.dart';
import 'package:VeggiePal/features/places/data/places_models.dart';
import 'package:VeggiePal/features/places/data/places_repository.dart';
import 'package:VeggiePal/features/places/data/user_location.dart';
import 'package:VeggiePal/features/places/presentation/places_map.dart';
import 'package:VeggiePal/features/places/presentation/places_screen.dart';
import 'support/blank_tiles.dart';
import 'support/filter_dropdown.dart';

Map<String, dynamic> _json(int id, String name,
        {String address = '1 Lê Lợi, Quận 1', double km = 1.2, double? rating = 4.5, bool vegan = true, String? phone = '028 7309 3899'}) =>
    {
      'id': id,
      'name': name,
      'address': address,
      'latitude': 10.77 + id / 1000,
      'longitude': 106.69 + id / 1000,
      'phoneNumber': phone,
      'rating': rating,
      'veganOnly': vegan,
      'imageUrl': null,
      'distanceKm': km,
    };

/// ApiClient giả: trả danh sách quán và ghi lại tham số của từng lần tìm.
class FakeApi extends ApiClient {
  final queries = <Map<String, dynamic>>[];
  var places = <Map<String, dynamic>>[];
  ApiException? error;

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    expect(path, Endpoints.restaurantsNearby);
    queries.add(Map.of(query!));
    final e = error;
    if (e != null) throw e;
    return places;
  }
}

/// Nguồn vị trí giả với kịch bản quyền / dịch vụ / toạ độ tuỳ ý.
class FakeLocation implements LocationSource {
  LocationPermission current = LocationPermission.denied;
  LocationPermission afterRequest = LocationPermission.whileInUse;
  bool enabled = true;
  LatLngPair position = (lat: 21.03, lng: 105.85); // Hà Nội
  Object? positionError;
  var requested = 0;
  var openedSettings = 0;

  @override
  Future<LocationPermission> permission() async => current;

  @override
  Future<LocationPermission> requestPermission() async {
    requested++;
    current = afterRequest;
    return current;
  }

  @override
  Future<bool> serviceEnabled() async => enabled;

  @override
  Future<LatLngPair> currentPosition() async {
    final e = positionError;
    if (e != null) throw e;
    return position;
  }

  @override
  Future<bool> openAppSettings() async {
    openedSettings++;
    return true;
  }

  @override
  Future<bool> openLocationSettings() async {
    openedSettings++;
    return true;
  }
}

void main() {
  setUp(() => dotenv.loadFromString(envString: 'APP=test'));

  group('định dạng và lọc', () {
    test('formatDistance / formatRating', () {
      expect(formatDistance(0.53), '530 m');
      expect(formatDistance(1.14), '1.1 km');
      expect(formatDistance(2), '2 km');
      expect(formatDistance(-1), '');
      expect(formatRating(4.7), '4.7');
      expect(formatRating(null), '-');
    });

    test('normalizeText bỏ dấu tiếng Việt, kể cả đ', () {
      expect(normalizeText('  Phở Chay Đồng Khởi '), 'pho chay dong khoi');
      expect(normalizeText('Bún riêu — Quận 1'), 'bun rieu — quan 1');
    });

    final places = [
      Place.fromJson(_json(1, 'Phương Mai Chay Quán', address: 'Võ Thị Sáu, Quận 1', km: 2, rating: 4.9)),
      Place.fromJson(_json(2, 'Cơm Chay Hoa Sen', address: 'Nguyễn Trãi, Quận 5', km: 0.5, rating: 4.2)),
      Place.fromJson(_json(3, 'Lẩu Nấm Chay', address: 'Phạm Ngũ Lão', km: 1, rating: null)),
    ];

    test('filterPlaces tìm trong tên và địa chỉ, không phân biệt dấu', () {
      expect(filterPlaces(places, 'pho').length, 0);
      expect(filterPlaces(places, 'com chay').map((p) => p.id), [2]);
      expect(filterPlaces(places, 'quan 1').map((p) => p.id), [1]);
      expect(filterPlaces(places, 'LAU nam').map((p) => p.id), [3]);
      expect(filterPlaces(places, '  '), places);
    });

    test('sortPlaces: đánh giá giảm dần, thiếu rating xuống cuối; "gần nhất" giữ thứ tự', () {
      expect(sortPlaces(places, PlaceSort.rating).map((p) => p.id), [1, 2, 3]);
      expect(sortPlaces(places, PlaceSort.nearest).map((p) => p.id), [1, 2, 3]);
      final tie = [
        Place.fromJson(_json(4, 'A', km: 3, rating: 4.0)),
        Place.fromJson(_json(5, 'B', km: 1, rating: 4.0)),
      ];
      expect(sortPlaces(tie, PlaceSort.rating).map((p) => p.id), [5, 4]); // bằng nhau thì gần hơn trước
      expect(identical(sortPlaces(places, PlaceSort.nearest), places), isFalse); // không đổi danh sách gốc
    });

    test('link chỉ đường, số điện thoại và mức zoom', () {
      final p = Place.fromJson(_json(7, 'Quán'));
      expect(directionsUri(p).toString(), 'https://www.google.com/maps/dir/?api=1&destination=10.777,106.697');
      expect(telUri('028 7309 3899').toString(), 'tel:02873093899');
      expect(telUri('+84 90-123'), Uri.parse('tel:+8490123'));
      expect(telUri(' '), isNull);
      expect(zoomForRadius(1), 14.8);
      expect(zoomForRadius(10), 11.5);
      expect(zoomForRadius(0), 12);
    });
  });

  test('PlacesRepository gửi toạ độ, bán kính và cờ thuần chay', () async {
    final api = FakeApi()..places = [_json(1, 'Chay Quán')];
    final r = await PlacesRepository(api).nearby(lat: 10.7, lng: 106.6, radiusKm: 3, veganOnly: true);
    expect(api.queries.single, {'lat': 10.7, 'lng': 106.6, 'radiusKm': 3, 'veganOnly': true});
    expect(r.single.name, 'Chay Quán');
  });

  group('UserLocation', () {
    test('mặc định là tâm TP.HCM và không tự xin quyền', () async {
      final src = FakeLocation();
      final u = UserLocation(src);
      expect(u.isDefault, isTrue);
      expect(u.location, (lat: defaultLat, lng: defaultLng));
      await u.restoreIfGranted();
      expect(src.requested, 0);
      expect(u.isDefault, isTrue);
    });

    test('quyền đã cấp từ trước thì restoreIfGranted lấy vị trí không hỏi lại', () async {
      final src = FakeLocation()..current = LocationPermission.whileInUse;
      final u = UserLocation(src);
      await u.restoreIfGranted();
      expect(src.requested, 0);
      expect(u.status, LocationStatus.granted);
      expect(u.location, (lat: 21.03, lng: 105.85));
    });

    test('request: xin quyền rồi lấy vị trí thật', () async {
      final src = FakeLocation();
      final u = UserLocation(src);
      await u.request();
      expect(src.requested, 1);
      expect(u.hasRealPosition, isTrue);
      u.useDefault();
      expect(u.isDefault, isTrue);
    });

    test('từ chối, từ chối vĩnh viễn, tắt định vị và lỗi thiết bị', () async {
      final src = FakeLocation()..afterRequest = LocationPermission.denied;
      final u = UserLocation(src);
      await u.request();
      expect(u.status, LocationStatus.denied);
      expect(u.isDefault, isTrue);

      src
        ..current = LocationPermission.deniedForever
        ..afterRequest = LocationPermission.deniedForever;
      await u.request();
      expect(u.status, LocationStatus.deniedForever);
      await u.openSettings();
      expect(src.openedSettings, 1);

      src
        ..current = LocationPermission.whileInUse
        ..enabled = false;
      await u.request();
      expect(u.status, LocationStatus.serviceOff);

      src
        ..enabled = true
        ..positionError = Exception('timeout');
      await u.request();
      expect(u.status, LocationStatus.unavailable);
    });

    test('lấy vị trí lỗi thì giữ vị trí thật trước đó', () async {
      final src = FakeLocation()..current = LocationPermission.whileInUse;
      final u = UserLocation(src);
      await u.request();
      src.positionError = Exception('lỗi');
      await u.request();
      expect(u.status, LocationStatus.unavailable);
      expect(u.location, (lat: 21.03, lng: 105.85));
    });
  });

  group('PlacesScreen', () {
    Future<(FakeApi, FakeLocation)> boot(WidgetTester tester, {FakeLocation? location}) async {
      final api = FakeApi()
        ..places = [
          _json(1, 'Phương Mai Chay Quán', address: 'Võ Thị Sáu, Quận 1', km: 0.53, rating: 4.9),
          _json(2, 'Cơm Chay Hoa Sen', address: 'Nguyễn Trãi, Quận 5', km: 2.4, rating: 4.2, vegan: false),
        ];
      final loc = location ?? FakeLocation();
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<PlacesRepository>.value(value: PlacesRepository(api)),
          Provider<LocationSource>.value(value: loc),
          Provider<MapTiles>.value(value: blankMapTiles()),
        ],
        child: const MaterialApp(home: Scaffold(body: PlacesScreen())),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      return (api, loc);
    }

    testWidgets('liệt kê quán gần nhất quanh tâm mặc định', (tester) async {
      final (api, _) = await boot(tester);
      expect(api.queries.first, {'lat': defaultLat, 'lng': defaultLng, 'radiusKm': 5, 'veganOnly': false});
      expect(find.text('Phương Mai Chay Quán'), findsOneWidget);
      expect(find.text('530 m', findRichText: true), findsNothing); // khoảng cách nằm cùng dòng với đánh giá
      expect(find.textContaining('530 m'), findsOneWidget);
      expect(find.text('Thuần chay 100%'), findsOneWidget);
      expect(find.text('Quán chay'), findsOneWidget); // quán còn lại không thuần chay
      expect(find.textContaining('Đang xem quanh trung tâm TP.HCM'), findsOneWidget);
    });

    testWidgets('gõ từ khoá không dấu lọc ngay trên danh sách, không gọi lại máy chủ', (tester) async {
      final (api, _) = await boot(tester);
      await tester.enterText(find.byType(SearchBar), 'com chay');
      await tester.pump();
      expect(find.text('Cơm Chay Hoa Sen'), findsOneWidget);
      expect(find.text('Phương Mai Chay Quán'), findsNothing);
      expect(api.queries.length, 1);
    });

    testWidgets('đổi bán kính và "chỉ thuần chay" thì tìm lại với tham số mới', (tester) async {
      final (api, _) = await boot(tester);
      await pickFilter(tester, '5 km', '10 km');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(api.queries.last['radiusKm'], 10);

      await pickFilter(tester, 'Mọi quán', 'Thuần chay');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(api.queries.last, {'lat': defaultLat, 'lng': defaultLng, 'radiusKm': 10, 'veganOnly': true});
    });

    testWidgets('"Vị trí của tôi" xin quyền rồi tìm quanh vị trí thật', (tester) async {
      final (api, loc) = await boot(tester);
      await tester.tap(find.text('Vị trí của tôi'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(loc.requested, 1);
      expect(api.queries.last['lat'], 21.03);
      expect(api.queries.last['lng'], 105.85);
      expect(find.textContaining('Đang tìm quanh vị trí của bạn'), findsOneWidget);
    });

    testWidgets('quyền đã cấp từ trước thì tự dùng vị trí, không hiện hộp thoại xin quyền', (tester) async {
      final loc = FakeLocation()..current = LocationPermission.whileInUse;
      final (api, _) = await boot(tester, location: loc);
      await tester.pump(const Duration(milliseconds: 100));
      expect(loc.requested, 0);
      expect(api.queries.last['lat'], 21.03);
    });

    testWidgets('quyền bị từ chối vĩnh viễn: gợi ý mở Cài đặt', (tester) async {
      final loc = FakeLocation()
        ..current = LocationPermission.deniedForever
        ..afterRequest = LocationPermission.deniedForever;
      await boot(tester, location: loc);
      await tester.tap(find.text('Vị trí của tôi'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('Quyền vị trí đang bị tắt'), findsOneWidget);
      await tester.tap(find.text('Mở Cài đặt'));
      expect(loc.openedSettings, 1);
    });

    testWidgets('bấm một quán mở chi tiết với nút Chỉ đường và Gọi', (tester) async {
      await boot(tester);
      await tester.tap(find.text('Phương Mai Chay Quán'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Chỉ đường'), findsOneWidget);
      expect(find.text('Gọi'), findsOneWidget);
      expect(find.text('028 7309 3899'), findsOneWidget);
      expect(find.text('Xem trên bản đồ'), findsOneWidget);
    });

    testWidgets('không có quán: gợi ý mở rộng bán kính', (tester) async {
      final api = FakeApi();
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<PlacesRepository>.value(value: PlacesRepository(api)),
          Provider<LocationSource>.value(value: FakeLocation()),
          Provider<MapTiles>.value(value: blankMapTiles()),
        ],
        child: const MaterialApp(home: Scaffold(body: PlacesScreen())),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Không có quán chay nào trong 5 km'), findsOneWidget);
      await tester.tap(find.text('Mở rộng bán kính'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(api.queries.last['radiusKm'], 10);
    });

    testWidgets('lỗi tải hiện popup và nút thử lại', (tester) async {
      final api = FakeApi()..error = ApiException('Toạ độ không hợp lệ.', code: 5001, statusCode: 400);
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<PlacesRepository>.value(value: PlacesRepository(api)),
          Provider<LocationSource>.value(value: FakeLocation()),
          Provider<MapTiles>.value(value: blankMapTiles()),
        ],
        child: const MaterialApp(home: Scaffold(body: PlacesScreen())),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Không tải được quán chay'), findsOneWidget);
      expect(find.text('Toạ độ không hợp lệ.'), findsOneWidget);
    });

    testWidgets('chuyển sang Bản đồ dựng được ghim và vòng bán kính', (tester) async {
      await boot(tester);
      await tester.tap(find.text('Bản đồ'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.byType(CircleLayer), findsOneWidget);
      expect(find.byType(MarkerLayer), findsOneWidget);
    });
  });
}
