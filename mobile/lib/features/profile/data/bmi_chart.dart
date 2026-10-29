import 'profile_models.dart';

// Tính toán cho biểu đồ theo dõi BMI / cân nặng ở Hồ sơ (cùng cách tính với bản web), tách riêng để test.

enum BmiMetric {
  bmi('BMI'),
  weight('Cân nặng (kg)');

  final String label;
  const BmiMetric(this.label);

  double valueOf(HealthRecord r) => this == bmi ? r.bmi : r.weightKg;
}

/// Một điểm trên biểu đồ. [fx] chạy 0..1 từ trái sang phải; [fy] chạy 0..1 từ trên xuống
/// (0 = giá trị cao nhất, 1 = thấp nhất).
class ChartPoint {
  final double fx;
  final double fy;
  final double value;
  final DateTime? at;
  final bool isLast;
  const ChartPoint(this.fx, this.fy, this.value, this.at, this.isLast);
}

/// Các bản ghi theo thứ tự cũ -> mới (backend trả mới nhất trước).
List<HealthRecord> oldestFirst(List<HealthRecord> newestFirst) {
  final copy = [...newestFirst];
  copy.sort((a, b) => (a.recordedAt ?? DateTime(0)).compareTo(b.recordedAt ?? DateTime(0)));
  return copy;
}

/// Toạ độ chuẩn hoá của các điểm; null nếu có ít hơn 2 bản ghi (không đủ để vẽ đường).
List<ChartPoint>? chartPoints(List<HealthRecord> records, BmiMetric metric) {
  if (records.length < 2) return null;
  final values = [for (final r in records) metric.valueOf(r)];
  final minV = values.reduce((a, b) => a < b ? a : b);
  final maxV = values.reduce((a, b) => a > b ? a : b);
  final span = maxV - minV == 0 ? 1.0 : maxV - minV; // mọi điểm bằng nhau thì vẽ đường ngang
  return [
    for (var i = 0; i < values.length; i++)
      ChartPoint(
        i / (values.length - 1),
        span == 1.0 && maxV == minV ? 0.5 : (maxV - values[i]) / span,
        values[i],
        records[i].recordedAt,
        i == values.length - 1,
      ),
  ];
}

/// Thay đổi giữa bản ghi đầu và bản ghi mới nhất.
class Trend {
  final double diff;
  final int days;
  final String unit;
  const Trend(this.diff, this.days, this.unit);

  String get highlight {
    if (diff < 0) return 'Chỉ số giảm ${_fmt(diff.abs())} $unit';
    if (diff > 0) return 'Chỉ số tăng ${_fmt(diff)} $unit';
    return 'Chỉ số duy trì ổn định';
  }

  String get detail => 'sau $days ngày theo dõi';

  static String _fmt(double v) => v.toStringAsFixed(1);
}

Trend? trendOf(List<HealthRecord> records, BmiMetric metric) {
  if (records.length < 2) return null;
  final first = records.first, last = records.last;
  final diff = double.parse((metric.valueOf(last) - metric.valueOf(first)).toStringAsFixed(1));
  var days = 1;
  if (first.recordedAt != null && last.recordedAt != null) {
    final d = last.recordedAt!.difference(first.recordedAt!).inHours.abs() / 24;
    days = d.round() < 1 ? 1 : d.round();
  }
  return Trend(diff, days, metric == BmiMetric.bmi ? 'điểm' : 'kg');
}
