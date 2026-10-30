import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/format.dart';
import '../data/payment_models.dart';

/// Một thanh hạn mức: tên tính năng, "Còn X/Y lượt ..." và ngày đặt lại. Đỏ khi hết lượt, cam khi còn ít (≤ 20%).
class QuotaMeter extends StatelessWidget {
  final String title;
  final FeatureQuota quota;
  const QuotaMeter({super.key, required this.title, required this.quota});

  @override
  Widget build(BuildContext context) {
    final low = quota.limit > 0 && quota.remaining / quota.limit <= 0.2;
    final color = quota.exhausted || quota.limit <= 0
        ? context.cs.error
        : low
        ? Colors.deepOrange
        : context.cs.primary;
    final resets = quota.resetsAt;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              ),
              Text(
                quota.label,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: quota.limit <= 0 ? 1 : quota.usedRatio,
              minHeight: 6,
              color: color,
            ),
          ),
          if (resets != null && quota.limit > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Đặt lại ngày ${fmtDate(resets)}',
                style: TextStyle(fontSize: 11.5, color: context.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}
