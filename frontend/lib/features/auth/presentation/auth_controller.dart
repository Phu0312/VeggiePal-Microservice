import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../data/auth_models.dart';
import '../data/auth_repository.dart';

/// Trạng thái xác thực toàn app. Mọi màn hình đọc [role] để ẩn/hiện chức năng
/// (Guest: chỉ xem/tìm kiếm; User: đăng bài, lưu thực đơn, chat không giới hạn; Admin: thêm dashboard).
class AuthController extends ChangeNotifier {
  AuthController(this._api, this._repo);

  final ApiClient _api;
  final AuthRepository _repo;

  AuthSession? _session;

  UserRole get role => _session?.user.role ?? UserRole.guest;
  AuthUser? get user => _session?.user;
  bool get isLoggedIn => _session != null;
  bool get isAdmin => role == UserRole.admin;

  /// True khi đang ở phiên demo (không có JWT thật) -> repository sẽ dùng mock.
  bool get isDemo => _session != null && _session!.token == null;

  void _apply(AuthSession? s) {
    _session = s;
    _api.token = s?.token; // ApiClient tự gắn Bearer token vào mọi request sau đó
    notifyListeners();
  }

  Future<void> login(String email, String password) async =>
      _apply(await _repo.login(email, password));

  Future<void> register(
          String email, String password, String name, String phone) async =>
      _apply(await _repo.register(email, password, name, phone));

  void logout() => _apply(null);

  /// Role Switcher trên Top Bar: chuyển nhanh để test giao diện.
  void switchRole(UserRole target) {
    if (target == role) return;
    _apply(target == UserRole.guest ? null : _repo.demoSession(target));
  }
}
