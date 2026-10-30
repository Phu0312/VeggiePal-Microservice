import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:VeggiePal/core/constants/endpoints.dart';
import 'package:VeggiePal/core/network/api_client.dart';
import 'package:VeggiePal/core/network/error_messages.dart';
import 'package:VeggiePal/core/storage/session_store.dart';
import 'package:VeggiePal/features/auth/data/auth_models.dart';
import 'package:VeggiePal/features/auth/data/auth_repository.dart';
import 'package:VeggiePal/features/auth/data/auth_validators.dart';
import 'package:VeggiePal/features/auth/data/google_auth.dart';
import 'package:VeggiePal/features/auth/presentation/auth_controller.dart';
import 'package:VeggiePal/features/auth/presentation/forgot_password_screen.dart';
import 'package:VeggiePal/features/auth/presentation/login_screen.dart';
import 'package:VeggiePal/features/auth/presentation/otp_widgets.dart';
import 'package:VeggiePal/features/auth/presentation/verify_email_screen.dart';

/// JWT giả có `exp` tính từ bây giờ; [tag] làm hai token cùng hạn nhưng khác chuỗi.
String _jwt(Duration validFor, {String tag = 'a'}) {
  String b64(Map m) => base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  final exp = DateTime.now().add(validFor).millisecondsSinceEpoch ~/ 1000;
  return '${b64({'alg': 'HS256'})}.${b64({'exp': exp, 'tag': tag})}.sig';
}

const _user = AuthUser(id: 7, email: 'an@gmail.com', fullName: 'An', role: UserRole.user, avatarUrl: 'http://x/a.png');

Map<String, dynamic> _loginJson({String? refresh = 'r1', String role = 'USER'}) => {
      'accessToken': _jwt(const Duration(hours: 1)),
      'refreshToken': ?refresh,
      'refreshExpiresIn': 2592000,
      'userId': 7,
      'email': 'an@gmail.com',
      'fullName': 'An',
      'role': role,
    };

/// ApiClient giả cho test repository: ghi lại lời gọi POST, trả kết quả theo đường dẫn.
class _FakeApi extends ApiClient {
  final bodies = <String, Object?>{};
  final results = <String, Object?>{};

  @override
  Future<dynamic> post(String path,
      {Object? body, Map<String, String>? headers, ProgressCallback? onSendProgress, Duration? receiveTimeout}) async {
    bodies[path] = body;
    return results[path];
  }
}

