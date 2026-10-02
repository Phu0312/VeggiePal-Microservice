import '../../../core/constants/endpoints.dart';
import '../../../core/network/api_client.dart';
import 'auth_models.dart';

class AuthRepository {
  final ApiClient _api;
  AuthRepository(this._api);

  /// POST /auth/login. Mọi lỗi (sai mật khẩu, không kết nối được máy chủ...) được ném lại cho UI.
  Future<AuthSession> login(String email, String password) async {
    final dynamic r;
    try {
      r = await _api.post(Endpoints.login, body: {'email': email.trim(), 'password': password});
    } on ApiException catch (e) {
      // BE trả UNAUTHENTICATED (1008) cho cả sai email lẫn sai mật khẩu.
      if (e.code == 1008) {
        throw ApiException('Email hoặc mật khẩu không đúng.', code: e.code, statusCode: e.statusCode);
      }
      rethrow;
    }
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
