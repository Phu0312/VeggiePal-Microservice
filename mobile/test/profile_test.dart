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
import 'package:VeggiePal/features/home/data/home_repository.dart';
import 'package:VeggiePal/features/menu_planner/data/health_sync.dart';
import 'package:VeggiePal/features/payment/data/payment_repository.dart';
import 'package:VeggiePal/features/payment/data/subscription_controller.dart';
import 'package:VeggiePal/features/profile/data/bmi_chart.dart';
import 'package:VeggiePal/features/profile/data/profile_models.dart';
import 'package:VeggiePal/features/profile/data/profile_overview.dart';
import 'package:VeggiePal/features/profile/data/profile_repository.dart';
import 'package:VeggiePal/features/profile/presentation/edit_profile_screen.dart';
import 'package:VeggiePal/features/profile/presentation/profile_screen.dart';
import 'package:VeggiePal/features/recipe/data/recipe_repository.dart';
import 'package:VeggiePal/features/video/data/video_repository.dart';

/// ApiClient giả: trả kết quả theo đường dẫn (hàm, để đổi theo kịch bản); lỗi theo đường dẫn nếu đặt.
class FakeApi extends ApiClient {
  final calls = <String>[];
  final queries = <String, Map<String, dynamic>?>{};
  final results = <String, Object? Function()>{};
  final errors = <String, ApiException>{};

  void on(String path, Object? Function() answer) => results[path] = answer;

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    calls.add(path);
    queries[path] = query;
    final e = errors[path];
    if (e != null) throw e;
    return results[path]?.call();
  }

  @override
  Future<dynamic> post(String path,
          {Object? body, Map<String, String>? headers, ProgressCallback? onSendProgress, Duration? receiveTimeout}) async =>
      null;
}

Map<String, dynamic> _record(int id, double weight, String at, {double height = 170}) => {
      'id': id,
      'heightCm': height,
      'weightKg': weight,
      'bmi': double.parse((weight / ((height / 100) * (height / 100))).toStringAsFixed(1)),
      'recordedAt': at,
    };

Map<String, dynamic> _profile({String? dob, String? gender, String? activity}) => {
      'id': 3,
      'email': 'an@gmail.com',
      'fullName': 'An',
      'role': 'USER',
      'status': 'ACTIVE',
      'dateOfBirth': dob,
      'gender': gender,
      'activityLevel': activity,
    };

Map<String, dynamic> _page(int total) =>
    {'content': <dynamic>[], 'page': 0, 'size': 1, 'totalElements': total, 'totalPages': total};

HealthRecord _hr(double weight, DateTime at) => HealthRecord.fromJson(_record(1, weight, at.toIso8601String()));