/// Adapter Dio giả: chỉ chấp nhận đúng một access token, token khác nhận 401. Ghi lại header đã gửi.
class _Adapter implements HttpClientAdapter {
  _Adapter(this.accepted);
  String accepted;
  final sent = <String?>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final auth = options.headers['Authorization'] as String?;
    sent.add(auth);
    final ok = auth == 'Bearer $accepted';
    return ResponseBody.fromString(
      jsonEncode(ok ? {'code': 1000, 'result': 'ok'} : {'code': 1008, 'message': 'Unauthenticated'}),
      ok ? 200 : 401,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Repository giả cho controller và màn hình: ghi lại cuộc gọi, không dùng mạng.
class _Repo extends AuthRepository {
  _Repo(super.api);
  final calls = <String>[];
  Object? verifyOtpError;
  Object? sendOtpError; // lỗi khi xin mã (forgot-password / send-verification)
  Object? refreshError;
  Duration refreshDelay = Duration.zero;
  Map<String, dynamic> profileJson = {'fullName': 'An', 'avatarUrl': null, 'emailVerified': true};
  String freshAccess = '';

  @override
  Future<AuthSession> login(String email, String password) async =>
      AuthSession.fromLogin(_loginJson());

  @override
  Future<AuthSession> register(String email, String password, String fullName, String phone) async =>
      AuthSession.fromLogin(_loginJson());

  @override
  Future<Map<String, dynamic>> profile() async => profileJson;

  @override
  Future<OtpSent> forgotPassword(String email) async {
    calls.add('forgot $email');
    final e = sendOtpError;
    if (e != null) throw e;
    return const OtpSent(300);
  }

  @override
  Future<String> verifyResetOtp(String email, String otp) async {
    calls.add('verifyOtp $email $otp');
    final e = verifyOtpError;
    if (e != null) throw e;
    return 'reset-token';
  }

  @override
  Future<void> resetPassword(String resetToken, String newPassword) async => calls.add('reset $resetToken $newPassword');

  @override
  Future<OtpSent> sendVerification(String email) async {
    calls.add('sendVerification $email');
    final e = sendOtpError;
    if (e != null) throw e;
    return const OtpSent(300);
  }

  @override
  Future<void> verifyEmail(String email, String otp) async => calls.add('verifyEmail $email $otp');

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    calls.add('refresh $refreshToken');
    await Future<void>.delayed(refreshDelay);
    final e = refreshError;
    if (e != null) throw e;
    return AuthSession(freshAccess, _user.copyWith(role: UserRole.user), refreshToken: 'r2');
  }

  @override
  Future<void> logout(String refreshToken) async => calls.add('logout $refreshToken');
}

void main() {
  setUp(() {
    dotenv.loadFromString(envString: 'APP=test');
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('validateOtp: đúng 6 chữ số', () {
    expect(validateOtp(''), 'Vui lòng nhập mã xác nhận');
    expect(validateOtp('12345'), 'Mã gồm 6 chữ số');
    expect(validateOtp('12345a'), 'Mã gồm 6 chữ số');
    expect(validateOtp(' 123456 '), isNull);
  });

  group('AuthRepository', () {
    test('login giữ refreshToken của BE', () {
      final s = AuthSession.fromLogin(_loginJson(refresh: 'abc'));
      expect(s.refreshToken, 'abc');
      expect(AuthSession.fromLogin(_loginJson(refresh: null)).refreshToken, isNull);
    });

    test('login đọc emailVerified của BE; thiếu trường thì coi như đã xác minh để không nhắc nhầm', () {
      expect(AuthSession.fromLogin({..._loginJson(), 'emailVerified': false}).user.emailVerified, isFalse);
      expect(AuthSession.fromLogin({..._loginJson(), 'emailVerified': true}).user.emailVerified, isTrue);
      expect(AuthSession.fromLogin(_loginJson()).user.emailVerified, isTrue);
    });

    test('mã lỗi OTP và nhật ký mới của BE có thông báo tiếng Việt', () {
      for (final code in [1033, 1034, 2012, 2013, 3051, 6025, 6026]) {
        expect(errorMessagesVi[code], isNotNull, reason: 'thiếu mã $code');
      }
      expect(localizedError(1033, 'Too many OTP requests; try again later'), contains('quá nhiều lần'));
      // 2010 / 2011 của nutrition-service là nhật ký ăn uống và lượng nước, không phải nguyên liệu.
      expect(errorMessagesVi[2010], contains('nhật ký'));
      expect(errorMessagesVi[2011], contains('ml'));
    });

    test('quên mật khẩu: gửi email, đổi OTP lấy resetToken, đặt mật khẩu bằng resetToken', () async {
      final api = _FakeApi()
        ..results[Endpoints.forgotPassword] = {'message': 'm', 'expiresInSeconds': 300}
        ..results[Endpoints.verifyOtp] = {'verified': true, 'resetToken': 'tok', 'expiresInSeconds': 600};
      final repo = AuthRepository(api);

      expect((await repo.forgotPassword(' an@gmail.com ')).expiresInSeconds, 300);
      expect(api.bodies[Endpoints.forgotPassword], {'email': 'an@gmail.com'});

      expect(await repo.verifyResetOtp('an@gmail.com', ' 123456 '), 'tok');
      expect(api.bodies[Endpoints.verifyOtp], {'email': 'an@gmail.com', 'otp': '123456'});

      await repo.resetPassword('tok', 'secret1');
      expect(api.bodies[Endpoints.resetPassword], {'resetToken': 'tok', 'newPassword': 'secret1'});
    });

    test('xác minh email luôn gửi kèm email vì /auth/send-verification là endpoint công khai', () async {
      final api = _FakeApi()..results[Endpoints.sendVerification] = {'expiresInSeconds': 120};
      final repo = AuthRepository(api);
      expect((await repo.sendVerification('an@gmail.com')).expiresInSeconds, 120);
      expect(api.bodies[Endpoints.sendVerification], {'email': 'an@gmail.com'});
      await repo.verifyEmail('an@gmail.com', '123456');
      expect(api.bodies[Endpoints.verifyEmail], {'email': 'an@gmail.com', 'otp': '123456'});
    });

    test('refresh gửi refreshToken và đọc phiên mới; logout nuốt mọi lỗi', () async {
      final api = _FakeApi()..results[Endpoints.refreshToken] = _loginJson(refresh: 'r2');
      final s = await AuthRepository(api).refresh('r1');
      expect(api.bodies[Endpoints.refreshToken], {'refreshToken': 'r1'});
      expect(s.refreshToken, 'r2');

      await AuthRepository(_ThrowingApi()).logout('r1'); // không ném
    });
  });

  group('SessionStore với refresh token', () {
    test('lưu và khôi phục refreshToken, kể cả khi access token đã hết hạn', () async {
      final store = SessionStore();
      final expired = _jwt(const Duration(minutes: -5));
      await store.save(AuthSession(expired, _user, refreshToken: 'r1'));

      final s = await store.load();
      expect(s, isNotNull);
      expect(s!.token, expired);
      expect(s.refreshToken, 'r1');
    });

    test('access token hết hạn mà không có refresh token thì bỏ phiên', () async {
      final store = SessionStore();
      await store.save(AuthSession(_jwt(const Duration(minutes: -5)), _user));
      expect(await store.load(), isNull);
    });

    test('isJwtExpired với leeway coi token sắp hết hạn là hết hạn', () {
      final soon = _jwt(const Duration(seconds: 10));
      expect(SessionStore.isJwtExpired(soon), isFalse);
      expect(SessionStore.isJwtExpired(soon, leeway: const Duration(seconds: 30)), isTrue);
    });
  });

  group('ApiClient làm mới token', () {
    late ApiClient api;
    late _Adapter adapter;
    late String fresh;
    late int refreshCalls;
    late int expiredCalls;

    setUp(() {
      fresh = _jwt(const Duration(hours: 1), tag: 'fresh');
      adapter = _Adapter(fresh);
      refreshCalls = 0;
      expiredCalls = 0;
      api = ApiClient()
        ..onSessionExpired = (() => expiredCalls++)
        ..dio.httpClientAdapter = adapter;
    });

    test('401 thì làm mới rồi gửi lại đúng một lần với token mới', () async {
      api
        ..token = _jwt(const Duration(hours: 1), tag: 'stale') // chưa hết hạn nhưng BE đã thu hồi
        ..refreshToken = 'r1'
        ..refreshSession = () async {
          refreshCalls++;
          api.token = fresh;
          return true;
        };

      expect(await api.get('/users/me'), 'ok');
      expect(refreshCalls, 1);
      expect(adapter.sent.length, 2);
      expect(adapter.sent.last, 'Bearer $fresh');
      expect(expiredCalls, 0);
    });

    test('token đã hết hạn thì làm mới trước khi gửi, không tốn request 401', () async {
      api
        ..token = _jwt(const Duration(minutes: -1), tag: 'old')
        ..refreshToken = 'r1'
        ..refreshSession = () async {
          refreshCalls++;
          api.token = fresh;
          return true;
        };

      expect(await api.get('/users/me'), 'ok');
      expect(refreshCalls, 1);
      expect(adapter.sent, ['Bearer $fresh']);
    });

    test('làm mới thất bại thì báo lỗi 401, việc đăng xuất là của AuthController', () async {
      api
        ..token = _jwt(const Duration(hours: 1), tag: 'stale')
        ..refreshToken = 'r1'
        ..refreshSession = () async {
          refreshCalls++;
          return false;
        };

      await expectLater(api.get('/users/me'), throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)));
      expect(refreshCalls, 1);
      expect(adapter.sent.length, 1);
      expect(expiredCalls, 0);
    });

    test('sau khi gửi lại vẫn 401 thì coi là hết phiên, không lặp vô hạn', () async {
      adapter.accepted = 'khong-token-nao-hop-le';
      api
        ..token = _jwt(const Duration(hours: 1), tag: 'stale')
        ..refreshToken = 'r1'
        ..refreshSession = () async {
          refreshCalls++;
          api.token = fresh;
          return true;
        };

      await expectLater(api.get('/users/me'), throwsA(isA<ApiException>()));
      expect(refreshCalls, 1);
      expect(adapter.sent.length, 2);
      expect(expiredCalls, 1);
    });

    test('không có refresh token thì 401 báo hết phiên như trước', () async {
      api.token = _jwt(const Duration(hours: 1), tag: 'stale');
      await expectLater(api.get('/users/me'), throwsA(isA<ApiException>()));
      expect(expiredCalls, 1);
    });

    test('endpoint /auth/* không đi qua cơ chế làm mới', () async {
      api
        ..token = _jwt(const Duration(minutes: -1), tag: 'old')
        ..refreshToken = 'r1'
        ..refreshSession = () async {
          refreshCalls++;
          return true;
        };
      await expectLater(api.post('/auth/refresh', body: {'refreshToken': 'r1'}), throwsA(isA<ApiException>()));
      expect(refreshCalls, 0);
      expect(expiredCalls, 0);
    });
  });

  group('AuthController', () {
    late _Repo repo;
    late ApiClient api;
    late String fresh;

    setUp(() {
      api = ApiClient();
      repo = _Repo(api);
      fresh = _jwt(const Duration(hours: 1), tag: 'fresh');
      repo.freshAccess = fresh;
    });

    Future<AuthController> boot({bool remember = true, VoidCallback? onExpired, Duration expiredBy = const Duration(minutes: -1)}) async {
      final session = AuthSession(_jwt(expiredBy, tag: 'old'), _user, refreshToken: 'r1');
      if (remember) await SessionStore().save(session);
      final auth = AuthController(api, repo, SessionStore(), initial: session, onSessionExpired: onExpired);
      await Future<void>.delayed(Duration.zero); // _loadProfile
      return auth;
    }

    test('token hết hạn lúc mở app: request đầu tiên tự làm mới, đổi refresh token và lưu lại', () async {
      final auth = await boot();
      api.dio.httpClientAdapter = _Adapter(fresh);

      expect(await api.get('/users/me'), 'ok');

      expect(repo.calls, ['refresh r1']);
      expect(auth.isLoggedIn, isTrue);
      expect(api.token, fresh);
      expect(api.refreshToken, 'r2');
      final stored = await SessionStore().load();
      expect(stored?.token, fresh);
      expect(stored?.refreshToken, 'r2');
      expect(auth.user?.avatarUrl, 'http://x/a.png'); // ảnh đại diện không bị mất
    });

    test('nhiều request cùng gặp token hết hạn chỉ làm mới một lần', () async {
      await boot();
      repo.refreshDelay = const Duration(milliseconds: 30);
      api.dio.httpClientAdapter = _Adapter(fresh);

      await Future.wait([api.get('/a'), api.get('/b'), api.get('/c')]);

      expect(repo.calls.where((c) => c.startsWith('refresh')).length, 1);
    });

    test('BE từ chối refresh token (1030) thì đăng xuất, xoá phiên đã lưu và báo hết phiên', () async {
      var expired = 0;
      final auth = await boot(onExpired: () => expired++);
      repo.refreshError = ApiException('x', code: 1030, statusCode: 401);
      api.dio.httpClientAdapter = _Adapter(fresh);

      await expectLater(api.get('/users/me'), throwsA(isA<ApiException>()));

      expect(auth.isLoggedIn, isFalse);
      expect(expired, 1);
      expect(await SessionStore().load(), isNull);
    });

    test('mất mạng khi làm mới thì giữ phiên để thử lại sau', () async {
      var expired = 0;
      final auth = await boot(onExpired: () => expired++);
      repo.refreshError = ApiException('mạng', isNetwork: true);
      api.dio.httpClientAdapter = _Adapter(fresh);

      await expectLater(api.get('/users/me'), throwsA(isA<ApiException>()));

      expect(auth.isLoggedIn, isTrue);
      expect(expired, 0);
      expect((await SessionStore().load())?.refreshToken, 'r1');
    });

    test('phiên không ghi nhớ vẫn làm mới được nhưng không ghi xuống máy', () async {
      final auth = AuthController(api, repo, SessionStore());
      await auth.login('a@b.c', 'secret1'); // remember = false
      await Future<void>.delayed(Duration.zero);
      api.dio.httpClientAdapter = _Adapter(fresh); // token lúc đăng nhập bị BE từ chối -> 401 -> làm mới

      expect(await api.get('/users/me'), 'ok');

      expect(api.token, fresh);
      expect(api.refreshToken, 'r2');
      expect(auth.isLoggedIn, isTrue);
      expect(await SessionStore().load(), isNull);
    });

    test('đăng xuất thu hồi refresh token ở BE', () async {
      final auth = await boot();
      auth.logout();
      await Future<void>.delayed(Duration.zero);
      expect(repo.calls, ['logout r1']);
      expect(auth.isLoggedIn, isFalse);
      expect(api.refreshToken, isNull);
    });

    test('đăng xuất khi chưa có refresh token thì không gọi BE', () async {
      final auth = AuthController(api, repo, SessionStore(),
          initial: AuthSession(_jwt(const Duration(hours: 1)), _user));
      await Future<void>.delayed(Duration.zero);
      auth.logout();
      await Future<void>.delayed(Duration.zero);
      expect(repo.calls, isEmpty);
    });

    test('hồ sơ báo email chưa xác minh thì cập nhật; xác minh xong thì chuyển sang đã xác minh', () async {
      repo.profileJson = {'fullName': 'An', 'avatarUrl': null, 'emailVerified': false};
      final auth = await boot(expiredBy: const Duration(hours: 1));
      expect(auth.user!.emailVerified, isFalse);

      await auth.verifyEmail('123456');
      expect(repo.calls, ['verifyEmail an@gmail.com 123456']);
      expect(auth.user!.emailVerified, isTrue);
      expect((await SessionStore().load())?.user.emailVerified, isTrue);
    });
  });

  group('màn hình', () {
    Future<(_Repo, AuthController)> pumpApp(WidgetTester tester, Widget Function() home,
        {bool loggedIn = false}) async {
      final api = ApiClient();
      final repo = _Repo(api);
      final auth = AuthController(api, repo, SessionStore(),
          initial: loggedIn ? AuthSession(_jwt(const Duration(hours: 1)), _user, refreshToken: 'r1') : null);
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<AuthRepository>.value(value: repo),
          ChangeNotifierProvider<AuthController>.value(value: auth),
          Provider<GoogleIdTokenSource>.value(value: _NoGoogle()),
        ],
        child: MaterialApp(home: home()),
      ));
      return (repo, auth);
    }

