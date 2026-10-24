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
      // Token đã hết hạn thì bỏ luôn, không cần chờ BE từ chối.
      if (isJwtExpired(token)) {
        await clear();
        return null;
      }
      return AuthSession(token, AuthUser.fromStored(Map<String, dynamic>.from(m['user'] as Map)));
    } catch (_) {
      return null;
    }
  }

  Future<void> save(AuthSession s) async {
    try {
      await _storage.write(
          key: _key, value: jsonEncode({'token': s.token, 'user': s.user.toJson()}));
    } catch (_) {}
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {}
  }

  /// Đọc claim `exp` (giây) của JWT; token không đọc được thì coi như đã hết hạn.
  static bool isJwtExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final exp = (jsonDecode(payload) as Map)['exp'];
      if (exp is! num) return false; // không có exp: để BE quyết định
      return DateTime.now().millisecondsSinceEpoch >= exp.toInt() * 1000;
    } catch (_) {
      return true;
    }
  }
}
