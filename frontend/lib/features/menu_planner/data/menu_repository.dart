import '../../../core/constants/endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/mock_fallback.dart';
import 'menu_models.dart';

/// Nutrition-service: chỉ số sức khỏe + thực đơn tuần. Các endpoint này đều yêu cầu JWT,
/// nên khách (hoặc phiên demo không có token) dùng thẳng logic cục bộ, không gọi API.
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
      if (e.isNetwork) return null;
      rethrow;
    }
  }

  // POST /nutrition/me/health-records {heightCm, weightKg}; BMI do server tính.
  Future<HealthInfo> saveHealth(double h, double w) async {
    if (_hasToken) {
      return withFallback(() async {
        final r = await _api.post(Endpoints.healthRecords,
            body: {'heightCm': h, 'weightKg': w});
        return HealthInfo.fromJson(Map<String, dynamic>.from(r as Map));
      }, () => HealthInfo(h, w, HealthInfo.computeBmi(h, w)));
    }
    return HealthInfo(h, w, HealthInfo.computeBmi(h, w));
  }

  // POST /nutrition/meal-plans/generate {goal, availableIngredients}
  Future<WeekPlan> generate(String goal, List<String> ingredients, HealthInfo? health) {
    Future<WeekPlan> local() async => _mockPlan(goal, ingredients, health);
    if (!_hasToken) return local();
    return withFallback(() async {
      final r = await _api.post(Endpoints.mealPlanGenerate,
          body: {'goal': goal, 'availableIngredients': ingredients});
      return WeekPlan.fromJson(Map<String, dynamic>.from(r as Map));
    }, () => _mockPlan(goal, ingredients, health));
  }

  // POST /nutrition/meal-plans {goal, planData}
  Future<void> save(WeekPlan plan) async {
    if (!_hasToken) return;
    await withFallback(() async {
      await _api.post(Endpoints.mealPlans, body: {'goal': plan.goal, 'planData': plan.raw});
    }, () {});
  }

  // GET /nutrition/meal-plans
  Future<List<SavedPlanInfo>> savedPlans() async {
    if (!_hasToken) return _mockSaved;
    return withFallback(() async {
      final r = await _api.get(Endpoints.mealPlans);
      return asList(r).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return SavedPlanInfo((m['id'] as num).toInt(), '${m['goal']}', '${m['createdAt']}'.split('T').first);
      }).toList();
    }, () => _mockSaved);
  }

  // GET /nutrition/meal-plans/{id}
  Future<WeekPlan?> planDetail(int id) async {
    if (!_hasToken) return null;
    return withFallback(() async {
      final r = await _api.get('${Endpoints.mealPlans}/$id');
      return WeekPlan.fromJson(Map<String, dynamic>.from(r as Map));
    }, () => null);
  }

  // ---------------- MOCK: sinh thực đơn cục bộ ----------------
  static const _mockSaved = [SavedPlanInfo(0, 'MAINTENANCE', '2026-09-20')];

  // (Tên món, calo, nguyên liệu) cho từng bữa; xoay vòng theo ngày.
  static const _menu = {
    'BREAKFAST': [
      ['Cháo yến mạch chuối hạt chia', 320, 'yến mạch, chuối, hạt chia'],
      ['Bánh mì nguyên cám bơ đậu hũ', 350, 'bánh mì, bơ, đậu hũ'],
      ['Sinh tố xanh cải kale', 260, 'cải kale, chuối, sữa hạnh nhân'],
      ['Xôi đậu xanh nước cốt dừa', 380, 'gạo nếp, đậu xanh'],
    ],
    'LUNCH': [
      ['Cơm gạo lứt đậu hũ sốt nấm', 520, 'gạo lứt, đậu hũ, nấm'],
      ['Bún nấm rau củ', 450, 'bún, nấm, cà rốt'],
      ['Salad quinoa đậu gà', 480, 'quinoa, đậu gà, dưa leo'],
      ['Mì Ý sốt cà chua nấm', 540, 'mì Ý, cà chua, nấm'],
    ],
    'DINNER': [
      ['Canh bí đỏ đậu hũ non', 300, 'bí đỏ, đậu hũ'],
      ['Đậu hũ chiên sả ớt + rau luộc', 420, 'đậu hũ, sả, rau muống'],
      ['Súp lơ xào nấm + khoai lang', 390, 'súp lơ, nấm, khoai lang'],
      ['Cà ri rau củ nước cốt dừa', 460, 'khoai tây, cà rốt, dừa'],
    ],
  };

  WeekPlan _mockPlan(String goal, List<String> ing, HealthInfo? h) {
    final mult = goal == 'WEIGHT_LOSS' ? 0.85 : (goal == 'MUSCLE_GAIN' ? 1.15 : 1.0);
    final words = ing.map((e) => e.toLowerCase()).toList();
    final days = <DayPlan>[];
    for (var d = 1; d <= 7; d++) {
      final meals = <Meal>[];
      for (final type in const ['BREAKFAST', 'LUNCH', 'DINNER']) {
        final options = _menu[type]!;
        // Ưu tiên món chứa nguyên liệu người dùng nhập; nếu không thì xoay vòng theo ngày.
        final pref = options.where((o) => words.any((w) => '${o[2]}'.contains(w))).toList();
        final pool = pref.isNotEmpty ? pref : options;
        final o = pool[(d - 1) % pool.length];
        meals.add(Meal(type, '${o[0]}', ((o[1] as int) * mult).round(), '${o[2]}'));
      }
      days.add(DayPlan(d, meals, meals.fold(0, (s, m) => s + m.calories)));
    }
    return WeekPlan(goal, days, {
      'goal': goal,
      'bmi': h?.bmi,
      'days': [
        for (final dp in days)
          {
            'day': dp.day,
            'totalCalories': dp.totalCalories,
            'meals': [
              for (final m in dp.meals)
                {'mealType': m.mealType, 'recipeName': m.name, 'calories': m.calories, 'ingredients': m.ingredients}
            ],
          }
      ],
    });
  }
}
