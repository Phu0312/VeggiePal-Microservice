import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:VeggiePal/core/constants/endpoints.dart';
import 'package:VeggiePal/core/network/api_client.dart';
import 'package:VeggiePal/core/storage/session_store.dart';
import 'package:VeggiePal/features/admin/data/admin_models.dart';
import 'package:VeggiePal/features/admin/data/admin_repository.dart';
import 'package:VeggiePal/features/admin/presentation/admin_users_tab.dart';
import 'package:VeggiePal/features/auth/data/auth_models.dart';
import 'package:VeggiePal/features/auth/data/auth_repository.dart';
import 'package:VeggiePal/features/auth/presentation/auth_controller.dart';
import 'support/filter_dropdown.dart';

/// ApiClient giả: ghi lại GET / PATCH, trả kết quả theo đường dẫn, không đụng tới mạng.
class _FakeApi extends ApiClient {
  final gets = <Map<String, dynamic>?>[];
  final patches = <String, Object?>{};
  final results = <String, Object?>{};
  final patchResults = <String, Object?>{};
  Object? patchError;

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    if (path == Endpoints.adminUsers) gets.add(query);
    return results[path];
  }

  @override
  Future<dynamic> patch(String path, {Object? body}) async {
    patches[path] = body;
    final e = patchError;
    if (e != null) {
      patchError = null;
      throw e;
    }
    return patchResults[path];
  }
}

Map<String, dynamic> _user(int id, String name,
        {String role = 'USER', String status = 'ACTIVE', bool verified = true, String? phone}) =>
    {
      'id': id,
      'email': '${name.toLowerCase().replaceAll(' ', '')}@gmail.com',
      'fullName': name,
      'phone': phone,
      'role': role,
      'status': status,
      'emailVerified': verified,
      'createdAt': '2026-10-20T08:30:00',
    };

Map<String, dynamic> _page(List<Map<String, dynamic>> items) =>
    {'content': items, 'items': items, 'page': 0, 'size': 20, 'totalElements': items.length, 'totalPages': 1};

