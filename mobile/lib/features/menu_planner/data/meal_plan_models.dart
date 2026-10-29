// Model thực đơn tuần của ai-service (`/ai/meal-plans`). Phần `plan` của backend chỉ có `recipeId`
// cho mỗi bữa; tên món, ảnh, nguyên liệu và các bước nấu lấy riêng từ recipe-service (xem PlanRecipe).

/// Mục tiêu của thực đơn (ai-service: GoalType).
class PlanGoal {
  final String value;
  final String label;
  final String hint;
  const PlanGoal(this.value, this.label, this.hint);

  static const lose = PlanGoal('LOSE', 'Giảm cân', 'Ăn ít hơn nhu cầu khoảng 15%');
  static const maintain = PlanGoal('MAINTAIN', 'Duy trì', 'Ăn đúng nhu cầu mỗi ngày');
  static const gain = PlanGoal('GAIN', 'Tăng cân', 'Ăn nhiều hơn nhu cầu khoảng 15%');
  static const all = [lose, maintain, gain];

  /// Nhãn tiếng Việt; thực đơn cũ chưa có goalType hoặc giá trị lạ thì trả chuỗi rỗng.
  static String labelOf(String? value) {
    for (final g in all) {
      if (g.value == value) return g.label;
    }
    return '';
  }
}

/// Thứ trong tuần theo thứ tự T2 -> CN; backend dùng tên tiếng Anh viết hoa (không đảm bảo hoa/thường).
const planDayOrder = [
  'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY',
];
const _dayShort = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
const _dayLong = ['Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ nhật'];

/// Bữa trong ngày; backend chỉ trả 3 bữa này.
const planMealOrder = ['BREAKFAST', 'LUNCH', 'DINNER'];

String normalizeKey(Object? v) => '$v'.trim().toUpperCase();

String dayShortLabel(String day) {
  final i = planDayOrder.indexOf(normalizeKey(day));
  return i < 0 ? day : _dayShort[i];
}

String dayLongLabel(String day) {
  final i = planDayOrder.indexOf(normalizeKey(day));
  return i < 0 ? day : _dayLong[i];
}

/// Khoá thứ của hôm nay (giờ máy), ví dụ `MONDAY`.
String todayDayKey([DateTime? now]) => planDayOrder[((now ?? DateTime.now()).weekday - 1) % 7];

String planMealLabel(String type) => switch (normalizeKey(type)) {
      'BREAKFAST' => 'Bữa sáng',
      'LUNCH' => 'Bữa trưa',
      'DINNER' => 'Bữa tối',
      _ => type,
    };

double _num(Object? v) => v is num ? v.toDouble() : 0;

/// Năng lượng và ba chất đa lượng (key khớp `nutrition` / `nutritionTotals` của backend).
class Nutrition {
  final double calories;
  final double protein;
  final double carbohydrate;
  final double fat;
  const Nutrition({this.calories = 0, this.protein = 0, this.carbohydrate = 0, this.fat = 0});

  factory Nutrition.fromJson(Object? j) {
    if (j is! Map) return const Nutrition();
    return Nutrition(
      calories: _num(j['calories']),
      protein: _num(j['protein']),
      carbohydrate: _num(j['carbohydrate']),
      fat: _num(j['fat']),
    );
  }
}

/// Khoảng mục tiêu dinh dưỡng mỗi ngày (`dailyNutritionTarget`).
class NutritionTarget {
  final double? minCalories, maxCalories;
  final double? minProtein, maxProtein;
  final double? minCarbohydrate, maxCarbohydrate;
  final double? minFat, maxFat;
  const NutritionTarget({
    this.minCalories,
    this.maxCalories,
    this.minProtein,
    this.maxProtein,
    this.minCarbohydrate,
    this.maxCarbohydrate,
    this.minFat,
    this.maxFat,
  });

  static double? _opt(Object? v) => v is num ? v.toDouble() : null;