    Finder field(String label) => find.widgetWithText(TextFormField, label);

    testWidgets('Quên mật khẩu: email -> mã -> mật khẩu mới, xong trả email về cho màn gọi', (tester) async {
      String? result;
      final (repo, _) = await pumpApp(tester, () => Builder(builder: (context) {
            return TextButton(
              onPressed: () async => result = await Navigator.of(context).push<String>(
                  MaterialPageRoute(builder: (_) => const ForgotPasswordScreen(initialEmail: 'an@gmail.com'))),
              child: const Text('mở'),
            );
          }));
      await tester.tap(find.text('mở'));
      await tester.pumpAndSettle();

      // Bước 1: email điền sẵn.
      expect(find.text('Gửi mã'), findsOneWidget);
      await tester.tap(find.text('Gửi mã'));
      await tester.pumpAndSettle();
      expect(repo.calls, ['forgot an@gmail.com']);

      // Bước 2: mã sai định dạng bị chặn, đúng thì sang bước 3.
      expect(find.text('Nhập mã xác nhận'), findsOneWidget);
      await tester.enterText(field('Mã xác nhận'), '123');
      await tester.tap(find.widgetWithText(FilledButton, 'Xác nhận'));
      await tester.pump();
      expect(find.text('Mã gồm 6 chữ số'), findsOneWidget);
      expect(repo.calls.where((c) => c.startsWith('verifyOtp')), isEmpty);

      await tester.enterText(field('Mã xác nhận'), '123456');
      await tester.tap(find.widgetWithText(FilledButton, 'Xác nhận'));
      await tester.pumpAndSettle();
      expect(repo.calls.last, 'verifyOtp an@gmail.com 123456');

      // Bước 3: mật khẩu nhập lại phải khớp.
      expect(find.text('Đặt mật khẩu mới'), findsOneWidget);
      await tester.enterText(field('Mật khẩu mới'), 'secret1');
      await tester.enterText(field('Nhập lại mật khẩu mới'), 'secret2');
      await tester.tap(find.widgetWithText(FilledButton, 'Đặt lại mật khẩu'));
      await tester.pump();
      expect(find.text('Mật khẩu nhập lại không khớp'), findsOneWidget);

      await tester.enterText(field('Nhập lại mật khẩu mới'), 'secret1');
      await tester.tap(find.widgetWithText(FilledButton, 'Đặt lại mật khẩu'));
      await tester.pumpAndSettle();
      expect(repo.calls.last, 'reset reset-token secret1');
      expect(result, 'an@gmail.com');
      expect(find.text('mở'), findsOneWidget); // đã đóng màn hình
    });

