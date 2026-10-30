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
    return AuthSession.fromLogin(Map<String, dynamic>.from(r as Map));
  }

  /// POST /auth/google {idToken}: backend tự kiểm tra ID token, liên kết với tài khoản cùng email
  /// (chưa có thì tạo mới, vai trò USER) và trả cùng dạng phản hồi như /auth/login.
  Future<AuthSession> loginWithGoogle(String idToken) async {
    final r = await _api.post(Endpoints.googleLogin, body: {'idToken': idToken});
    return AuthSession.fromLogin(Map<String, dynamic>.from(r as Map));
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

  /// POST /auth/forgot-password: gửi mã 6 số tới email. BE luôn báo thành công, kể cả khi email chưa đăng ký.
  Future<OtpSent> forgotPassword(String email) async {
    final r = await _api.post(Endpoints.forgotPassword, body: {'email': email.trim()});
    return OtpSent.fromJson(Map<String, dynamic>.from(r as Map));
  }

  /// POST /auth/verify-otp: đổi mã 6 số lấy `resetToken` dùng một lần cho [resetPassword].
  Future<String> verifyResetOtp(String email, String otp) async {
    final r = await _api.post(Endpoints.verifyOtp, body: {'email': email.trim(), 'otp': otp.trim()});
    return '${(r as Map)['resetToken']}';
  }

  /// POST /auth/reset-password: đặt mật khẩu mới. BE thu hồi mọi phiên đăng nhập cũ của tài khoản.
  Future<void> resetPassword(String resetToken, String newPassword) =>
      _api.post(Endpoints.resetPassword, body: {'resetToken': resetToken, 'newPassword': newPassword});

  /// POST /auth/send-verification: gửi (hoặc gửi lại) mã xác minh email. Endpoint công khai nên phải gửi kèm email.
  Future<OtpSent> sendVerification(String email) async {
    final r = await _api.post(Endpoints.sendVerification, body: {'email': email.trim()});
    return OtpSent.fromJson(Map<String, dynamic>.from(r as Map));
  }

  /// POST /auth/verify-email.
  Future<void> verifyEmail(String email, String otp) =>
      _api.post(Endpoints.verifyEmail, body: {'email': email.trim(), 'otp': otp.trim()});

  /// POST /auth/refresh: đổi refresh token lấy access token mới. BE xoay vòng, refresh token cũ hết hiệu lực.
  Future<AuthSession> refresh(String refreshToken) async {
    final r = await _api.post(Endpoints.refreshToken, body: {'refreshToken': refreshToken});
    return AuthSession.fromLogin(Map<String, dynamic>.from(r as Map));
  }

  /// POST /auth/logout: thu hồi refresh token. Lỗi (mất mạng, token đã hết hạn) bị bỏ qua vì app đã đăng xuất cục bộ.
  Future<void> logout(String refreshToken) async {
    try {
      await _api.post(Endpoints.logout, body: {'refreshToken': refreshToken});
    } catch (_) {}
  }
}
