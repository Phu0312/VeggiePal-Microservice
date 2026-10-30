import '../../../core/constants/endpoints.dart';
import '../../../core/network/api_client.dart';
import 'meal_plan_models.dart';

/// ai-service: thực đơn tuần (`/ai/meal-plans`, cần JWT). Công thức của từng bữa lấy ở RecipeRepository.
/// Mọi lỗi được ném lại cho UI hiển thị popup.
class MealPlanRepository {
  final ApiClient _api;
  MealPlanRepository(this._api);

  void _requireLogin() {
    if (_api.token == null) throw ApiException('Vui lòng đăng nhập để sử dụng chức năng này.');
  }

  MealPlan _plan(dynamic r) => MealPlan.fromJson(Map<String, dynamic>.from(r as Map));

  // POST /ai/meal-plans. Backend tạo và lưu luôn thực đơn (trừ 1 lượt thực đơn của gói).
  // Không gửi dailyNutritionTarget thì backend tự tính theo hồ sơ + goalType.
  Future<MealPlan> generate({
    required String name,
    required PlanGoal goal,
    List<String> ingredients = const [],
    List<String> preferences = const [],
  }) async {
    _requireLogin();
    final r = await _api.post(Endpoints.aiMealPlans, body: {
      'name': name,
      'goalType': goal.value,
      'healthGoal': goal.label,
      'preferences': preferences,
      'availableIngredients': ingredients,
    });
    return _plan(r);
  }

  // GET /ai/meal-plans -> mới nhất trước
  Future<List<MealPlan>> myPlans() async {
    _requireLogin();
    return asList(await _api.get(Endpoints.aiMealPlans)).map(_plan).toList();
  }

  // GET /ai/meal-plans/{id}
  Future<MealPlan> plan(int id) async {
    _requireLogin();
    return _plan(await _api.get(Endpoints.aiMealPlan(id)));
  }

  // POST /ai/meal-plans/{id}/replace {day, mealType, currentRecipeId} -> thực đơn đã đổi món
  // (backend chọn món khác, tránh dị ứng và lưu lại luôn).
  Future<MealPlan> replaceMeal(MealPlan plan, String day, PlanMeal meal) async {
    _requireLogin();
    final r = await _api.post(Endpoints.aiMealPlanReplace(plan.id),
        body: {'day': day, 'mealType': meal.mealType, 'currentRecipeId': meal.recipeId});
    return _plan(r);
  }

  // POST /ai/meal-plans/{id}/favorite (409 / 6014 nếu đã yêu thích) và DELETE cùng đường dẫn.
  Future<void> setFavorite(int id, bool favorite) async {
    _requireLogin();
    if (favorite) {
      await _api.post(Endpoints.aiMealPlanFavorite(id));
    } else {
      await _api.delete(Endpoints.aiMealPlanFavorite(id));
    }
  }

  // GET /ai/meal-plans/favorites?page&size (PageResponse)
  Future<List<MealPlan>> favorites({int size = 50}) async {
    _requireLogin();
    final r = await _api.get(Endpoints.aiMealPlanFavorites, query: {'page': 0, 'size': size});
    return asList(r).map(_plan).toList();
  }

  // GET /ai/meal-plans/{id}/versions -> mới nhất trước
  Future<List<MealPlanVersion>> versions(int id) async {
    _requireLogin();
    final r = await _api.get(Endpoints.aiMealPlanVersions(id));
    return asList(r)
        .map((e) => MealPlanVersion.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // POST /ai/meal-plans/{id}/versions/{version}/restore : đưa nội dung phiên bản cũ về làm thực đơn hiện tại. BE lưu
  // nội dung hiện tại thành một phiên bản trong lịch sử trước khi thay nên không mất gì. Lỗi 6017 = không có phiên bản đó.
  Future<MealPlan> restoreVersion(int id, int version) async {
    _requireLogin();
    return _plan(await _api.post(Endpoints.aiMealPlanRestore(id, version)));
  }

  // GET /ai/meal-plans/nutrition-target?goalType= -> mục tiêu calo backend tính từ hồ sơ.
  // Lỗi 6010 (thiếu chỉ số sức khỏe) / 6020 (thiếu hồ sơ) / 6021 (dưới 18 tuổi) được ném lại.
  Future<NutritionTargetInfo> nutritionTarget(PlanGoal goal) async {
    _requireLogin();
    final r = await _api.get(Endpoints.aiNutritionTarget, query: {'goalType': goal.value});
    return NutritionTargetInfo.fromJson(Map<String, dynamic>.from(r as Map));
  }
}
