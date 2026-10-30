import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import 'payment_models.dart';
import 'payment_repository.dart';

/// Gói thành viên hiện tại của người dùng (GET /subscriptions/me), dùng chung cho màn gói, chatbot và các
/// chỗ hiển thị hạn mức. Đặt ở Provider để mọi màn cùng thấy gói mới ngay sau khi thanh toán.
class SubscriptionController extends ChangeNotifier {
  SubscriptionController(this._repo);

  final PaymentRepository _repo;

  int? _userId;
  Subscription? subscription;

  /// Lượt đã dùng / còn lại (GET /ai/quotas/me). Null khi chưa tải được: giao diện chỉ hiện hạn mức của gói.
  QuotaOverview? quota;
  bool loading = false;
  String? error;

  /// Gọi khi đăng nhập / đăng xuất (từ ProxyProvider). Quản trị viên không dùng gói nên không tải.
  void bindUser(int? userId) {
    if (userId == _userId) return;
    _userId = userId;
    subscription = null;
    quota = null;
    error = null;
    loading = false;
    // Được gọi từ ProxyProvider.update (đang trong build) nên hoãn thông báo sang microtask.
    Future.microtask(notifyListeners);
    if (userId != null) Future.microtask(refresh);
  }

  /// Tải lại gói hiện tại; trả về thông báo lỗi nếu thất bại (null = thành công).
  Future<String?> refresh() async {
    final user = _userId;
    if (user == null) return null;
    loading = true;
    notifyListeners();
    try {
      final s = await _repo.mySubscription();
      if (user != _userId) return null;
      subscription = s;
      error = null;
      _loadQuota(user); // phần phụ: lỗi không làm hỏng thông tin gói
    } catch (e) {
      if (user != _userId) return null;
      error = errorMessage(e);
    } finally {
      if (user == _userId) {
        loading = false;
        notifyListeners();
      }
    }
    return error;
  }

  /// Tải lại lượt đã dùng sau khi người dùng vừa dùng một tính năng AI. Lỗi bị bỏ qua.
  Future<void> refreshQuota() async {
    final user = _userId;
    if (user != null) await _loadQuota(user);
  }

  Future<void> _loadQuota(int user) async {
    try {
      final q = await _repo.myQuotas();
      if (user != _userId) return;
      quota = q;
      notifyListeners();
    } catch (_) {}
  }
}