    testWidgets('Quên mật khẩu: nhập sai quá số lần (1026) thì quay lại bước nhập email', (tester) async {
      final (repo, _) = await pumpApp(tester, () => const ForgotPasswordScreen(initialEmail: 'an@gmail.com'));
      repo.verifyOtpError = ApiException('Quá số lần', code: 1026, statusCode: 429);
      await tester.tap(find.text('Gửi mã'));
      await tester.pumpAndSettle();
      await tester.enterText(field('Mã xác nhận'), '000000');
      await tester.tap(find.widgetWithText(FilledButton, 'Xác nhận'));
      await tester.pumpAndSettle();

      expect(find.text('Mã không hợp lệ'), findsOneWidget); // popup lỗi
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();
      expect(find.text('Quên mật khẩu'), findsOneWidget);
      expect(find.text('Gửi mã'), findsOneWidget);
    });

    testWidgets('Quên mật khẩu: gửi quá nhiều mã (1033) hiện thông báo rõ và ở lại bước nhập email', (tester) async {
      final (repo, _) = await pumpApp(tester, () => const ForgotPasswordScreen(initialEmail: 'an@gmail.com'));
      repo.sendOtpError = ApiException(localizedError(1033, 'Too many OTP requests'), code: 1033, statusCode: 429);
      await tester.tap(find.text('Gửi mã'));
      await tester.pumpAndSettle();

      expect(find.text('Không gửi được mã'), findsOneWidget);
      expect(find.text(errorMessagesVi[1033]!), findsOneWidget);
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();
      expect(find.text('Gửi mã'), findsOneWidget); // vẫn ở bước nhập email
    });

