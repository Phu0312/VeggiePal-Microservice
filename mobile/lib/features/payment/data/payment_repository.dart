import '../../../core/constants/endpoints.dart';
import '../../../core/network/api_client.dart';
import 'payment_models.dart';

/// Mã lỗi của payment-service nằm trong dải 7000-7009 (trước đây là 6000-6009, trùng dải với ai-service). Bảng này
/// chỉ dịch riêng mã payment; mã 6xxx của ai-service (ví dụ 6003 hết lượt AI) không được dịch ở đây.
const paymentErrorMessages = {
  7000: 'Vui lòng chọn gói thành viên.',
  7001: 'Gói không tồn tại.',
  7002: 'Gói này không thể mua.',
  7003: 'Không tìm thấy đơn hàng.',
  7004: 'Cổng thanh toán đang bận, vui lòng thử lại sau.',
  7005: 'Chữ ký thanh toán không hợp lệ.',
  7006: 'Số tiền thanh toán không khớp với đơn hàng.',
  7007: 'Thanh toán không thành công.',
  7008: 'Đơn hàng này không thể huỷ.',
  7009: 'Chưa huỷ được đơn, vui lòng thử lại.',
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

  // GET /ai/quotas/me (ai-service): lượt chat / thực đơn / video đã dùng và còn lại trong kỳ. Không qua _guard vì
  // mã lỗi của ai-service khác bảng của payment-service.
  Future<QuotaOverview> myQuotas() async {
    _requireLogin();
    final r = await _api.get(Endpoints.myQuotas);
    return QuotaOverview.fromJson(Map<String, dynamic>.from(r as Map));
  }

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

  // POST /payments/orders/{id}/cancel : chỉ huỷ được đơn PENDING (7008 nếu đã thanh toán).
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
