import '../../../core/constants/endpoints.dart';
import '../../../core/network/api_client.dart';
import 'auth_models.dart';

class AuthRepository {
  final ApiClient _api;
  AuthRepository(this._api);

  /// POST /auth/login. Mọi lỗi (sai mật khẩu, không kết nối được máy chủ...) được ném lại cho UI.
  Future<AuthSession> login(String email, String password) async {
    final r = await _api.post(Endpoints.login,
        body: {'email': email.trim(), 'password': password});
    final m = Map<String, dynamic>.from(r as Map);
    return AuthSession('${m['accessToken']}', AuthUser.fromLogin(m));
  }

  // GET /users/me -> thông tin hồ sơ (có avatarUrl).
  Future<Map<String, dynamic>> profile() async {
    final r = await _api.get(Endpoints.me);
    return Map<String, dynamic>.from(r as Map);
  }

  /// POST /auth/register rồi tự đăng nhập.
  Future<AuthSession> register(
      String email, String password, String fullName, String phone) async {
    await _api.post(Endpoints.register, body: {
      'email': email.trim(),
      'password': password,
      'fullName': fullName,
      'phone': phone,
    });
    return login(email, password);
  }
}
