import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/paged_list_view.dart';
import '../data/admin_models.dart';
import '../data/admin_repository.dart';

Color _statusColor(BuildContext context, String status) => switch (status) {
      'PAID' => Colors.green,
      'PENDING' => Colors.orange,
      'CANCELLED' => context.textMuted,
      _ => context.cs.error,
    };

/// Thanh toán (admin, payment-service): "Tổng quan" (số liệu, doanh thu theo kỳ, phân bố theo gói / trạng thái)
/// và "Đơn hàng" (danh sách phân trang có lọc trạng thái, xem chi tiết). Bộ lọc kỳ và gói áp dụng cho cả hai phần.
/// Doanh thu chỉ tính các đơn đã thanh toán.
class AdminPaymentsTab extends StatefulWidget {
  const AdminPaymentsTab({super.key});

  @override
  State<AdminPaymentsTab> createState() => _AdminPaymentsTabState();
}

class _AdminPaymentsTabState extends State<AdminPaymentsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static const _periods = <int?, String>{7: '7 ngày', 30: '30 ngày', 90: '90 ngày', null: 'Tất cả'};
  static const _plans = <String?, String>{null: 'Mọi gói', 'PLUS': 'PLUS', 'PRO': 'PRO'};
  static const _statuses = <String?, String>{
    null: 'Mọi trạng thái',
    'PAID': 'Đã thanh toán',
    'PENDING': 'Đang chờ',
    'CANCELLED': 'Đã huỷ',
    'FAILED': 'Thất bại',
  };

  int? _days = 30;
  String? _plan;
  String? _status;
  DateTime? _from = DateTime.now().subtract(const Duration(days: 30));
  bool _showOrders = false;

  PaymentSummary? _summary;
  PaymentStatistics? _stats;
  Revenue? _revenue;
  bool _loading = true;
  bool _failed = false;
  int _generation = 0;

  final _orders = GlobalKey<PagedListViewState<PaymentOrder>>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Gom bộ lọc kỳ + gói thành một lần tải lại (đặt lại mốc thời gian theo "bây giờ").
  void _applyFilters({int? days, String? plan, bool setDays = false, bool setPlan = false}) {
    setState(() {
      if (setDays) {
        _days = days;
        _from = days == null ? null : DateTime.now().subtract(Duration(days: days));
      }
      if (setPlan) _plan = plan;
    });
    _load();
    _orders.currentState?.reload();
  }

  Future<void> _load() async {
    final gen = ++_generation;
    setState(() {
      _loading = true;
      _failed = false;
    });
    final repo = context.read<AdminRepository>();
    try {
      final r = await Future.wait<Object>([
        repo.paymentSummary(from: _from, planCode: _plan),
        repo.paymentStatistics(from: _from, planCode: _plan),
        repo.paymentRevenue(from: _from, planCode: _plan, groupBy: (_days ?? 365) > 30 ? 'MONTH' : 'DAY'),
      ]);
      if (!mounted || gen != _generation) return;
      setState(() {
        _summary = r[0] as PaymentSummary;
        _stats = r[1] as PaymentStatistics;
        _revenue = r[2] as Revenue;
      });
    } catch (e) {
      if (!mounted || gen != _generation) return;
      setState(() => _failed = true);
      showErrorDialog(context, errorMessage(e), title: 'Không tải được số liệu thanh toán');
    } finally {
      if (mounted && gen == _generation) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(children: [
      const SizedBox(height: 8),
      FilterRow(children: [
        FilterDropdown<int?>(
          options: _periods,
          selected: _days,
          onChanged: (v) => _applyFilters(days: v, setDays: true),
        ),
        FilterDropdown<String?>(
          options: _plans,
          selected: _plan,
          onChanged: (v) => _applyFilters(plan: v, setPlan: true),
        ),
      ]),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: FullWidthSegmented<bool>(
          options: const [SegmentOption(false, 'Tổng quan'), SegmentOption(true, 'Đơn hàng')],
          selected: _showOrders,
          onChanged: (v) => setState(() => _showOrders = v),
        ),
      ),
      Expanded(child: _showOrders ? _ordersView() : _overview()),
    ]);
  }

  // ---------------- Tổng quan ----------------

  Widget _overview() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final s = _summary, st = _stats, rv = _revenue;
    if (_failed || s == null || st == null || rv == null) return RetryView(onRetry: _load);

    Widget tile(String label, String value, {Color? color}) => Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              FittedBox(
                child: Text(value,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color ?? context.cs.primary)),
              ),
              const SizedBox(height: 2),
              Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: context.textMuted)),
            ]),
          ),
        );

    final maxRevenue = rv.points.fold<int>(0, (m, p) => p.revenue > m ? p.revenue : m);
    final points = rv.points.length > 14 ? rv.points.sublist(rv.points.length - 14) : rv.points;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.1,
          children: [
            tile('Doanh thu', formatVnd(s.totalRevenue)),
            tile('Tổng giao dịch', formatCount(s.totalTransactions)),
            tile('Đã thanh toán', formatCount(s.paid), color: Colors.green),
            tile('Đang chờ', formatCount(s.pending), color: Colors.orange),
            tile('Đã huỷ', formatCount(s.cancelled), color: context.textMuted),
            tile('Thất bại', formatCount(s.failed), color: context.cs.error),
          ],
        ),
        const SizedBox(height: 4),
        Text('Trung bình mỗi đơn đã thanh toán: ${formatVnd(s.averagePaidAmount)}',
            style: TextStyle(fontSize: 12.5, color: context.textMuted)),
        const SectionHeader('Doanh thu theo kỳ'),
        if (points.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Chưa có doanh thu trong khoảng này.', style: TextStyle(color: context.textMuted)),
          )
        else
          for (final p in points)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(children: [
                SizedBox(width: 78, child: Text(p.period, style: const TextStyle(fontSize: 12.5))),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      minHeight: 14,
                      value: maxRevenue == 0 ? 0 : p.revenue / maxRevenue,
                      backgroundColor: context.cs.surfaceContainerHighest.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                    width: 92,
                    child: Text(formatVnd(p.revenue),
                        textAlign: TextAlign.right, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
              ]),
            ),
        const SectionHeader('Theo gói'),
        _distribution(st.byPlan, (k) => k),
        const SectionHeader('Theo trạng thái'),
        _distribution(st.byStatus, paymentStatusLabel),
      ]),
    );
  }

  Widget _distribution(List<Distribution> items, String Function(String) label) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text('Không có dữ liệu.', style: TextStyle(color: context.textMuted)),
      );
    }
    return Column(children: [
      for (final d in items)
        ListTile(
          dense: true,
          title: Text(label(d.key)),
          subtitle: Text('${formatCount(d.count)} giao dịch'),
          trailing: Text(formatVnd(d.amount), style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
    ]);
  }

  // ---------------- Đơn hàng ----------------

  Widget _ordersView() {
    final repo = context.read<AdminRepository>();
    return Column(children: [
      FilterRow(children: [
        FilterDropdown<String?>(
          options: _statuses,
          selected: _status,
          onChanged: (v) {
            setState(() => _status = v);
            _orders.currentState?.reload();
          },
        ),
      ]),
      Expanded(
        child: PagedListView<PaymentOrder>(
          key: _orders,
          errorTitle: 'Không tải được danh sách đơn hàng',
          load: (page) => repo.paymentOrders(status: _status, from: _from, planCode: _plan, page: page),
          emptyText: 'Không có đơn hàng nào trong bộ lọc này.',
          itemBuilder: (context, o) => Card(
            child: ListTile(
              onTap: () => _showOrder(o),
              title: Row(children: [
                Text('#${o.orderCode}', style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Text(o.planCode, style: TextStyle(color: context.cs.primary, fontWeight: FontWeight.w700)),
                const Spacer(),
                StatusPill(paymentStatusLabel(o.status), _statusColor(context, o.status)),
              ]),
              subtitle: Text(
                  '${formatVnd(o.amount)}  •  Người dùng #${o.userId}'
                  '${o.createdAt == null ? '' : '\n${fmtDateTime(o.createdAt!)}'}'),
              isThreeLine: o.createdAt != null,
            ),
          ),
        ),
      ),
    ]);
  }

  void _showOrder(PaymentOrder o) {
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
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Đơn #${o.orderCode}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            row('Trạng thái', paymentStatusLabel(o.status)),
            row('Gói', o.planCode),
            row('Số tiền', formatVnd(o.amount)),
            row('Người dùng', '#${o.userId}'),
            row('Nội dung', (o.description ?? '').isEmpty ? '-' : o.description!),
            row('Tạo lúc', when(o.createdAt)),
            row('Thanh toán lúc', when(o.paidAt)),
            row('Hết hạn lúc', when(o.expiredAt)),
          ]),
        ),
      ),
    );
  }
}
