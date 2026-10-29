import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/common_widgets.dart';
import '../data/payment_models.dart';
import '../data/payment_repository.dart';
import '../data/subscription_controller.dart';
import 'checkout_screen.dart';

/// Lịch sử thanh toán (GET /payments/history, mới nhất trước). Đơn chưa thanh toán còn hạn có nút
/// "Tiếp tục thanh toán"; các đơn khác bấm vào để xem chi tiết.
class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  List<UserOrder> _orders = [];
  bool _loading = true;
  bool _failed = false;

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
    try {
      final r = await context.read<PaymentRepository>().history();
      if (mounted) setState(() => _orders = r);
    } catch (e) {
      if (mounted) {
        setState(() => _failed = true);
        showErrorDialog(context, errorMessage(e), title: 'Không tải được lịch sử thanh toán');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _color(BuildContext context, String status) => switch (status) {
        'PAID' => Colors.green,
        'PENDING' => Colors.orange,
        'FAILED' => context.cs.error,
        _ => context.textMuted,
      };

  Future<void> _resume(UserOrder o) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => CheckoutScreen(order: o)));
    if (!mounted) return;
    context.read<SubscriptionController>().refresh();
    _load();
  }

  void _detail(UserOrder o) {
    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 120, child: Text(label, style: TextStyle(color: context.textMuted))),
            Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
          ]),
        );
    String when(DateTime? t) => t == null ? '-' : fmtDateTime(t);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Đơn #${o.orderCode}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            row('Trạng thái', orderStatusLabel(o.status)),
            row('Gói', planName(o.planCode)),
            row('Số tiền', formatVnd(o.amount)),
            row('Nội dung', (o.description ?? '').isEmpty ? '-' : o.description!),
            row('Tạo lúc', when(o.createdAt)),
            row('Thanh toán lúc', when(o.paidAt)),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử thanh toán')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _failed
              ? RetryView(onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _orders.isEmpty
                      ? ListView(children: [
                          Padding(
                            padding: const EdgeInsets.all(48),
                            child: Center(
                                child: Text('Bạn chưa có giao dịch nào.',
                                    style: TextStyle(color: context.textMuted))),
                          ),
                        ])
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _orders.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final o = _orders[i];
                            final payable = o.isPayable();
                            return Card(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => payable ? _resume(o) : _detail(o),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Row(children: [
                                      Expanded(
                                          child: Text(planName(o.planCode),
                                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
                                      StatusPill(orderStatusLabel(o.status), _color(context, o.status)),
                                    ]),
                                    const SizedBox(height: 4),
                                    Text(formatVnd(o.amount),
                                        style: TextStyle(
                                            fontWeight: FontWeight.w800, color: context.cs.primary)),
                                    Text(
                                        '#${o.orderCode}'
                                        '${o.createdAt == null ? '' : '  •  ${fmtDateTime(o.createdAt!)}'}',
                                        style: TextStyle(fontSize: 12.5, color: context.textMuted)),
                                    if (payable)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text('Bấm để tiếp tục thanh toán',
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: context.cs.primary)),
                                      ),
                                  ]),
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