void main() {
  setUp(() {
    dotenv.loadFromString(envString: 'APP=test');
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('AdminUser đọc vai trò, trạng thái và nhãn tiếng Việt', () {
    final u = AdminUser.fromJson(_user(3, 'Bình', status: 'BLOCKED', role: 'ADMIN', verified: false));
    expect(u.isAdmin, isTrue);
    expect(u.isBlocked, isTrue);
    expect(u.statusLabel, 'Bị khóa');
    expect(u.roleLabel, 'Quản trị viên');
    expect(u.emailVerified, isFalse);
    expect(u.createdAt, isNotNull);
    expect(AdminUser.fromJson({'id': 1, 'email': 'a@b.c', 'fullName': ' '}).displayName, 'a@b.c');
  });

  group('AdminRepository', () {
    test('users chỉ gửi bộ lọc đã chọn', () async {
      final api = _FakeApi()..results[Endpoints.adminUsers] = _page([_user(2, 'An')]);
      final repo = AdminRepository(api);

      final p = await repo.users();
      expect(p.items.single.fullName, 'An');
      expect(api.gets.last, {'page': 0, 'size': 20});

      await repo.users(keyword: 'an', role: 'ADMIN', status: 'BLOCKED', page: 2);
      expect(api.gets.last, {'keyword': 'an', 'role': 'ADMIN', 'status': 'BLOCKED', 'page': 2, 'size': 20});
    });

    test('đổi trạng thái và vai trò dùng PATCH, trả về tài khoản đã cập nhật', () async {
      final api = _FakeApi()
        ..patchResults[Endpoints.adminUserStatus(2)] = _user(2, 'An', status: 'BLOCKED')
        ..patchResults[Endpoints.adminUserRole(2)] = _user(2, 'An', role: 'ADMIN');
      final repo = AdminRepository(api);

      expect((await repo.setUserStatus(2, 'BLOCKED')).isBlocked, isTrue);
      expect(api.patches[Endpoints.adminUserStatus(2)], {'status': 'BLOCKED'});
      expect((await repo.setUserRole(2, 'ADMIN')).isAdmin, isTrue);
      expect(api.patches[Endpoints.adminUserRole(2)], {'role': 'ADMIN'});
    });
  });

  group('AdminUsersTab', () {
    late _FakeApi api;

    Future<void> boot(WidgetTester tester) async {
      api = _FakeApi()
        ..results[Endpoints.adminUsers] = _page([
          _user(1, 'Quản Trị', role: 'ADMIN'),
          _user(2, 'An Nguyễn', verified: false, phone: '0901234567'),
          _user(3, 'Bình', status: 'BLOCKED'),
        ]);
      final auth = AuthController(
          api,
          AuthRepository(api),
          SessionStore(),
          initial: const AuthSession(
              't', AuthUser(id: 1, email: 'quantri@gmail.com', fullName: 'Quản Trị', role: UserRole.admin)));
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<AdminRepository>.value(value: AdminRepository(api)),
          ChangeNotifierProvider<AuthController>.value(value: auth),
        ],
        child: const MaterialApp(home: Scaffold(body: AdminUsersTab())),
      ));
      await tester.pumpAndSettle();
    }

    Finder inDialog(Finder f) => find.descendant(of: find.byType(AlertDialog), matching: f);

    testWidgets('hiện danh sách với vai trò, trạng thái và email chưa xác minh', (tester) async {
      await boot(tester);
      expect(find.text('Quản Trị'), findsOneWidget);
      expect(find.text('An Nguyễn'), findsOneWidget);
      expect(find.text('Quản trị viên'), findsOneWidget); // badge (ô lọc chỉ hiện "Mọi vai trò")
      expect(find.text('Bị khóa'), findsOneWidget); // badge của Bình
      expect(find.text('Chưa xác minh email'), findsOneWidget);
    });

    testWidgets('tìm kiếm và chip lọc gửi đúng tham số lên BE', (tester) async {
      await boot(tester);

      await tester.enterText(find.byType(SearchBar), ' an ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(api.gets.last?['keyword'], 'an');

      await pickFilter(tester, 'Mọi vai trò', 'Quản trị viên');
      await tester.pumpAndSettle();
      expect(api.gets.last?['role'], 'ADMIN');
      expect(api.gets.last?['keyword'], 'an');

      await pickFilter(tester, 'Mọi trạng thái', 'Bị khóa');
      await tester.pumpAndSettle();
      expect(api.gets.last?['status'], 'BLOCKED');

      await pickFilter(tester, 'Bị khóa', 'Mọi trạng thái');
      await tester.pumpAndSettle();
      expect(api.gets.last?.containsKey('status'), isFalse);
    });

    testWidgets('khóa tài khoản: xác nhận rồi PATCH, dòng đó chuyển sang "Bị khóa"', (tester) async {
      await boot(tester);
      api.patchResults[Endpoints.adminUserStatus(2)] = _user(2, 'An Nguyễn', status: 'BLOCKED', verified: false);

      await tester.tap(find.text('An Nguyễn'));
      await tester.pumpAndSettle();
      expect(find.text('0901234567'), findsOneWidget); // chi tiết
      expect(find.text('Mở khóa tài khoản'), findsNothing);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Khóa tài khoản'));
      await tester.pumpAndSettle();
      await tester.tap(inDialog(find.widgetWithText(FilledButton, 'Khóa')));
      await tester.pumpAndSettle();

      expect(api.patches[Endpoints.adminUserStatus(2)], {'status': 'BLOCKED'});
      expect(find.text('Bị khóa'), findsNWidgets(2)); // Bình và An Nguyễn
    });

    testWidgets('hủy ở hộp xác nhận thì không gọi BE', (tester) async {
      await boot(tester);
      await tester.tap(find.text('An Nguyễn'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cấp quyền quản trị'));
      await tester.pumpAndSettle();
      await tester.tap(inDialog(find.text('Hủy')));
      await tester.pumpAndSettle();
      expect(api.patches, isEmpty);
    });

    testWidgets('cấp quyền quản trị gọi PATCH role=ADMIN và hiện badge', (tester) async {
      await boot(tester);
      api.patchResults[Endpoints.adminUserRole(2)] = _user(2, 'An Nguyễn', role: 'ADMIN', verified: false);
      await tester.tap(find.text('An Nguyễn'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cấp quyền quản trị'));
      await tester.pumpAndSettle();
      await tester.tap(inDialog(find.widgetWithText(FilledButton, 'Cấp quyền')));
      await tester.pumpAndSettle();

      expect(api.patches[Endpoints.adminUserRole(2)], {'role': 'ADMIN'});
      expect(find.text('Quản trị viên'), findsNWidgets(2)); // Quản Trị và An Nguyễn
    });

    testWidgets('tài khoản đang bị khóa chỉ có "Mở khóa", không có "Khóa"', (tester) async {
      await boot(tester);
      api.patchResults[Endpoints.adminUserStatus(3)] = _user(3, 'Bình');
      await tester.tap(find.text('Bình'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(OutlinedButton, 'Khóa tài khoản'), findsNothing);
      await tester.tap(find.widgetWithText(FilledButton, 'Mở khóa tài khoản'));
      await tester.pumpAndSettle();
      await tester.tap(inDialog(find.widgetWithText(FilledButton, 'Mở khóa')));
      await tester.pumpAndSettle();

      expect(api.patches[Endpoints.adminUserStatus(3)], {'status': 'ACTIVE'});
      expect(find.text('Bị khóa'), findsNothing); // không còn tài khoản nào bị khóa
    });

    testWidgets('tài khoản của chính admin không có thao tác khóa / đổi quyền', (tester) async {
      await boot(tester);
      await tester.tap(find.text('Quản Trị'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Đây là tài khoản của bạn'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Khóa tài khoản'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Gỡ quyền quản trị'), findsNothing);
    });

    testWidgets('đã được admin khác đổi vai trò (1023): báo lỗi rồi tải lại danh sách', (tester) async {
      await boot(tester);
      final before = api.gets.length;
      api.patchError = ApiException('Tài khoản đã có vai trò này.', code: 1023, statusCode: 400);
      await tester.tap(find.text('An Nguyễn'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cấp quyền quản trị'));
      await tester.pumpAndSettle();
      await tester.tap(inDialog(find.widgetWithText(FilledButton, 'Cấp quyền')));
      await tester.pumpAndSettle();

      expect(find.text('Tài khoản đã có vai trò này.'), findsOneWidget);
      expect(api.gets.length, before + 1);
    });
  });
}
