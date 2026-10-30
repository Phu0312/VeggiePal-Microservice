import 'dart:async';

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
    _api.refreshToken = initial?.refreshToken;
    _api.refreshSession = _refresh;
    _api.onSessionExpired = _handleExpired;
    if (initial != null) _loadProfile(); // đồng thời kiểm tra token còn hiệu lực phía BE
  }

  final ApiClient _api;
  final AuthRepository _repo;
  final SessionStore _store;
  final VoidCallback? onSessionExpired;

  AuthSession? _session;

  /// Lần làm mới đang chạy. Nhiều request cùng gặp token hết hạn thì dùng chung một lần gọi, vì BE xoay vòng
  /// refresh token: gọi hai lần với cùng một token thì lần sau bị từ chối và người dùng bị đăng xuất oan.
  Future<bool>? _refreshing;

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
    _api.refreshToken = s?.refreshToken;
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
      updateUser(
          fullName: p['fullName'] as String?,
          avatarUrl: p['avatarUrl'] as String?,
          emailVerified: p['emailVerified'] as bool?);
    } catch (_) {}
  }

  /// Cập nhật thông tin hiển thị của người dùng hiện tại (sau khi sửa hồ sơ/đổi avatar/xác minh email).
  void updateUser({String? fullName, String? avatarUrl, bool? emailVerified}) {
    final s = _session;
    if (s == null) return;
    _session = AuthSession(
        s.token, s.user.copyWith(fullName: fullName, avatarUrl: avatarUrl, emailVerified: emailVerified),
        refreshToken: s.refreshToken);
    if (_remember) _store.save(_session!);
    notifyListeners();
  }

  /// Đổi refresh token lấy access token mới (ApiClient gọi khi token hết hạn hoặc bị từ chối).
  /// `true` = đã có token mới. BE từ chối (refresh token hết hạn, bị thu hồi, tài khoản bị khóa) thì đăng xuất;
  /// lỗi mạng thì giữ phiên để lần sau thử lại.
  Future<bool> _refresh() => _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  Future<bool> _doRefresh() async {
    final s = _session;
    final rt = s?.refreshToken;
    if (s == null || rt == null) return false;
    try {
      final fresh = await _repo.refresh(rt);
      if (_session?.refreshToken != rt) return false; // đã đăng xuất/đổi tài khoản trong lúc chờ
      // Giữ ảnh đại diện và trạng thái email; họ tên và vai trò lấy theo BE vì có thể đã đổi.
      final user = s.user.copyWith(fullName: fresh.user.fullName, role: fresh.user.role);
      _session = AuthSession(fresh.token, user, refreshToken: fresh.refreshToken ?? rt);
      _api.token = _session!.token;
      _api.refreshToken = _session!.refreshToken;
      if (_remember) _store.save(_session!);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      final rejected = e.statusCode == 401 || e.code == 1030 || e.code == 1021;
      if (rejected && _session?.refreshToken == rt) _handleExpired();
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Gửi (hoặc gửi lại) mã xác minh tới email của tài khoản đang đăng nhập.
  Future<OtpSent> sendVerification() => _repo.sendVerification(user!.email);

  /// Xác minh email bằng mã OTP; thành công thì hồ sơ trong app chuyển sang "đã xác minh".
  Future<void> verifyEmail(String otp) async {
    await _repo.verifyEmail(user!.email, otp);
    updateUser(emailVerified: true);
  }

  /// [remember] = true thì lưu phiên để lần mở app sau không phải đăng nhập lại.
  Future<void> login(String email, String password, {bool remember = false}) async =>
      _apply(await _repo.login(email, password), remember: remember);

  /// Đăng nhập bằng ID token của Google. Luồng Google không có ô "Ghi nhớ đăng nhập" nên luôn lưu phiên
  /// (giống bản web).
  Future<void> loginWithGoogle(String idToken, {bool remember = true}) async =>
      _apply(await _repo.loginWithGoogle(idToken), remember: remember);

  Future<void> register(String email, String password, String name, String phone,
          {bool remember = false}) async =>
      _apply(await _repo.register(email, password, name, phone), remember: remember);

  /// Đăng xuất ngay trên máy; refresh token được thu hồi phía BE ở nền (lỗi bị bỏ qua).
  void logout() {
    final rt = _session?.refreshToken;
    _apply(null);
    if (rt != null) unawaited(_repo.logout(rt));
  }
}
