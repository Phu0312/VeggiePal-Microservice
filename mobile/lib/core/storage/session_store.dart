import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/data/auth_models.dart';

/// Lưu phiên đăng nhập (JWT + thông tin người dùng) vào kho mã hoá của hệ điều hành
/// (Keystore trên Android, Keychain trên iOS) để lần mở app sau không phải đăng nhập lại.
/// Mọi thao tác đều nuốt lỗi lưu trữ: không đọc/ghi được thì app chỉ đơn giản yêu cầu đăng nhập lại.
class SessionStore {
  SessionStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'auth_session';
  final FlutterSecureStorage _storage;

  Future<AuthSession?> load() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null) return null;
      final m = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final token = '${m['token']}';
      final refresh = m['refreshToken'];
      final refreshToken = refresh is String && refresh.isNotEmpty ? refresh : null;
      // Access token đã hết hạn mà không có refresh token thì bỏ luôn, không cần chờ BE từ chối.
      // Có refresh token thì giữ phiên: ApiClient tự đổi token mới ở request đầu tiên.
      if (refreshToken == null && isJwtExpired(token)) {
        await clear();
        return null;
      }
      return AuthSession(token, AuthUser.fromStored(Map<String, dynamic>.from(m['user'] as Map)),
          refreshToken: refreshToken);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(AuthSession s) async {
    try {
      await _storage.write(
          key: _key,
          value: jsonEncode({'token': s.token, 'refreshToken': s.refreshToken, 'user': s.user.toJson()}));
    } catch (_) {}
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {}
  }

  /// Đọc claim `exp` (giây) của JWT; token không đọc được thì coi như đã hết hạn.
  /// [leeway] > 0 coi token là hết hạn sớm hơn chừng đó, để làm mới trước khi nó chết giữa đường.
  static bool isJwtExpired(String token, {Duration leeway = Duration.zero}) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final exp = (jsonDecode(payload) as Map)['exp'];
      if (exp is! num) return false; // không có exp: để BE quyết định
      return DateTime.now().add(leeway).millisecondsSinceEpoch >= exp.toInt() * 1000;
    } catch (_) {
      return true;
    }
  }
}
