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