  factory NutritionTarget.fromJson(Object? j) {
    if (j is! Map) return const NutritionTarget();
    return NutritionTarget(
      minCalories: _opt(j['minCalories']),
      maxCalories: _opt(j['maxCalories']),
      minProtein: _opt(j['minProtein']),
      maxProtein: _opt(j['maxProtein']),
      minCarbohydrate: _opt(j['minCarbohydrate']),
      maxCarbohydrate: _opt(j['maxCarbohydrate']),
      minFat: _opt(j['minFat']),
      maxFat: _opt(j['maxFat']),
    );
  }

  /// Mỗi chất một dòng ("Năng lượng: 1.500–1.800 kcal"); bỏ chất không đặt mốc nào.
  List<(String label, String range)> get lines => [
        for (final m in [
          ('Năng lượng', minCalories, maxCalories, 'kcal'),
          ('Đạm', minProtein, maxProtein, 'g'),
          ('Tinh bột', minCarbohydrate, maxCarbohydrate, 'g'),
          ('Chất béo', minFat, maxFat, 'g'),
        ])
          if (describeRange(m.$2, m.$3, m.$4).isNotEmpty) (m.$1, describeRange(m.$2, m.$3, m.$4)),
      ];
}

String _fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

/// "1500–1800 kcal", "≥ 80 g" hoặc "≤ 60 g"; rỗng nếu không có mốc nào.
String describeRange(double? min, double? max, String unit) {
  if (min != null && max != null) return '${_fmt(min)}–${_fmt(max)} $unit';
  if (min != null) return '≥ ${_fmt(min)} $unit';
  if (max != null) return '≤ ${_fmt(max)} $unit';
  return '';
}

/// Kết quả `GET /ai/meal-plans/nutrition-target`: mục tiêu calo do backend tính từ hồ sơ.
class NutritionTargetInfo {
  final int bmr;
  final int tdee;
  final int targetCalories;
  final NutritionTarget target;
  const NutritionTargetInfo(this.bmr, this.tdee, this.targetCalories, this.target);

  factory NutritionTargetInfo.fromJson(Map<String, dynamic> j) => NutritionTargetInfo(
        (j['bmr'] as num?)?.toInt() ?? 0,
        (j['tdee'] as num?)?.toInt() ?? 0,
        (j['targetCalories'] as num?)?.toInt() ?? 0,
        NutritionTarget.fromJson(j['target']),
      );
}

/// Chất lệch khỏi khoảng mục tiêu của một ngày (`targetDeviations`).
class Deviation {
  final String label;
  final String unit;
  final double actual;
  final String range;
  const Deviation(this.label, this.unit, this.actual, this.range);
}

class PlanMeal {
  final String mealType; // BREAKFAST | LUNCH | DINNER
  final int recipeId;
  final String note;
  final Nutrition nutrition;
  final double servingMultiplier;
  const PlanMeal({
    required this.mealType,
    required this.recipeId,
    this.note = '',
    this.nutrition = const Nutrition(),
    this.servingMultiplier = 1,
  });

  factory PlanMeal.fromJson(Map<String, dynamic> j) => PlanMeal(
        mealType: normalizeKey(j['mealType']),
        recipeId: (j['recipeId'] as num).toInt(),
        note: '${j['note'] ?? ''}',
        nutrition: Nutrition.fromJson(j['nutrition']),
        servingMultiplier: (j['servingMultiplier'] as num?)?.toDouble() ?? 1,
      );
}

class PlanDay {
  final String day; // MONDAY..SUNDAY
  final List<PlanMeal> meals; // đã sắp sáng -> trưa -> tối
  final Nutrition totals;
  final bool? targetMet;
  final List<Deviation> deviations;
  const PlanDay(this.day, this.meals, this.totals, this.targetMet, this.deviations);

  static const _metrics = [
    ('calories', 'Năng lượng', 'kcal'),
    ('protein', 'Đạm', 'g'),
    ('carbohydrate', 'Tinh bột', 'g'),
    ('fat', 'Chất béo', 'g'),
  ];

