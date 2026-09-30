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
  const Meal(this.mealType, this.name, this.calories, this.ingredients);

  factory Meal.fromJson(Map<String, dynamic> j) => Meal(
        '${j['mealType']}',
        '${j['recipeName']}',
        (j['calories'] as num?)?.toInt() ?? 0,
        '${j['ingredients'] ?? ''}',
      );
}

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
  const WeekPlan(this.goal, this.days, this.raw);

  factory WeekPlan.fromJson(Map<String, dynamic> j) => WeekPlan(
        '${j['goal'] ?? 'MAINTENANCE'}',
        (j['days'] as List)
            .map((d) => DayPlan.fromJson(Map<String, dynamic>.from(d as Map)))
            .toList(),
        j,
      );
}

class SavedPlanInfo {
  final int id;
  final String goal;
  final String createdAt;
  const SavedPlanInfo(this.id, this.goal, this.createdAt);
}
