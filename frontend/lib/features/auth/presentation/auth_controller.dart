import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/session_store.dart';
import '../data/auth_models.dart';
import '../data/auth_repository.dart';

/// Trạng thái xác thực toàn app. Mọi màn hình đọc [role] để ẩn/hiện chức năng
/// (Guest: chỉ xem/tìm kiếm; User: đăng bài, lưu thực đơn, chat không giới hạn; Admin: thêm dashboard).
class AuthController extends ChangeNotifier {
  /// [initial] là phiên khôi phục từ [SessionStore] khi mở app; [onSessionExpired] được gọi
  /// sau khi BE từ chối token (hết hạn) và app đã tự đăng xuất.
  AuthController(this._api, this._repo, this._store,
      {AuthSession? initial, this.onSessionExpired})
      : _session = initial,
        _remember = initial != null {
    _api.token = initial?.token;
    _api.onSessionExpired = _handleExpired;
    if (initial != null) _loadProfile(); // đồng thời kiểm tra token còn hiệu lực phía BE
  }

  final ApiClient _api;
  final AuthRepository _repo;
  final SessionStore _store;
  final VoidCallback? onSessionExpired;

  AuthSession? _session;

  /// Có lưu phiên vào máy hay không (người dùng tick "Ghi nhớ đăng nhập").
  /// Phiên khôi phục từ bộ nhớ luôn là phiên đã được ghi nhớ.
  bool _remember;

  UserRole get role => _session?.user.role ?? UserRole.guest;
  AuthUser? get user => _session?.user;
  bool get isLoggedIn => _session != null;
  bool get isAdmin => role == UserRole.admin;

  void _apply(AuthSession? s, {bool remember = false}) {
    _session = s;
    _remember = s != null && remember;
    _api.token = s?.token; // ApiClient tự gắn Bearer token vào mọi request sau đó
    notifyListeners();
    // Không ghi nhớ (hoặc đăng xuất) thì xoá mọi phiên đã lưu từ trước.
    if (s != null && remember) {
      _store.save(s);
    } else {
      _store.clear();
    }
    if (s != null) _loadProfile();
  }

  /// BE báo token hết hạn/không hợp lệ: đăng xuất ngay và báo cho người dùng.
  void _handleExpired() {
    if (_session == null) return;
    _apply(null);
    onSessionExpired?.call();
  }

  /// Nạp ảnh đại diện/họ tên mới nhất từ GET /users/me. Chỉ là phần hiển thị phụ
  /// nên lỗi được bỏ qua (header sẽ dùng chữ cái đầu thay cho ảnh).
  Future<void> _loadProfile() async {
    final token = _session?.token;
    try {
      final p = await _repo.profile();
      if (_session?.token != token) return; // đã đăng xuất/đổi tài khoản trong lúc chờ
      updateUser(fullName: p['fullName'] as String?, avatarUrl: p['avatarUrl'] as String?);
    } catch (_) {}
  }

  /// Cập nhật thông tin hiển thị của người dùng hiện tại (sau khi sửa hồ sơ/đổi avatar).
  void updateUser({String? fullName, String? avatarUrl}) {
    final s = _session;
    if (s == null) return;
    _session = AuthSession(s.token, s.user.copyWith(fullName: fullName, avatarUrl: avatarUrl));
    if (_remember) _store.save(_session!);
    notifyListeners();
  }

  /// [remember] = true thì lưu phiên để lần mở app sau không phải đăng nhập lại.
  Future<void> login(String email, String password, {bool remember = false}) async =>
      _apply(await _repo.login(email, password), remember: remember);

  Future<void> register(String email, String password, String name, String phone,
          {bool remember = false}) async =>
      _apply(await _repo.register(email, password, name, phone), remember: remember);

  void logout() => _apply(null);
}
