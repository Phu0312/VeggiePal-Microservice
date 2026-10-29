import 'dart:convert';

import 'package:dio/dio.dart' show ProgressCallback;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:VeggiePal/core/constants/endpoints.dart';
import 'package:VeggiePal/core/network/api_client.dart';
import 'package:VeggiePal/core/storage/session_store.dart';
import 'package:VeggiePal/features/auth/data/auth_models.dart';
import 'package:VeggiePal/features/auth/data/auth_repository.dart';
import 'package:VeggiePal/features/auth/data/auth_validators.dart';
import 'package:VeggiePal/features/auth/data/google_auth.dart';
import 'package:VeggiePal/features/auth/presentation/auth_controller.dart';
import 'package:VeggiePal/features/auth/presentation/login_screen.dart';

String _jwt() {
  String b64(Map m) => base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  final exp = DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
  return '${b64({'alg': 'HS256'})}.${b64({'exp': exp})}.sig';
}

/// ApiClient giả: ghi lại lời gọi POST và trả kết quả theo đường dẫn (hoặc ném lỗi).
class FakeApi extends ApiClient {
  final bodies = <String, Object?>{};
  final results = <String, Object?>{};
  final errors = <String, ApiException>{};

  @override
  Future<dynamic> post(String path,
      {Object? body, Map<String, String>? headers, ProgressCallback? onSendProgress, Duration? receiveTimeout}) async {
    bodies[path] = body;
    final e = errors[path];
    if (e != null) throw e;
    return results[path];
  }
}

Map<String, dynamic> _login({String role = 'USER'}) =>
    {'accessToken': _jwt(), 'userId': 7, 'email': 'an@gmail.com', 'fullName': 'An', 'role': role};

/// Nguồn Google ID token giả.
class FakeGoogle implements GoogleIdTokenSource {
  bool configured = true;
  String? token = 'google-id-token';
  Object? error;
  var calls = 0;

  @override
  bool get isConfigured => configured;

  @override
  Future<String?> idToken() async {
    calls++;
    if (!configured) throw ApiException('Chưa cấu hình đăng nhập Google (thiếu GOOGLE_CLIENT_ID trong .env).');
    final e = error;
    if (e != null) throw e;
    return token;
  }
}

/// Repository giả cho màn đăng nhập: ghi lại cuộc gọi, không dùng mạng.
class FakeRepo extends AuthRepository {
  FakeRepo(super.api);
  final calls = <String>[];

  AuthSession get _session => AuthSession(_jwt(), const AuthUser(id: 7, email: 'an@gmail.com', fullName: 'An', role: UserRole.user));

  @override
  Future<AuthSession> login(String email, String password) async {
    calls.add('login $email');
    return _session;
  }

  @override
  Future<AuthSession> register(String email, String password, String fullName, String phone) async {
    calls.add('register $email|$fullName|$phone');
    return _session;
  }

  @override
  Future<AuthSession> loginWithGoogle(String idToken) async {
    calls.add('google $idToken');
    return _session;
  }

  @override
  Future<Map<String, dynamic>> profile() async => {'fullName': 'An', 'avatarUrl': null};
}

