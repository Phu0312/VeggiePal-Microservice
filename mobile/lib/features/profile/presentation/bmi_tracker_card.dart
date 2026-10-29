import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../menu_planner/data/menu_models.dart';
import '../data/bmi_chart.dart';
import '../data/profile_models.dart';

/// Theo dõi thể trạng: biểu đồ đường BMI hoặc cân nặng qua các lần ghi chỉ số gần nhất, kèm nhận xét thay đổi.
/// [recordsNewestFirst] là các bản ghi từ backend (mới nhất trước); cần ít nhất 2 bản ghi mới vẽ được đường.
class BmiTrackerCard extends StatefulWidget {
  final List<HealthRecord> recordsNewestFirst;
  final VoidCallback onOpenHistory;
  const BmiTrackerCard({super.key, required this.recordsNewestFirst, required this.onOpenHistory});

  @override
  State<BmiTrackerCard> createState() => _BmiTrackerCardState();
}

class _BmiTrackerCardState extends State<BmiTrackerCard> {
  BmiMetric _metric = BmiMetric.bmi;

  @override
  Widget build(BuildContext context) {
    final records = oldestFirst(widget.recordsNewestFirst);
    final points = chartPoints(records, _metric);
    final trend = trendOf(records, _metric);
    final latest = records.isEmpty ? null : records.last;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(LucideIcons.trendingDown, size: 18, color: context.cs.primary),
            const SizedBox(width: 8),
            const Expanded(
                child: Text('Theo dõi thể trạng', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
            TextButton(onPressed: widget.onOpenHistory, child: const Text('Lịch sử')),
          ]),
          if (latest != null)
            Text(
                _metric == BmiMetric.bmi
                    ? 'BMI hiện tại ${latest.bmi.toStringAsFixed(1)} • ${HealthInfo(latest.heightCm, latest.weightKg, latest.bmi).category}'
                    : 'Cân nặng hiện tại ${latest.weightKg} kg',
                style: TextStyle(fontSize: 13, color: context.textMuted)),
          const SizedBox(height: 10),
          SegmentedButton<BmiMetric>(
            showSelectedIcon: false,
            segments: [for (final m in BmiMetric.values) ButtonSegment(value: m, label: Text(m.label))],
            selected: {_metric},
            onSelectionChanged: (s) => setState(() => _metric = s.first),
          ),
          const SizedBox(height: 14),
          if (latest == null)
            _Placeholder('Chưa có chỉ số nào. Vào "Lịch sử" để thêm chiều cao và cân nặng.')
          else if (points == null)
            _Placeholder('Cần ít nhất 2 lần ghi chỉ số để vẽ biểu đồ.')
          else ...[
            SizedBox(
              height: 130,
              child: CustomPaint(
                size: const Size.fromHeight(130),
                painter: _LinePainter(points, context.cs.primary, context.cs.surface),
              ),
            ),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              for (final p in points)
                Text('${p.at == null ? '-' : _day(p.at!)}\n${p.value.toStringAsFixed(1)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: p.isLast ? FontWeight.w800 : FontWeight.w500,
                        color: p.isLast ? context.cs.onSurface : context.textMuted)),
            ]),
          ],
          if (trend != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
              child: Text.rich(TextSpan(children: [
                TextSpan(text: '${trend.highlight}: ', style: const TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: trend.detail),
              ]), style: const TextStyle(fontSize: 13)),
            ),
          ],
        ]),
      ),
    );
  }

  static String _day(DateTime d) {
    final l = d.toLocal();
    return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}';
  }
}

class _Placeholder extends StatelessWidget {
  final String text;
  const _Placeholder(this.text);

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
        decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor), borderRadius: BorderRadius.circular(14)),
        child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: context.textMuted, fontSize: 13)),
      );
}

/// Vẽ vùng mờ, đường và các điểm đo từ toạ độ chuẩn hoá của [chartPoints].
class _LinePainter extends CustomPainter {
  final List<ChartPoint> points;
  final Color color;
  final Color dotBorder;
  _LinePainter(this.points, this.color, this.dotBorder);

  static const _padX = 10.0, _padTop = 14.0, _padBottom = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    final usableW = size.width - _padX * 2;
    final usableH = size.height - _padTop - _padBottom;
    Offset at(ChartPoint p) => Offset(_padX + p.fx * usableW, _padTop + p.fy * usableH);

    final line = Path()..moveTo(at(points.first).dx, at(points.first).dy);
    for (final p in points.skip(1)) {
      line.lineTo(at(p).dx, at(p).dy);
    }
    final area = Path.from(line)
      ..lineTo(at(points.last).dx, size.height)
      ..lineTo(at(points.first).dx, size.height)
      ..close();

    canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0)])
              .createShader(Offset.zero & size));
    canvas.drawPath(
        line,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
    for (final p in points) {
      final c = at(p);
      canvas.drawCircle(c, p.isLast ? 6.5 : 5, Paint()..color = dotBorder);
      canvas.drawCircle(c, p.isLast ? 4.5 : 3.5, Paint()..color = p.isLast ? color : color.withValues(alpha: 0.7));
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.points != points || old.color != color || old.dotBorder != dotBorder;
}
