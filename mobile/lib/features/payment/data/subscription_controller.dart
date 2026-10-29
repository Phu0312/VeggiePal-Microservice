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
  bool loading = false;
  String? error;

  /// Gọi khi đăng nhập / đăng xuất (từ ProxyProvider). Quản trị viên không dùng gói nên không tải.
  void bindUser(int? userId) {
    if (userId == _userId) return;
    _userId = userId;
    subscription = null;
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
}
