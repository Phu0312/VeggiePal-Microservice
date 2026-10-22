import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:VeggiePal/core/storage/session_store.dart';
import 'package:VeggiePal/features/auth/data/auth_models.dart';

String _jwt(int expSeconds) {
  String b64(Map m) => base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${b64({'alg': 'HS256'})}.${b64({'exp': expSeconds})}.sig';
}

int _inSeconds(Duration d) => DateTime.now().add(d).millisecondsSinceEpoch ~/ 1000;

void main() {
  const user = AuthUser(
      id: 7, email: 'a@b.c', fullName: 'An', role: UserRole.admin, avatarUrl: 'http://x/a.png');

  test('Phiên còn hạn được lưu rồi khôi phục đầy đủ thông tin', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final store = SessionStore();
    final token = _jwt(_inSeconds(const Duration(hours: 1)));
    await store.save(AuthSession(token, user));

    final s = await store.load();
    expect(s, isNotNull);
    expect(s!.token, token);
    expect(s.user.id, 7);
    expect(s.user.role, UserRole.admin);
    expect(s.user.avatarUrl, 'http://x/a.png');
  });

  test('Token đã hết hạn thì bị bỏ khi khôi phục (phải đăng nhập lại)', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final store = SessionStore();
    await store.save(AuthSession(_jwt(_inSeconds(const Duration(minutes: -5))), user));

    expect(await store.load(), isNull);
    expect(await store.load(), isNull); // đã bị xoá khỏi kho
  });

  test('Xoá phiên khi đăng xuất', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final store = SessionStore();
    await store.save(AuthSession(_jwt(_inSeconds(const Duration(hours: 1))), user));
    await store.clear();
    expect(await store.load(), isNull);
  });

  test('isJwtExpired', () {
    expect(SessionStore.isJwtExpired(_jwt(_inSeconds(const Duration(hours: 1)))), isFalse);
    expect(SessionStore.isJwtExpired(_jwt(_inSeconds(const Duration(seconds: -1)))), isTrue);
    expect(SessionStore.isJwtExpired('khong-phai-jwt'), isTrue);
  });
}