void main() {
  setUp(() {
    dotenv.loadFromString(envString: 'APP=test');
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('kiểm tra form', () {
    test('email', () {
      expect(validateEmail(''), 'Vui lòng nhập email');
      expect(validateEmail('an@'), 'Email không hợp lệ');
      expect(validateEmail('an@gmail'), 'Email không hợp lệ');
      expect(validateEmail('an gmail@x.com'), 'Email không hợp lệ');
      expect(validateEmail(' an@gmail.com '), isNull);
    });

    test('mật khẩu tối thiểu 6 ký tự, họ tên không để trống', () {
      expect(validatePassword(''), isNotNull);
      expect(validatePassword('12345'), 'Mật khẩu tối thiểu 6 ký tự');
      expect(validatePassword('123456'), isNull);
      expect(validateFullName('  '), isNotNull);
      expect(validateFullName('An'), isNull);
    });

    test('số điện thoại không bắt buộc nhưng nếu nhập phải hợp lệ', () {
      expect(validatePhone(''), isNull);
      expect(validatePhone('028 7309 3899'), isNull);
      expect(validatePhone('+84 90 123 4567'), isNull);
      expect(validatePhone('abc'), 'Số điện thoại không hợp lệ');
      expect(validatePhone('123'), 'Số điện thoại không hợp lệ');
    });

    test('nhập lại mật khẩu phải khớp', () {
      expect(validateConfirmPassword('', 'abcdef'), isNotNull);
      expect(validateConfirmPassword('abcdeg', 'abcdef'), 'Mật khẩu nhập lại không khớp');
      expect(validateConfirmPassword('abcdef', 'abcdef'), isNull);
    });
  });

  group('AuthRepository', () {
    test('loginWithGoogle gửi idToken và trả phiên như đăng nhập thường', () async {
      final api = FakeApi()..results[Endpoints.googleLogin] = _login();
      final s = await AuthRepository(api).loginWithGoogle('abc');
      expect(api.bodies[Endpoints.googleLogin], {'idToken': 'abc'});
      expect(s.user.email, 'an@gmail.com');
      expect(s.user.role, UserRole.user);
    });

    test('tài khoản ADMIN đăng nhập bằng Google vẫn nhận vai trò admin', () async {
      final api = FakeApi()..results[Endpoints.googleLogin] = _login(role: 'ADMIN');
      expect((await AuthRepository(api).loginWithGoogle('abc')).user.role, UserRole.admin);
    });

    test('mã 1019 (token Google sai) có thông báo tiếng Việt riêng', () async {
      final api = FakeApi()
        ..errors[Endpoints.googleLogin] = ApiException('Không xác thực được tài khoản Google. Vui lòng thử lại.', code: 1019, statusCode: 401);
      await expectLater(AuthRepository(api).loginWithGoogle('x'),
          throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('Google'))));
    });

    test('đăng nhập sai email hoặc mật khẩu (1008) chỉ báo một câu chung', () async {
      final api = FakeApi()..errors[Endpoints.login] = ApiException('Bạn cần đăng nhập', code: 1008, statusCode: 401);
      await expectLater(AuthRepository(api).login('a@b.c', 'x'),
          throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Email hoặc mật khẩu không đúng.')));
    });
  });

  group('google_auth', () {
    test('người dùng tự đóng màn chọn tài khoản không phải lỗi', () {
      expect(googleErrorToResult(GoogleSignInExceptionCode.canceled), isNull);
      expect(googleErrorToResult(GoogleSignInExceptionCode.interrupted), isNull);
    });

    test('lỗi cấu hình và lỗi khác được báo bằng tiếng Việt', () {
      expect(() => googleErrorToResult(GoogleSignInExceptionCode.clientConfigurationError),
          throwsA(isA<ApiException>().having((e) => e.message, 'm', contains('Cấu hình đăng nhập Google'))));
      expect(() => googleErrorToResult(GoogleSignInExceptionCode.unknownError),
          throwsA(isA<ApiException>().having((e) => e.message, 'm', contains('Đăng nhập bằng Google thất bại'))));
    });

    test('chưa cấu hình GOOGLE_CLIENT_ID thì báo rõ, không gọi Google', () async {
      expect(GoogleSignInSource().isConfigured, isFalse);
      await expectLater(GoogleSignInSource().idToken(),
          throwsA(isA<ApiException>().having((e) => e.message, 'm', contains('GOOGLE_CLIENT_ID'))));
      dotenv.loadFromString(envString: 'GOOGLE_CLIENT_ID=abc.apps.googleusercontent.com');
      expect(GoogleSignInSource().isConfigured, isTrue);
    });
  });

  test('AuthController.loginWithGoogle luôn lưu phiên (giống bản web)', () async {
    final store = SessionStore();
    final api = ApiClient();
    final auth = AuthController(api, FakeRepo(api), store);
    await auth.loginWithGoogle('t');
    await Future<void>.delayed(Duration.zero);
    expect(auth.isLoggedIn, isTrue);
    expect((await store.load())?.user.email, 'an@gmail.com');
    expect(api.token, isNotNull);
  });

  group('LoginScreen', () {
    Future<(FakeRepo, FakeGoogle, AuthController)> boot(WidgetTester tester) async {
      final api = ApiClient();
      final repo = FakeRepo(api);
      final google = FakeGoogle();
      final auth = AuthController(api, repo, SessionStore());
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthController>.value(value: auth),
          Provider<GoogleIdTokenSource>.value(value: google),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen())),
              child: const Text('mở'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('mở'));
      await tester.pumpAndSettle();
      return (repo, google, auth);
    }

    testWidgets('đăng nhập hợp lệ thì gọi đăng nhập rồi đóng màn hình', (tester) async {
      final (repo, _, auth) = await boot(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'an@gmail.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Mật khẩu'), 'secret1');
      await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
      await tester.pumpAndSettle();
      expect(repo.calls, ['login an@gmail.com']);
      expect(auth.isLoggedIn, isTrue);
      expect(find.text('mở'), findsOneWidget); // đã quay về màn trước
    });

    testWidgets('form không hợp lệ thì báo lỗi và không gọi máy chủ', (tester) async {
      final (repo, _, _) = await boot(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'khong-hop-le');
      await tester.enterText(find.widgetWithText(TextFormField, 'Mật khẩu'), '123');
      await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
      await tester.pump();
      expect(find.text('Email không hợp lệ'), findsOneWidget);
      expect(find.text('Mật khẩu tối thiểu 6 ký tự'), findsOneWidget);
      expect(repo.calls, isEmpty);
    });

    testWidgets('đăng ký: có ô nhập lại mật khẩu, không khớp thì chặn', (tester) async {
      final (repo, _, _) = await boot(tester);
      await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
      await tester.pump();
      expect(find.widgetWithText(TextFormField, 'Nhập lại mật khẩu'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, 'Họ tên'), 'An Nguyễn');
      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'an@gmail.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Mật khẩu'), 'secret1');
      await tester.enterText(find.widgetWithText(TextFormField, 'Nhập lại mật khẩu'), 'secret2');
      await tester.tap(find.widgetWithText(FilledButton, 'Tạo tài khoản'));
      await tester.pump();
      expect(find.text('Mật khẩu nhập lại không khớp'), findsOneWidget);
      expect(repo.calls, isEmpty);

      await tester.enterText(find.widgetWithText(TextFormField, 'Nhập lại mật khẩu'), 'secret1');
      await tester.tap(find.widgetWithText(FilledButton, 'Tạo tài khoản'));
      await tester.pumpAndSettle();
      expect(repo.calls, ['register an@gmail.com|An Nguyễn|']);
    });

    testWidgets('Tiếp tục với Google: gửi ID token cho backend rồi đóng màn hình', (tester) async {
      final (repo, google, auth) = await boot(tester);
      await tester.tap(find.text('Tiếp tục với Google'));
      await tester.pumpAndSettle();
      expect(google.calls, 1);
      expect(repo.calls, ['google google-id-token']);
      expect(auth.isLoggedIn, isTrue);
      expect(find.text('mở'), findsOneWidget);
    });

    testWidgets('đóng màn chọn tài khoản Google thì ở lại màn đăng nhập, không báo lỗi', (tester) async {
      final (repo, google, auth) = await boot(tester);
      google.token = null;
      await tester.tap(find.text('Tiếp tục với Google'));
      await tester.pumpAndSettle();
      expect(repo.calls, isEmpty);
      expect(auth.isLoggedIn, isFalse);
      expect(find.text('Đăng nhập bằng Google thất bại'), findsNothing);
      expect(find.text('Tiếp tục với Google'), findsOneWidget);
    });

    testWidgets('Google chưa cấu hình: hiện popup nêu rõ thiếu GOOGLE_CLIENT_ID', (tester) async {
      final (repo, google, _) = await boot(tester);
      google.configured = false;
      await tester.tap(find.text('Tiếp tục với Google'));
      await tester.pumpAndSettle();
      expect(find.text('Đăng nhập bằng Google thất bại'), findsOneWidget);
      expect(find.textContaining('GOOGLE_CLIENT_ID'), findsOneWidget);
      expect(repo.calls, isEmpty);
    });
  });
}
