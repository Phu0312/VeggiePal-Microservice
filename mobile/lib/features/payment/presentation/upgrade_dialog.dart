import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import 'pricing_screen.dart';

/// Mở màn "Gói thành viên".
Future<void> openPricing(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PricingScreen()));

/// Thông báo hết hạn mức của gói hiện tại (mã 6003) kèm lối tắt sang màn nâng cấp gói.
Future<void> showUpgradeDialog(BuildContext context, String message,
    {String title = 'Đã hết lượt sử dụng'}) async {
  if (!context.mounted) return;
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(LucideIcons.sparkles, color: ctx.cs.primary, size: 36),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Để sau')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xem các gói')),
      ],
    ),
  );
  if (go == true && context.mounted) await openPricing(context);
}
