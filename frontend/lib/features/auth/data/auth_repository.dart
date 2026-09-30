import '../../../core/constants/endpoints.dart';
import '../../../core/network/api_client.dart';
import 'auth_models.dart';

class AuthRepository {
  final ApiClient _api;
  AuthRepository(this._api);

  /// POST /auth/login. Nếu server chưa bật (lỗi mạng) -> Mock Fallback: tạo phiên demo
  /// (email chứa "admin" => ADMIN) để vẫn xem được giao diện. Lỗi nghiệp vụ (sai mật khẩu)
  /// thì KHÔNG fallback, ném lại cho UI hiển thị.
  Future<AuthSession> login(String email, String password) async {
    try {
      final r = await _api.post(Endpoints.login,
          body: {'email': email.trim(), 'password': password});
      final m = Map<String, dynamic>.from(r as Map);
      return AuthSession('${m['accessToken']}', AuthUser.fromLogin(m));
    } on ApiException catch (e) {
      if (!e.isNetwork) rethrow;
      return AuthSession(null, _mockUser(email));
    }
  }

  /// POST /auth/register rồi tự đăng nhập.
  Future<AuthSession> register(
      String email, String password, String fullName, String phone) async {
    try {
      await _api.post(Endpoints.register, body: {
        'email': email.trim(),
        'password': password,
        'fullName': fullName,
        'phone': phone,
      });
      return await login(email, password);
    } on ApiException catch (e) {
      if (!e.isNetwork) rethrow;
      return AuthSession(null, _mockUser(email, name: fullName));
    }
  }

  AuthUser _mockUser(String email, {String? name}) {
    final admin = email.toLowerCase().contains('admin');
    return AuthUser(
      id: admin ? 1 : 2,
      email: email,
      fullName: name ?? (admin ? 'Quản trị viên' : 'Thành viên VeggiePal'),
      role: admin ? UserRole.admin : UserRole.user,
    );
  }

  /// Phiên demo cho Role Switcher (không cần server).
  AuthSession demoSession(UserRole role) => AuthSession(
      null,
      role == UserRole.admin
          ? _mockUser('admin@veggiepal.com')
          : _mockUser('user@veggiepal.com'));
}
