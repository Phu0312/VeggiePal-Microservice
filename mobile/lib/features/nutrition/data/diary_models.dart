// Nhật ký dinh dưỡng hằng ngày (nutrition-service: `/nutrition/me/food-logs`, `/water`, `/daily-activity`,
// `/daily-summary`).

double _d(Object? v) => v is num ? v.toDouble() : 0;
int _i(Object? v) => v is num ? v.toInt() : 0;

/// Bữa ăn trong ngày (nutrition-service: MealType).
enum MealSlot {
  breakfast('BREAKFAST', 'Bữa sáng'),
  lunch('LUNCH', 'Bữa trưa'),
  dinner('DINNER', 'Bữa tối'),
  snack('SNACK', 'Bữa phụ');

  final String code;
  final String label;
  const MealSlot(this.code, this.label);

  static MealSlot fromCode(String? code) =>
      values.firstWhere((m) => m.code == code, orElse: () => MealSlot.snack);

  /// Bữa hợp lý nhất theo giờ hiện tại, dùng làm lựa chọn mặc định khi ghi món.
  static MealSlot forTime(DateTime t) {
    if (t.hour < 10) return MealSlot.breakfast;
    if (t.hour < 15) return MealSlot.lunch;
    if (t.hour < 21) return MealSlot.dinner;
    return MealSlot.snack;
  }
}

/// `yyyy-MM-dd` theo giờ địa phương, đúng định dạng ngày mà BE nhận.
String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Một món đã ghi trong nhật ký (FoodLogResponse).
class FoodEntry {
  final int id;
  final MealSlot meal;
  final String name;
  final int? recipeId;
  final int calories;
  final double protein, carbs, fat, fiber;

  const FoodEntry({
    required this.id,
    required this.meal,
    required this.name,
    this.recipeId,
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.fiber = 0,
  });

  factory FoodEntry.fromJson(Map<String, dynamic> j) => FoodEntry(
        id: _i(j['id']),
        meal: MealSlot.fromCode(j['mealType'] as String?),
        name: '${j['foodName'] ?? ''}',
        recipeId: (j['recipeId'] as num?)?.toInt(),
        calories: _i(j['calories']),
        protein: _d(j['proteinG']),
        carbs: _d(j['carbsG']),
        fat: _d(j['fatG']),
        fiber: _d(j['fiberG']),
      );
}

/// Dữ liệu người dùng nhập khi ghi một món (FoodLogRequest). Ô bỏ trống tính là 0.
class FoodDraft {
  final String name;
  final MealSlot meal;
  final int? recipeId;
  final int? calories;
  final double? protein, carbs, fat, fiber;

  const FoodDraft({
    required this.name,
    required this.meal,
    this.recipeId,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.fiber,
  });

  Map<String, dynamic> toJson(DateTime date) => {
        'logDate': isoDate(date),
        'mealType': meal.code,
        'foodName': name.trim(),
        'recipeId': ?recipeId,
        'calories': ?calories,
        'proteinG': ?protein,
        'carbsG': ?carbs,
        'fatG': ?fat,
        'fiberG': ?fiber,
      };
}

/// Nước uống và vận động của một ngày (DailyActivityResponse).
class DailyActivity {
  final int waterMl;
  final int waterTargetMl;
  final int waterGlasses;
  final int exerciseMinutes;
  final int steps;
  final int caloriesBurned;
  final String? note;

  const DailyActivity({
    this.waterMl = 0,
    this.waterTargetMl = 2000,
    this.waterGlasses = 0,
    this.exerciseMinutes = 0,
    this.steps = 0,
    this.caloriesBurned = 0,
    this.note,
  });

  factory DailyActivity.fromJson(Map<String, dynamic> j) => DailyActivity(
        waterMl: _i(j['waterMl']),
        waterTargetMl: j['waterTargetMl'] == null ? 2000 : _i(j['waterTargetMl']),
        waterGlasses: _i(j['waterGlasses']),
        exerciseMinutes: _i(j['exerciseMinutes']),
        steps: _i(j['steps']),
        caloriesBurned: _i(j['caloriesBurned']),
        note: j['activityNote'] as String?,
      );
}

/// Tổng kết một ngày: lượng nạp so với mục tiêu, nước, vận động và các món đã ghi (DailyNutritionSummaryResponse).
/// Mục tiêu macro do BE chia theo calo mục tiêu: 50% tinh bột, 20% đạm, 30% chất béo.
class DailySummary {
  final DateTime date;
  final int consumedCalories;
  final int targetCalories;
  final int remainingCalories;
  final double protein, targetProtein;
  final double carbs, targetCarbs;
  final double fat, targetFat;
  final double fiber;
  final DailyActivity activity;
  final List<FoodEntry> entries;

  const DailySummary({
    required this.date,
    this.consumedCalories = 0,
    this.targetCalories = 2000,
    this.remainingCalories = 0,
    this.protein = 0,
    this.targetProtein = 0,
    this.carbs = 0,
    this.targetCarbs = 0,
    this.fat = 0,
    this.targetFat = 0,
    this.fiber = 0,
    this.activity = const DailyActivity(),
    this.entries = const [],
  });

  factory DailySummary.fromJson(Map<String, dynamic> j) => DailySummary(
        date: DateTime.tryParse('${j['date']}') ?? DateTime.now(),
        consumedCalories: _i(j['consumedCalories']),
        targetCalories: j['targetCalories'] == null ? 2000 : _i(j['targetCalories']),
        remainingCalories: _i(j['remainingCalories']),
        protein: _d(j['proteinG']),
        targetProtein: _d(j['targetProteinG']),
        carbs: _d(j['carbsG']),
        targetCarbs: _d(j['targetCarbsG']),
        fat: _d(j['fatG']),
        targetFat: _d(j['targetFatG']),
        fiber: _d(j['fiberG']),
        activity: DailyActivity(
          waterMl: _i(j['waterMl']),
          waterTargetMl: j['waterTargetMl'] == null ? 2000 : _i(j['waterTargetMl']),
          waterGlasses: _i(j['waterGlasses']),
          exerciseMinutes: _i(j['exerciseMinutes']),
          steps: _i(j['steps']),
          caloriesBurned: _i(j['caloriesBurned']),
          note: j['activityNote'] as String?,
        ),
        entries: [
          for (final e in (j['entries'] as List? ?? const [])) FoodEntry.fromJson(Map<String, dynamic>.from(e as Map)),
        ],
      );

  List<FoodEntry> entriesOf(MealSlot meal) => [for (final e in entries) if (e.meal == meal) e];

  int caloriesOf(MealSlot meal) => entriesOf(meal).fold(0, (s, e) => s + e.calories);

  /// Tỉ lệ calo đã nạp trên mục tiêu, 0..1 (có thể vượt 1 thực tế nhưng thanh chỉ hiển thị tới 100%).
  double get calorieRatio => targetCalories <= 0 ? 0 : (consumedCalories / targetCalories).clamp(0.0, 1.0);

  bool get overTarget => targetCalories > 0 && consumedCalories > targetCalories;

  double get waterRatio => activity.waterTargetMl <= 0 ? 0 : (activity.waterMl / activity.waterTargetMl).clamp(0.0, 1.0);
}