  factory PlanDay.fromJson(Map<String, dynamic> j) {
    final meals = [
      for (final m in (j['meals'] as List? ?? const []))
        PlanMeal.fromJson(Map<String, dynamic>.from(m as Map)),
    ]..sort((a, b) => _order(planMealOrder, a.mealType).compareTo(_order(planMealOrder, b.mealType)));

    final raw = j['targetDeviations'];
    final deviations = <Deviation>[];
    if (raw is Map) {
      for (final (key, label, unit) in _metrics) {
        final d = raw[key];
        if (d is! Map) continue;
        deviations.add(Deviation(label, unit, _num(d['actual']),
            describeRange(NutritionTarget._opt(d['min']), NutritionTarget._opt(d['max']), unit)));
      }
    }
    return PlanDay(normalizeKey(j['day']), meals, Nutrition.fromJson(j['nutritionTotals']),
        j['targetMet'] as bool?, deviations);
  }

  PlanMeal? meal(String type) {
    for (final m in meals) {
      if (m.mealType == type) return m;
    }
    return null;
  }

  /// Ngày lỡ mục tiêu calo: backend đánh dấu `targetMet == false`.
  bool get missedTarget => targetMet == false;

  /// Đạm/tinh bột/béo lệch khoảng mục tiêu trong khi calo vẫn đạt: chỉ là lưu ý nhẹ.
  List<Deviation> get macroNotes => targetMet == true ? deviations : const [];

  /// Các chất lệch khi ngày lỡ mục tiêu calo.
  List<Deviation> get missedDeviations => targetMet == true ? const [] : deviations;
}

int _order(List<String> order, String key) {
  final i = order.indexOf(key);
  return i < 0 ? order.length : i;
}

List<PlanDay> _parseDays(Object? plan) {
  final days = plan is Map ? plan['days'] : null;
  if (days is! List) return const [];
  return [
    for (final d in days) PlanDay.fromJson(Map<String, dynamic>.from(d as Map)),
  ]..sort((a, b) => _order(planDayOrder, a.day).compareTo(_order(planDayOrder, b.day)));
}

/// Một thực đơn tuần đã lưu (ai-service: MealPlanResponse). Backend lưu ngay khi tạo.
class MealPlan {
  final int id;
  final String name;
  final String goal;
  final String? goalType;
  final int version;
  final bool isFavorite;
  final DateTime? createdAt;
  final List<PlanDay> days;
  final NutritionTarget? target;

  /// Khác null khi đang xem một phiên bản cũ (chỉ đọc).
  final int? viewingVersion;

  const MealPlan({
    required this.id,
    required this.name,
    required this.goal,
    required this.goalType,
    required this.version,
    required this.isFavorite,
    required this.createdAt,
    required this.days,
    this.target,
    this.viewingVersion,
  });

  factory MealPlan.fromJson(Map<String, dynamic> j) {
    final plan = j['plan'];
    final constraints = plan is Map ? plan['constraints'] : null;
    final target = constraints is Map && constraints['dailyNutritionTarget'] is Map
        ? NutritionTarget.fromJson(constraints['dailyNutritionTarget'])
        : null;
    return MealPlan(
      id: (j['id'] as num).toInt(),
      name: '${j['name'] ?? ''}',
      goal: '${j['goal'] ?? ''}',
      goalType: j['goalType'] as String?,
      version: (j['version'] as num?)?.toInt() ?? 1,
      isFavorite: j['isFavorite'] == true,
      createdAt: j['createdAt'] == null ? null : DateTime.tryParse('${j['createdAt']}'),
      days: _parseDays(plan),
      target: target,
    );
  }

  MealPlan copyWith({bool? isFavorite}) => MealPlan(
        id: id,
        name: name,
        goal: goal,
        goalType: goalType,
        version: version,
        isFavorite: isFavorite ?? this.isFavorite,
        createdAt: createdAt,
        days: days,
        target: target,
        viewingVersion: viewingVersion,
      );

