import '../../../core/constants/endpoints.dart';
import '../../../core/network/api_client.dart';
import 'menu_models.dart';

/// Mã lỗi backend "chưa có chỉ số sức khỏe nào" (ErrorCode.HEALTH_RECORD_NOT_EXISTED) - không phải lỗi thật.
const _healthRecordNotExistedCode = 2005;

/// Nutrition-service: chỉ số sức khỏe (cần JWT). Thực đơn tuần nằm ở [MealPlanRepository].
/// Mọi lỗi từ backend được ném lại cho UI hiển thị popup.
class MenuRepository {
  final ApiClient _api;
  MenuRepository(this._api);

  bool get _hasToken => _api.token != null;

  // GET /nutrition/me/health-records/latest
  Future<HealthInfo?> latestHealth() async {
    if (!_hasToken) return null;
    try {
      final r = await _api.get(Endpoints.healthRecordLatest);
      if (r == null) return null;
      return HealthInfo.fromJson(Map<String, dynamic>.from(r as Map));
    } on ApiException catch (e) {
      if (e.code == _healthRecordNotExistedCode) return null;
      rethrow;
    }
  }

  // POST /nutrition/me/health-records {heightCm, weightKg}; BMI do server tính.
  // Khách (chưa đăng nhập) chỉ tính BMI trên máy, không lưu lên server.
  Future<HealthInfo> saveHealth(double h, double w) async {
    if (!_hasToken) return HealthInfo(h, w, HealthInfo.computeBmi(h, w));
    final r = await _api.post(Endpoints.healthRecords, body: {'heightCm': h, 'weightKg': w});
    return HealthInfo.fromJson(Map<String, dynamic>.from(r as Map));
  }
}