    testWidgets('Xác minh email: máy chủ chưa cấu hình email (1034) hiện thông báo, không báo đã gửi', (tester) async {
      final (repo, _) = await pumpApp(tester, () => const VerifyEmailScreen(sendOnOpen: true), loggedIn: true);
      repo.sendOtpError = ApiException(localizedError(1034, 'OTP email delivery is not configured'),
          code: 1034, statusCode: 503);
      // Mã đã được gửi một lần lúc mở màn hình; bấm gửi lại sau khi hết đếm ngược để chạm lỗi.
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 61));
      await tester.tap(find.text('Gửi lại mã'));
      await tester.pumpAndSettle();

      expect(find.text('Không gửi được mã'), findsOneWidget);
      expect(find.text(errorMessagesVi[1034]!), findsOneWidget);
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Gửi lại mã bị khóa trong lúc đếm ngược rồi mở lại sau 60 giây', (tester) async {
      await pumpApp(tester, () => const ForgotPasswordScreen(initialEmail: 'an@gmail.com'));
      await tester.tap(find.text('Gửi mã'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Gửi lại mã sau'), findsOneWidget);
      expect(tester.widget<TextButton>(find.widgetWithText(TextButton, 'Gửi lại mã sau 60s')).onPressed, isNull);

      await tester.pump(const Duration(seconds: 60));
      expect(find.text('Gửi lại mã'), findsOneWidget);
      expect(tester.widget<TextButton>(find.widgetWithText(TextButton, 'Gửi lại mã')).onPressed, isNotNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Xác minh email mở từ Hồ sơ: tự gửi mã, nhập đúng mã thì đóng và đánh dấu đã xác minh', (tester) async {
      bool? result;
      final (repo, auth) = await pumpApp(
        tester,
        () => Builder(builder: (context) {
          return TextButton(
            onPressed: () async => result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const VerifyEmailScreen(sendOnOpen: true))),
            child: const Text('mở'),
          );
        }),
        loggedIn: true,
      );
      repo.profileJson = {'fullName': 'An', 'avatarUrl': null, 'emailVerified': false};
      await tester.tap(find.text('mở'));
      await tester.pumpAndSettle();
      expect(repo.calls, ['sendVerification an@gmail.com']);

      await tester.enterText(field('Mã xác nhận'), '654321');
      await tester.tap(find.widgetWithText(FilledButton, 'Xác minh'));
      await tester.pumpAndSettle();

      expect(repo.calls.last, 'verifyEmail an@gmail.com 654321');
      expect(auth.user!.emailVerified, isTrue);
      expect(result, isTrue);
    });

    testWidgets('Xác minh email: "Để sau" đóng màn hình mà không xác minh', (tester) async {
      bool? result;
      final (repo, _) = await pumpApp(
        tester,
        () => Builder(builder: (context) {
          return TextButton(
            onPressed: () async => result = await Navigator.of(context)
                .push<bool>(MaterialPageRoute(builder: (_) => const VerifyEmailScreen())),
            child: const Text('mở'),
          );
        }),
        loggedIn: true,
      );
      await tester.tap(find.text('mở'));
      await tester.pumpAndSettle();
      expect(repo.calls, isEmpty); // vừa đăng ký: BE đã gửi mã, màn hình không gửi thêm
      await tester.tap(find.text('Để sau'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Màn đăng nhập: có "Quên mật khẩu?" (không có ở chế độ đăng ký), đặt lại xong thì điền sẵn email',
        (tester) async {
      final (repo, _) = await pumpApp(tester, () => const LoginScreen());
      expect(find.text('Quên mật khẩu?'), findsOneWidget);

      await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
      await tester.pump();
      expect(find.text('Quên mật khẩu?'), findsNothing);
      await tester.tap(find.text('Đã có tài khoản? Đăng nhập'));
      await tester.pump();

      await tester.enterText(field('Email'), 'an@gmail.com');
      await tester.tap(find.text('Quên mật khẩu?'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextFormField>(field('Email')).controller!.text, 'an@gmail.com'); // điền sẵn

      await tester.tap(find.text('Gửi mã'));
      await tester.pumpAndSettle();
      await tester.enterText(field('Mã xác nhận'), '123456');
      await tester.tap(find.widgetWithText(FilledButton, 'Xác nhận'));
      await tester.pumpAndSettle();
      await tester.enterText(field('Mật khẩu mới'), 'secret1');
      await tester.enterText(field('Nhập lại mật khẩu mới'), 'secret1');
      await tester.tap(find.widgetWithText(FilledButton, 'Đặt lại mật khẩu'));
      await tester.pumpAndSettle();

      expect(repo.calls.last, 'reset reset-token secret1');
      expect(find.text('Đã đặt lại mật khẩu. Hãy đăng nhập bằng mật khẩu mới.'), findsOneWidget);
      expect(tester.widget<TextFormField>(field('Email')).controller!.text, 'an@gmail.com');
    });

    testWidgets('Đăng ký xong thì mở màn xác minh email', (tester) async {
      await pumpApp(tester, () => const LoginScreen());
      await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
      await tester.pump();
      await tester.enterText(field('Họ tên'), 'An');
      await tester.enterText(field('Email'), 'an@gmail.com');
      await tester.enterText(field('Mật khẩu'), 'secret1');
      await tester.enterText(field('Nhập lại mật khẩu'), 'secret1');
      await tester.tap(find.widgetWithText(FilledButton, 'Tạo tài khoản'));
      await tester.pumpAndSettle();

      expect(find.text('Xác minh email'), findsOneWidget);
      expect(find.byType(OtpField), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });
}

class _ThrowingApi extends ApiClient {
  @override
  Future<dynamic> post(String path,
          {Object? body, Map<String, String>? headers, ProgressCallback? onSendProgress, Duration? receiveTimeout}) =>
      throw ApiException('mạng', isNetwork: true);
}

class _NoGoogle implements GoogleIdTokenSource {
  @override
  bool get isConfigured => false;

  @override
  Future<String?> idToken() async => null;
}
