import '../../../core/constants/endpoints.dart';
import '../../../core/network/api_client.dart';
import 'menu_models.dart';

/// Mã lỗi backend "chưa có chỉ số sức khỏe nào" (ErrorCode.HEALTH_RECORD_NOT_EXISTED) - không phải lỗi thật.
const _healthRecordNotExistedCode = 2005;

/// Nutrition-service: chỉ số sức khỏe + thực đơn tuần. Các endpoint này đều yêu cầu JWT.
/// Mọi lỗi từ backend được ném lại cho UI hiển thị popup.
class MenuRepository {
  final ApiClient _api;
  MenuRepository(this._api);

  bool get _hasToken => _api.token != null;

  void _requireLogin() {
    if (!_hasToken) throw ApiException('Vui lòng đăng nhập để sử dụng chức năng này.');
  }

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

  // POST /nutrition/meal-plans/generate {goal, availableIngredients}
  Future<WeekPlan> generate(String goal, List<String> ingredients) async {
    _requireLogin();
    final r = await _api.post(Endpoints.mealPlanGenerate,
        body: {'goal': goal, 'availableIngredients': ingredients});
    return WeekPlan.fromJson(Map<String, dynamic>.from(r as Map));
  }

  // POST /nutrition/meal-plans {goal, planData}
  Future<void> save(WeekPlan plan) async {
    _requireLogin();
    await _api.post(Endpoints.mealPlans, body: {'goal': plan.goal, 'planData': plan.raw});
  }

  // GET /nutrition/meal-plans
  Future<List<SavedPlanInfo>> savedPlans() async {
    _requireLogin();
    final r = await _api.get(Endpoints.mealPlans);
    return asList(r).map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return SavedPlanInfo((m['id'] as num).toInt(), '${m['goal']}', '${m['createdAt']}'.split('T').first);
    }).toList();
  }

  // GET /nutrition/meal-plans/{id}
  Future<WeekPlan> planDetail(int id) async {
    _requireLogin();
    final r = await _api.get('${Endpoints.mealPlans}/$id');
    return WeekPlan.fromJson(Map<String, dynamic>.from(r as Map));
  }
}