void main() {
  setUp(() => dotenv.loadFromString(envString: 'APP=test'));

  group('biểu đồ BMI', () {
    final t0 = DateTime(2026, 10, 1);
    final records = [_hr(70, t0), _hr(68, t0.add(const Duration(days: 10))), _hr(66, t0.add(const Duration(days: 30)))];

    test('cần ít nhất 2 bản ghi', () {
      expect(chartPoints([_hr(70, t0)], BmiMetric.weight), isNull);
      expect(trendOf([_hr(70, t0)], BmiMetric.weight), isNull);
      expect(chartPoints(const [], BmiMetric.bmi), isNull);
    });

    test('điểm cao nhất ở trên cùng, thấp nhất ở dưới cùng, trải đều từ trái sang phải', () {
      final p = chartPoints(records, BmiMetric.weight)!;
      expect(p.map((e) => e.fx), [0, 0.5, 1]);
      expect(p.first.fy, 0); // 70 kg là cao nhất
      expect(p.last.fy, 1); // 66 kg là thấp nhất
      expect(p[1].fy, closeTo(0.5, 1e-9));
      expect(p.last.isLast, isTrue);
      expect(p.first.isLast, isFalse);
    });

    test('mọi giá trị bằng nhau thì vẽ đường ngang giữa khung', () {
      final p = chartPoints([_hr(70, t0), _hr(70, t0.add(const Duration(days: 1)))], BmiMetric.weight)!;
      expect(p.map((e) => e.fy), [0.5, 0.5]);
    });

    test('xu hướng: giảm / tăng / ổn định và số ngày theo dõi', () {
      final t = trendOf(records, BmiMetric.weight)!;
      expect(t.diff, -4.0);
      expect(t.days, 30);
      expect(t.highlight, 'Chỉ số giảm 4.0 kg');
      expect(t.detail, 'sau 30 ngày theo dõi');
      expect(trendOf(records.reversed.toList(), BmiMetric.weight)!.highlight, 'Chỉ số tăng 4.0 kg');
      expect(trendOf([_hr(70, t0), _hr(70, t0)], BmiMetric.weight)!.highlight, 'Chỉ số duy trì ổn định');
      expect(trendOf(records, BmiMetric.bmi)!.unit, 'điểm');
    });

    test('oldestFirst sắp bản ghi từ cũ đến mới mà không đổi danh sách gốc', () {
      final newestFirst = records.reversed.toList();
      expect(oldestFirst(newestFirst).map((r) => r.weightKg), [70, 68, 66]);
      expect(newestFirst.first.weightKg, 66);
    });
  });

  group('CalorieProfileIssue', () {
    UserProfile p({String? dob, String? gender, String? activity}) =>
        UserProfile.fromJson(_profile(dob: dob, gender: gender, activity: activity));
    final today = DateTime(2026, 10, 29);

    test('thiếu cả ba trường', () {
      final i = CalorieProfileIssue.of(p(), today);
      expect(i.missing, ['dateOfBirth', 'gender', 'activityLevel']);
      expect(i.message, 'Bổ sung ngày sinh, giới tính, mức độ vận động để tính nhu cầu calo cho thực đơn.');
    });

    test('đủ thông tin và đủ 18 tuổi thì không có vấn đề', () {
      expect(CalorieProfileIssue.of(p(dob: '2000-05-01', gender: 'MALE', activity: 'LIGHT'), today).hasIssue, isFalse);
    });

    test('đủ 18 tuổi đúng ngày sinh nhật, chưa tới sinh nhật thì còn 17', () {
      expect(CalorieProfileIssue.of(p(dob: '2008-10-29', gender: 'MALE', activity: 'LIGHT'), today).underage, isFalse);
      expect(CalorieProfileIssue.of(p(dob: '2008-10-30', gender: 'MALE', activity: 'LIGHT'), today).underage, isTrue);
    });

    test('dưới 18 tuổi: báo riêng, không bảo bổ sung', () {
      final i = CalorieProfileIssue.of(p(dob: '2015-01-01', gender: 'FEMALE', activity: 'LIGHT'), today);
      expect(i.underage, isTrue);
      expect(i.message, contains('18 tuổi'));
    });
  });

  group('ProfileOverview', () {
    FakeApi newApi() {
      final api = FakeApi()
        ..on(Endpoints.me, () => _profile(dob: '1995-01-01', gender: 'FEMALE', activity: 'MODERATE'))
        ..on(Endpoints.myBlogs, () => {'content': <dynamic>[], 'page': 0, 'totalElements': 4, 'totalPages': 4})
        ..on(Endpoints.myRecipes, () => _page(2))
        ..on(Endpoints.myVideos, () => _page(1))
        ..on(Endpoints.myAllergies, () => [
              {'id': 1, 'code': 'SOY', 'name': 'Đậu nành', 'category': 'LEGUME'},
              {'id': 2, 'code': 'NUT', 'name': 'Hạt', 'category': 'NUT_SEED'},
            ])
        ..on(Endpoints.healthRecords, () => [
              _record(2, 66, '2026-10-20T08:00:00'),
              _record(1, 70, '2026-10-01T08:00:00'),
            ]);
      api.token = 't';
      return api;
    }

    ProfileOverview make(FakeApi api) =>
        ProfileOverview(ProfileRepository(api), HomeRepository(api), RecipeRepository(api), VideoRepository(api));

    test('tải đủ số liệu và lấy chỉ số mới nhất', () async {
      final api = newApi();
      final o = make(api)..bindUser(3);
      await o.refresh();
      expect((o.blogs, o.recipes, o.videos, o.allergies), (4, 2, 1, 2));
      expect(o.latestHealth!.weightKg, 66);
      expect(o.health.length, 2);
      expect(o.error, isNull);
      expect(o.calorieIssue!.hasIssue, isFalse);
      expect(api.queries[Endpoints.healthRecords], {'page': 0, 'size': ProfileOverview.chartSize});
      expect(api.queries[Endpoints.myBlogs], {'size': 1}); // chỉ cần totalElements
    });

    test('một nguồn lỗi không làm mất các nguồn còn lại', () async {
      final api = newApi()..errors[Endpoints.myVideos] = ApiException('Mất kết nối', isNetwork: true);
      final o = make(api)..bindUser(3);
      await o.refresh();
      expect(o.videos, isNull);
      expect(o.blogs, 4);
      expect(o.recipes, 2);
      expect(o.error, 'Mất kết nối');
      expect(o.loaded, isTrue);
    });

    test('lần tải lại lỗi giữ số liệu cũ thay vì xoá', () async {
      final api = newApi();
      final o = make(api)..bindUser(3);
      await o.refresh();
      api.errors[Endpoints.myRecipes] = ApiException('Mất kết nối', isNetwork: true);
      await o.refresh();
      expect(o.recipes, 2);
    });

    test('ensureLoaded chỉ tải một lần; chưa đăng nhập thì không gọi máy chủ', () async {
      final api = newApi();
      final o = make(api);
      await o.ensureLoaded();
      expect(api.calls, isEmpty);

      o.bindUser(3);
      await o.ensureLoaded();
      await o.ensureLoaded();
      expect(api.calls.where((c) => c == Endpoints.me).length, 1);
    });

    test('đăng xuất xoá số liệu của tài khoản trước', () async {
      final o = make(newApi())..bindUser(3);
      await o.refresh();
      o.bindUser(null);
      expect(o.blogs, isNull);
      expect(o.health, isEmpty);
      expect(o.profile, isNull);
      expect(o.loaded, isFalse);
    });
  });

  group('ProfileScreen', () {
    Future<FakeApi> boot(WidgetTester tester, {Map<String, dynamic>? profile}) async {
      final api = FakeApi()
        ..on(Endpoints.me, () => profile ?? _profile())
        ..on(Endpoints.myBlogs, () => {'content': <dynamic>[], 'page': 0, 'totalElements': 4, 'totalPages': 4})
        ..on(Endpoints.myRecipes, () => _page(2))
        ..on(Endpoints.myVideos, () => _page(1))
        ..on(Endpoints.myAllergies, () => <dynamic>[])
        ..on(Endpoints.healthRecords, () => [
              _record(2, 66, '2026-10-20T08:00:00'),
              _record(1, 70, '2026-10-01T08:00:00'),
            ])
        ..on(Endpoints.mySubscription, () => {'planCode': 'PLUS', 'expiresAt': '2026-12-01T00:00:00Z', 'chatPerDay': 20, 'mealPlansPerMonth': 8, 'videosPerMonth': 3});
      api.token = 't';
      final auth = AuthController(api, AuthRepository(api), SessionStore(),
          initial: const AuthSession('t', AuthUser(id: 3, email: 'an@gmail.com', fullName: 'An', role: UserRole.user)));
      final overview = ProfileOverview(ProfileRepository(api), HomeRepository(api), RecipeRepository(api), VideoRepository(api))
        ..bindUser(3);
      final sub = SubscriptionController(PaymentRepository(api))..bindUser(3);
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthController>.value(value: auth),
          ChangeNotifierProvider<ProfileOverview>.value(value: overview),
          ChangeNotifierProvider<SubscriptionController>.value(value: sub),
          ChangeNotifierProvider<HealthSync>(create: (_) => HealthSync()),
          Provider<ProfileRepository>.value(value: ProfileRepository(api)),
        ],
        child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      return api;
    }

    testWidgets('hiện gói, số liệu, BMI mới nhất và biểu đồ theo dõi', (tester) async {
      await boot(tester);
      expect(find.text('An'), findsOneWidget);
      expect(find.textContaining('Gói PLUS'), findsWidgets);
      expect(find.text('4'), findsOneWidget); // bài viết
      expect(find.text('2'), findsOneWidget); // công thức
      expect(find.text('1'), findsOneWidget); // video
      expect(find.text('22.8'), findsWidgets); // BMI = 66 / 1.7^2 = 22.84
      expect(find.text('Theo dõi thể trạng'), findsOneWidget);
      expect(find.textContaining('Chỉ số giảm'), findsOneWidget);
      expect(find.text('Chưa chọn chất nào', findRichText: true), findsNothing);
      expect(find.textContaining('Chưa chọn chất nào'), findsOneWidget); // menu dị ứng
    });

    testWidgets('hồ sơ thiếu ngày sinh / giới tính / vận động thì nhắc bổ sung', (tester) async {
      await boot(tester);
      expect(find.textContaining('Bổ sung ngày sinh, giới tính, mức độ vận động'), findsOneWidget);
      expect(find.text('Bổ sung'), findsOneWidget);
    });

    testWidgets('hồ sơ đủ thông tin thì không nhắc', (tester) async {
      await boot(tester, profile: _profile(dob: '1995-01-01', gender: 'MALE', activity: 'LIGHT'));
      expect(find.textContaining('Bổ sung ngày sinh'), findsNothing);
      expect(find.text('Bổ sung'), findsNothing);
    });

    testWidgets('dưới 18 tuổi thì báo giới hạn nhưng không có nút bổ sung', (tester) async {
      await boot(tester, profile: _profile(dob: '2015-01-01', gender: 'MALE', activity: 'LIGHT'));
      expect(find.textContaining('18 tuổi'), findsOneWidget);
      expect(find.text('Bổ sung'), findsNothing);
    });
  });

  group('EditProfileScreen', () {
    Future<void> boot(WidgetTester tester, Set<String> highlight, Map<String, dynamic> profile) async {
      final api = FakeApi()..on(Endpoints.me, () => profile);
      api.token = 't';
      final auth = AuthController(api, AuthRepository(api), SessionStore(),
          initial: const AuthSession('t', AuthUser(id: 3, email: 'an@gmail.com', fullName: 'An', role: UserRole.user)));
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthController>.value(value: auth),
          Provider<ProfileRepository>.value(value: ProfileRepository(api)),
        ],
        child: MaterialApp(home: EditProfileScreen(highlightFields: highlight)),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('trường được yêu cầu mà còn trống thì có nhắc "Cần bổ sung"', (tester) async {
      await boot(tester, {'dateOfBirth', 'gender'}, _profile(activity: 'LIGHT'));
      expect(find.text('Cần bổ sung để tính nhu cầu calo'), findsNWidgets(2)); // ngày sinh + giới tính, không có vận động
    });

    testWidgets('trường đã có dữ liệu hoặc không được yêu cầu thì không nhắc', (tester) async {
      await boot(tester, {'dateOfBirth'}, _profile(dob: '1995-01-01'));
      expect(find.text('Cần bổ sung để tính nhu cầu calo'), findsNothing);
      await boot(tester, const {}, _profile());
      expect(find.text('Cần bổ sung để tính nhu cầu calo'), findsNothing);
    });

    testWidgets('ngày sinh dưới 18 tuổi hiện cảnh báo', (tester) async {
      await boot(tester, const {}, _profile(dob: '2015-01-01'));
      expect(find.textContaining('chỉ dành cho người từ 18 tuổi'), findsOneWidget);
    });
  });
}
