import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/network/api_client.dart';

/// Nguồn Google ID token cho "Tiếp tục với Google"; tách ra để test không cần Google thật.
abstract class GoogleIdTokenSource {
  /// Đã cấu hình `GOOGLE_CLIENT_ID` trong `.env` chưa.
  bool get isConfigured;

  /// Mở màn chọn tài khoản Google và trả về ID token để gửi cho `POST /auth/google`.
  /// Trả về null nếu người dùng tự đóng màn chọn tài khoản; lỗi khác được ném dạng [ApiException].
  Future<String?> idToken();
}

/// Dùng google_sign_in. `GOOGLE_CLIENT_ID` phải là OAuth *Web* client ID, đúng bằng `GOOGLE_CLIENT_ID` của
/// identity-service: backend chỉ nhận ID token có audience trùng giá trị này. Trên Android cần thêm một OAuth
/// client loại Android (package `com.veggiepal.mobile` + SHA-1 của khoá ký) trong cùng dự án Google Cloud;
/// trên iOS cần `GOOGLE_IOS_CLIENT_ID` và URL scheme tương ứng trong Info.plist.
class GoogleSignInSource implements GoogleIdTokenSource {
  GoogleSignInSource();

  Future<void>? _initialized;

  static String? _env(String key) {
    final v = dotenv.maybeGet(key)?.trim();
    return v == null || v.isEmpty ? null : v;
  }

  @override
  bool get isConfigured => _env('GOOGLE_CLIENT_ID') != null;

  Future<void> _init() => _initialized ??= GoogleSignIn.instance.initialize(
        serverClientId: _env('GOOGLE_CLIENT_ID'),
        clientId: _env('GOOGLE_IOS_CLIENT_ID'),
      );

  @override
  Future<String?> idToken() async {
    if (!isConfigured) {
      throw ApiException('Chưa cấu hình đăng nhập Google (thiếu GOOGLE_CLIENT_ID trong .env).');
    }
    try {
      await _init();
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        throw ApiException('Thiết bị này chưa hỗ trợ đăng nhập bằng Google.');
      }
      final account = await GoogleSignIn.instance.authenticate();
      final token = account.authentication.idToken;
      if (token == null || token.isEmpty) {
        throw ApiException('Không nhận được thông tin từ Google. Vui lòng thử lại.');
      }
      // Chỉ cần ID token cho backend; đăng xuất khỏi Google để lần sau luôn hiện màn chọn tài khoản.
      await GoogleSignIn.instance.signOut();
      return token;
    } on GoogleSignInException catch (e) {
      return googleErrorToResult(e.code);
    }
  }
}

/// Đổi mã lỗi của google_sign_in: người dùng tự đóng thì trả null (không phải lỗi), còn lại ném thông báo tiếng Việt.
String? googleErrorToResult(GoogleSignInExceptionCode code) {
  switch (code) {
    case GoogleSignInExceptionCode.canceled:
    case GoogleSignInExceptionCode.interrupted:
      return null;
    case GoogleSignInExceptionCode.clientConfigurationError:
    case GoogleSignInExceptionCode.providerConfigurationError:
      throw ApiException(
          'Cấu hình đăng nhập Google chưa đúng (OAuth client, package name hoặc SHA-1). Vui lòng liên hệ quản trị viên.');
    case GoogleSignInExceptionCode.uiUnavailable:
      throw ApiException('Không mở được màn chọn tài khoản Google. Vui lòng thử lại.');
    default:
      throw ApiException('Đăng nhập bằng Google thất bại. Vui lòng thử lại.');
  }
}
