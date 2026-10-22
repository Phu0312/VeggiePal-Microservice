/// Chỉ số sức khỏe mới nhất (nutrition-service: HealthRecordResponse).
class HealthInfo {
  final double heightCm;
  final double weightKg;
  final double bmi;
  const HealthInfo(this.heightCm, this.weightKg, this.bmi);

  factory HealthInfo.fromJson(Map<String, dynamic> j) => HealthInfo(
        (j['heightCm'] as num).toDouble(),
        (j['weightKg'] as num).toDouble(),
        (j['bmi'] as num).toDouble(),
      );

  /// BMI làm tròn HALF_UP 1 chữ số giống backend.
  static double computeBmi(double heightCm, double weightKg) {
    final m = heightCm / 100;
    return (weightKg / (m * m) * 10).roundToDouble() / 10;
  }

  String get category {
    if (bmi < 18.5) return 'Thiếu cân';
    if (bmi < 23) return 'Bình thường';
    if (bmi < 25) return 'Thừa cân nhẹ';
    return 'Béo phì';
  }

  /// Calo khuyến nghị/ngày (ước lượng thô: ~30 kcal/kg, điều chỉnh theo BMI).
  int get recommendedCalories {
    final base = weightKg * 30;
    final factor = bmi < 18.5 ? 1.15 : (bmi >= 25 ? 0.85 : 1.0);
    return (base * factor / 10).round() * 10;
  }
}

class Meal {
  final String mealType; // BREAKFAST | LUNCH | DINNER
  final String name;
  final int calories;
  final String ingredients;
  final int? recipeId; // để mở chi tiết công thức (GET /recipes/{id})
  final double protein;
  final double carbs;
  final double fat;
  const Meal(this.mealType, this.name, this.calories, this.ingredients,
      {this.recipeId, this.protein = 0, this.carbs = 0, this.fat = 0});

  factory Meal.fromJson(Map<String, dynamic> j) => Meal(
        '${j['mealType']}',
        '${j['recipeName']}',
        (j['calories'] as num?)?.toInt() ?? 0,
        '${j['ingredients'] ?? ''}',
        recipeId: (j['recipeId'] as num?)?.toInt(),
        protein: (j['protein'] as num?)?.toDouble() ?? 0,
        carbs: (j['carbs'] as num?)?.toDouble() ?? 0,
        fat: (j['fat'] as num?)?.toDouble() ?? 0,
      );
}

/// Tên bữa ăn tiếng Việt (BREAKFAST/LUNCH/DINNER/ANY).
String mealTypeLabel(String type) => switch (type.toUpperCase()) {
      'BREAKFAST' => 'Bữa sáng',
      'LUNCH' => 'Bữa trưa',
      'DINNER' => 'Bữa tối',
      'ANY' => 'Mọi bữa',
      _ => type,
    };

class DayPlan {
  final int day; // 1 = Thứ 2 ... 7 = Chủ nhật
  final List<Meal> meals;
  final int totalCalories;
  const DayPlan(this.day, this.meals, this.totalCalories);

  factory DayPlan.fromJson(Map<String, dynamic> j) => DayPlan(
        (j['day'] as num).toInt(),
        (j['meals'] as List)
            .map((m) => Meal.fromJson(Map<String, dynamic>.from(m as Map)))
            .toList(),
        (j['totalCalories'] as num?)?.toInt() ?? 0,
      );

  Meal? meal(String type) {
    for (final m in meals) {
      if (m.mealType == type) return m;
    }
    return null;
  }
}

class WeekPlan {
  final String goal;
  final List<DayPlan> days;
  final Map<String, dynamic> raw; // gửi lại nguyên vẹn khi lưu (planData)
  final int? planId; // có khi thực đơn đã được lưu (đổi món chỉ dùng được với thực đơn đã lưu)
  final List<String> allergenExclusions; // mã dị ứng đã được loại khỏi thực đơn
  const WeekPlan(this.goal, this.days, this.raw,
      {this.planId, this.allergenExclusions = const []});

  factory WeekPlan.fromJson(Map<String, dynamic> j) => WeekPlan(
        '${j['goal'] ?? 'MAINTENANCE'}',
        (j['days'] as List)
            .map((d) => DayPlan.fromJson(Map<String, dynamic>.from(d as Map)))
            .toList(),
        j,
        planId: (j['id'] as num?)?.toInt(),
        allergenExclusions: [
          for (final c in (j['allergenExclusions'] as List? ?? const [])) '$c',
        ],
      );

  WeekPlan withPlanId(int id) =>
      WeekPlan(goal, days, raw, planId: id, allergenExclusions: allergenExclusions);
}

class SavedPlanInfo {
  final int id;
  final String goal;
  final String createdAt;
  const SavedPlanInfo(this.id, this.goal, this.createdAt);
}
