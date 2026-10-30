import '../../../core/constants/endpoints.dart';
import '../../../core/network/api_client.dart';
import 'payment_models.dart';

/// Mã lỗi của payment-service nằm trong dải 6000-6009, trùng dải với ai-service nên không dùng chung bảng thông báo
/// toàn app mà dịch riêng tại đây.
const paymentErrorMessages = {
  6000: 'Vui lòng chọn gói thành viên.',
  6001: 'Gói không tồn tại.',
  6002: 'Gói này không thể mua.',
  6003: 'Không tìm thấy đơn hàng.',
  6004: 'Cổng thanh toán đang bận, vui lòng thử lại sau.',
  6005: 'Chữ ký thanh toán không hợp lệ.',
  6006: 'Số tiền thanh toán không khớp với đơn hàng.',
  6007: 'Thanh toán không thành công.',
  6008: 'Đơn hàng này không thể huỷ.',
  6009: 'Chưa huỷ được đơn, vui lòng thử lại.',
};

/// payment-service: gói thành viên (công khai) và thanh toán / gói của tôi (cần JWT).
/// Mọi lỗi được ném lại cho UI hiển thị popup.
class PaymentRepository {
  final ApiClient _api;
  PaymentRepository(this._api);

  /// Dịch lỗi theo bảng của payment-service (giữ nguyên mã và HTTP status).
  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on ApiException catch (e) {
      final message = e.code == null ? null : paymentErrorMessages[e.code];
      if (message == null) rethrow;
      throw ApiException(message, code: e.code, statusCode: e.statusCode);
    }
  }

  UserOrder _order(dynamic r) => UserOrder.fromJson(Map<String, dynamic>.from(r as Map));

  void _requireLogin() {
    if (_api.token == null) throw ApiException('Vui lòng đăng nhập để sử dụng chức năng này.');
  }

  // GET /payments/plans (công khai)
  Future<List<Plan>> plans() => _guard(() async {
        final r = await _api.get(Endpoints.paymentPlans);
        return asList(r).map((e) => Plan.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      });

  // GET /subscriptions/me : gói đang hiệu lực (gói hết hạn tự về FREE)
  Future<Subscription> mySubscription() => _guard(() async {
        _requireLogin();
        final r = await _api.get(Endpoints.mySubscription);
        return Subscription.fromJson(Map<String, dynamic>.from(r as Map));
      });

  // POST /payments/checkout {planCode}: tạo đơn và liên kết PayOS; còn đơn PENDING chưa hết hạn của gói này thì dùng lại.
  Future<UserOrder> checkout(String planCode) => _guard(() async {
        _requireLogin();
        return _order(await _api.post(Endpoints.paymentCheckout, body: {'planCode': planCode}));
      });

  // GET /payments/orders/{id}
  Future<UserOrder> order(int id) => _guard(() async {
        _requireLogin();
        return _order(await _api.get(Endpoints.paymentOrder(id)));
      });

  // POST /payments/orders/{id}/cancel : chỉ huỷ được đơn PENDING (6008 nếu đã thanh toán).
  Future<UserOrder> cancel(int id) => _guard(() async {
        _requireLogin();
        return _order(await _api.post(Endpoints.paymentOrderCancel(id)));
      });

  // GET /payments/history : mới nhất trước
  Future<List<UserOrder>> history() => _guard(() async {
        _requireLogin();
        return asList(await _api.get(Endpoints.paymentHistory)).map(_order).toList();
      });
}
