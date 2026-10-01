import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/storage/session_store.dart';
import 'package:frontend/features/auth/data/auth_models.dart';
import 'package:frontend/features/auth/data/auth_repository.dart';
import 'package:frontend/features/auth/presentation/auth_controller.dart';
import 'package:frontend/features/auth/presentation/login_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

String _jwt() {
  String b64(Map m) => base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  final exp = DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
  return '${b64({'alg': 'HS256'})}.${b64({'exp': exp})}.sig';
}

class _FakeRepo extends AuthRepository {
  _FakeRepo(super.api);

  @override
  Future<AuthSession> login(String email, String password) async => AuthSession(
      _jwt(), const AuthUser(id: 1, email: 'a@b.c', fullName: 'An', role: UserRole.user));

  @override
  Future<Map<String, dynamic>> profile() async => {'fullName': 'An', 'avatarUrl': null};
}

void main() {
  setUp(() {
    dotenv.loadFromString(envString: 'APP=test');
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('Không tick "Ghi nhớ" thì phiên không được lưu', () async {
    final store = SessionStore();
    final auth = AuthController(ApiClient(), _FakeRepo(ApiClient()), store);
    await auth.login('a@b.c', 'secret1');
    await Future<void>.delayed(Duration.zero);

    expect(auth.isLoggedIn, isTrue);
    expect(await store.load(), isNull);
  });

  test('Tick "Ghi nhớ" thì phiên được lưu, đăng xuất thì xoá', () async {
    final store = SessionStore();
    final auth = AuthController(ApiClient(), _FakeRepo(ApiClient()), store);
    await auth.login('a@b.c', 'secret1', remember: true);
    await Future<void>.delayed(Duration.zero);
    expect((await store.load())?.user.email, 'a@b.c');

    auth.logout();
    await Future<void>.delayed(Duration.zero);
    expect(await store.load(), isNull);
  });

  testWidgets('Màn đăng nhập: có ô ghi nhớ và nút xem/ẩn mật khẩu', (tester) async {
    final api = ApiClient();
    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider(
        create: (_) => AuthController(api, _FakeRepo(api), SessionStore()),
        child: const LoginScreen(),
      ),
    ));

    expect(find.text('Ghi nhớ đăng nhập'), findsOneWidget);
    expect(tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value, isFalse);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    expect(tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value, isTrue);

    bool obscured() => tester
        .widget<EditableText>(find.descendant(
            of: find.widgetWithText(TextFormField, 'Mật khẩu'), matching: find.byType(EditableText)))
        .obscureText;
    expect(obscured(), isTrue);
    await tester.tap(find.byIcon(LucideIcons.eye));
    await tester.pump();
    expect(obscured(), isFalse);
  });
}