  /// Mục tiêu một dòng: "Giảm cân · ăn thanh đạm", "Duy trì", hoặc nguyên `goal` với thực đơn cũ.
  String get goalSummary {
    final label = PlanGoal.labelOf(goalType);
    if (label.isEmpty) return goal;
    if (goal == label) return label;
    final note = goal.startsWith('$label: ') ? goal.substring(label.length + 2) : goal;
    return '$label · $note';
  }

  PlanDay? dayOf(String key) {
    for (final d in days) {
      if (d.day == key) return d;
    }
    return null;
  }

  int get missedDays => days.where((d) => d.missedTarget).length;
}

/// Một phiên bản trong lịch sử của thực đơn (`/ai/meal-plans/{id}/versions`).
class MealPlanVersion {
  final int version;
  final String name;
  final String goal;
  final String changeSummary;
  final DateTime? createdAt;
  final List<PlanDay> days;
  const MealPlanVersion(this.version, this.name, this.goal, this.changeSummary, this.createdAt, this.days);

  factory MealPlanVersion.fromJson(Map<String, dynamic> j) => MealPlanVersion(
        (j['version'] as num).toInt(),
        '${j['name'] ?? ''}',
        '${j['goal'] ?? ''}',
        '${j['changeSummary'] ?? ''}',
        j['createdAt'] == null ? null : DateTime.tryParse('${j['createdAt']}'),
        _parseDays(j['plan']),
      );

  /// Dựng thực đơn chỉ đọc từ phiên bản này, giữ id/mục tiêu/yêu thích của thực đơn hiện tại.
  MealPlan asPlanOf(MealPlan current) => MealPlan(
        id: current.id,
        name: name,
        goal: goal,
        goalType: current.goalType,
        version: version,
        isFavorite: current.isFavorite,
        createdAt: createdAt,
        days: days,
        target: current.target,
        viewingVersion: version,
      );
}

/// Nguyên liệu của một công thức (recipe-service: RecipeIngredientResponse).
class PlanIngredient {
  final String name;
  final String amount; // "200 g" hoặc rỗng
  const PlanIngredient(this.name, this.amount);
}

/// Phần của công thức mà màn thực đơn cần (recipe-service: RecipeResponse).
class PlanRecipe {
  final int id;
  final String title;
  final String? description;
  final String? imageUrl;
  final int? servings;
  final int? prepTime;
  final int? cookTime;
  final List<PlanIngredient> ingredients;
  final List<String> steps;
  const PlanRecipe({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.servings,
    this.prepTime,
    this.cookTime,
    this.ingredients = const [],
    this.steps = const [],
  });

  factory PlanRecipe.fromJson(Map<String, dynamic> j) {
    final steps = [
      for (final s in (j['steps'] as List? ?? const [])) Map<String, dynamic>.from(s as Map),
    ]..sort((a, b) => ((a['stepNumber'] as num?) ?? 0).compareTo((b['stepNumber'] as num?) ?? 0));
    return PlanRecipe(
      id: (j['id'] as num).toInt(),
      title: '${j['title'] ?? ''}',
      description: j['description'] as String?,
      imageUrl: j['imageUrl'] as String?,
      servings: (j['servings'] as num?)?.toInt(),
      prepTime: (j['prepTime'] as num?)?.toInt(),
      cookTime: (j['cookTime'] as num?)?.toInt(),
      ingredients: [
        for (final i in (j['ingredients'] as List? ?? const []))
          PlanIngredient('${(i as Map)['ingredientName'] ?? ''}', _amount(i['quantity'], i['unit'])),
      ],
      steps: [for (final s in steps) '${s['instruction'] ?? ''}'],
    );
  }

  static String _amount(Object? quantity, Object? unit) => [
        if (quantity is num) _fmt(quantity.toDouble()),
        if (unit != null && '$unit'.trim().isNotEmpty) '$unit'.trim(),
      ].join(' ');

  /// Tổng thời gian chuẩn bị + nấu (phút); null nếu cả hai đều trống.
  int? get totalMinutes =>
      prepTime == null && cookTime == null ? null : (prepTime ?? 0) + (cookTime ?? 0);
}
