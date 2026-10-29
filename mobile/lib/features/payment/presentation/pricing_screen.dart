import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/login_screen.dart';
import '../data/payment_models.dart';
import '../data/payment_repository.dart';
import '../data/subscription_controller.dart';
import 'checkout_screen.dart';
import 'payment_history_screen.dart';

/// Gói thành viên (GET /payments/plans, công khai): gói đang dùng, hạn mức từng gói và nút mua / gia hạn.
/// Mua gói trả phí tạo đơn (POST /payments/checkout) rồi mở màn thanh toán QR. Khách bấm mua thì được mời đăng nhập.
class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  List<Plan> _plans = [];
  bool _loading = true;
  bool _failed = false;
  String? _buying; // mã gói đang tạo đơn

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final sub = context.read<SubscriptionController>();
    try {
      final plans = await context.read<PaymentRepository>().plans();
      if (!mounted) return;
      setState(() => _plans = plans);
    } catch (e) {
      if (mounted) {
        setState(() => _failed = true);
        showErrorDialog(context, errorMessage(e), title: 'Không tải được các gói thành viên');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    sub.refresh(); // lỗi tải gói hiện tại hiện ngay trên thẻ gói của tôi
  }

  Future<void> _buy(Plan plan) async {
    final auth = context.read<AuthController>();
    if (!auth.isLoggedIn) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    final current = context.read<SubscriptionController>().subscription;
    // Đang dùng gói trả phí khác: gói mới thay thế hạn sử dụng hiện tại nên cần xác nhận.
    if (current != null && current.isPaid && current.planCode != plan.code) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Chuyển sang ${planName(plan.code)}?'),
          content: Text('Bạn đang dùng ${planName(current.planCode)}. Sau khi thanh toán, '
              '${planName(plan.code)} sẽ thay thế gói hiện tại và tính hạn mới từ ngày thanh toán.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Tiếp tục')),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    setState(() => _buying = plan.code);
    try {
      final order = await context.read<PaymentRepository>().checkout(plan.code);
      if (!mounted) return;
      await _openCheckout(order);
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e), title: 'Không tạo được giao dịch');
    } finally {
      if (mounted) setState(() => _buying = null);
    }
  }

  Future<void> _openCheckout(UserOrder order) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => CheckoutScreen(order: order)));
    if (mounted) context.read<SubscriptionController>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final sub = context.watch<SubscriptionController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gói thành viên'),
        actions: [
          if (auth.isLoggedIn)
            IconButton(
              tooltip: 'Lịch sử thanh toán',
              icon: const Icon(LucideIcons.history),
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const PaymentHistoryScreen())),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _failed
              ? RetryView(onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 32), children: [
                    if (auth.isLoggedIn) _CurrentPlanCard(sub),
                    const SizedBox(height: 4),
                    Text('Mở rộng hạn mức hỏi trợ lý AI, lập thực đơn và bóc tách công thức từ video.',
                        style: TextStyle(color: context.textMuted)),
                    const SizedBox(height: 12),
                    for (final p in _plans)
                      _PlanCard(
                        plan: p,
                        currentCode: auth.isLoggedIn ? sub.subscription?.planCode : null,
                        buying: _buying == p.code,
                        busy: _buying != null,
                        onBuy: () => _buy(p),
                      ),
                    const SizedBox(height: 8),
                    Text(
                        'Thanh toán bằng chuyển khoản VietQR qua PayOS. Gói được kích hoạt tự động sau khi thanh toán '
                        'thành công; mua lại đúng gói đang dùng sẽ cộng thêm thời hạn.',
                        style: TextStyle(fontSize: 12.5, color: context.textMuted)),
                  ]),
                ),
    );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  final SubscriptionController sub;
  const _CurrentPlanCard(this.sub);

  @override
  Widget build(BuildContext context) {
    final s = sub.subscription;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: context.cs.primaryContainer, borderRadius: BorderRadius.circular(14)),
            child: Icon(LucideIcons.shieldCheck, color: context.cs.onPrimaryContainer),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: s == null
                ? (sub.loading
                    ? const Text('Đang tải gói của bạn...')
                    : Text(sub.error ?? 'Chưa xác định được gói hiện tại.',
                        style: TextStyle(color: context.cs.error)))
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Gói hiện tại', style: TextStyle(fontSize: 12.5, color: context.textMuted)),
                    Text('${planName(s.planCode)} (${s.planCode})',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(
                        s.expiresAt != null
                            ? 'Hạn sử dụng đến ${fmtDateTime(s.expiresAt!)}'
                            : 'Gói mặc định, không giới hạn thời gian.',
                        style: TextStyle(fontSize: 13, color: context.textMuted)),
                  ]),
          ),
        ]),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final Plan plan;
  final String? currentCode;
  final bool buying;
  final bool busy;
  final VoidCallback onBuy;
  const _PlanCard(
      {required this.plan,
      required this.currentCode,
      required this.buying,
      required this.busy,
      required this.onBuy});

  Widget _feature(BuildContext context, IconData icon, String text, {bool enabled = true}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Icon(icon, size: 18, color: enabled ? context.cs.primary : context.textMuted),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      color: enabled ? null : context.textMuted,
                      decoration: enabled ? null : TextDecoration.lineThrough))),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final isCurrent = currentCode == plan.code;
    final popular = plan.code == 'PLUS';
    final String label;
    if (plan.isFree) {
      label = isCurrent ? 'Đang sử dụng' : 'Gói mặc định';
    } else {
      label = isCurrent ? 'Gia hạn gói' : 'Chọn ${planName(plan.code)}';
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: (popular || isCurrent && !plan.isFree)
            ? BorderSide(color: context.cs.primary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text(planName(plan.code),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
            if (isCurrent && !plan.isFree)
              StatusPill('Đang sử dụng', context.cs.primary)
            else if (popular)
              StatusPill('Phổ biến nhất', Colors.orange),
          ]),
          const SizedBox(height: 6),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(plan.isFree ? '0 ₫' : formatVnd(plan.price),
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: context.cs.primary)),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(plan.isFree ? '/ vĩnh viễn' : '/ ${plan.durationDays} ngày',
                  style: TextStyle(color: context.textMuted)),
            ),
          ]),
          const Divider(height: 24),
          _feature(context, LucideIcons.messageCircle, '${plan.chatPerDay} lượt hỏi trợ lý AI mỗi ngày'),
          _feature(context, LucideIcons.calendarDays, '${plan.mealPlansPerMonth} thực đơn tuần mỗi tháng'),
          _feature(
              context,
              LucideIcons.video,
              plan.videosPerMonth > 0
                  ? '${plan.videosPerMonth} lượt bóc tách video mỗi tháng'
                  : 'Không có bóc tách công thức từ video',
              enabled: plan.videosPerMonth > 0),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (plan.isFree || busy) ? null : onBuy,
              child: buying
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(label),
            ),
          ),
        ]),
      ),
    );
  }
}
