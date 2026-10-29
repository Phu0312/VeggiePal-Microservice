import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/common_widgets.dart';
import '../data/payment_models.dart';
import '../data/payment_repository.dart';
import '../data/subscription_controller.dart';

/// Thanh toán một đơn bằng VietQR (PayOS): mã QR, đếm ngược hết hạn, thông tin chuyển khoản có nút sao chép.
/// Màn hỏi lại GET /payments/orders/{id} mỗi 2,5 giây; khi webhook PayOS đánh dấu đơn PAID thì gói đã được kích hoạt
/// và màn chuyển sang thông báo thành công. Quá hạn thì mời tạo lại mã. Trả về true qua Navigator.pop nếu đã thanh toán.
class CheckoutScreen extends StatefulWidget {
  final UserOrder order;
  const CheckoutScreen({super.key, required this.order});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const _pollEvery = Duration(milliseconds: 2500);

  late UserOrder _order = widget.order;
  Timer? _poll;
  Timer? _tick;
  DateTime _now = DateTime.now();
  bool _polling = false;
  int _pollFailures = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _startTimers();
  }

  @override
  void dispose() {
    _stopTimers();
    super.dispose();
  }

  void _startTimers() {
    _stopTimers();
    if (!_order.isPending) return;
    _poll = Timer.periodic(_pollEvery, (_) => _check());
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  void _stopTimers() {
    _poll?.cancel();
    _tick?.cancel();
    _poll = _tick = null;
  }

  Future<void> _check() async {
    if (_polling || !mounted) return;
    _polling = true;
    try {
      final o = await context.read<PaymentRepository>().order(_order.id);
      if (!mounted) return;
      _pollFailures = 0;
      _apply(o);
    } catch (_) {
      // Lỗi mạng thoáng qua: thử lại ở lượt sau, chỉ báo khi lỗi liên tục.
      if (mounted) setState(() => _pollFailures++);
    } finally {
      _polling = false;
    }
  }

  void _apply(UserOrder o) {
    setState(() => _order = o);
    if (o.isPending) return;
    _stopTimers();
    if (o.status == 'PAID') {
      context.read<SubscriptionController>().refresh(); // gói mới có hiệu lực ngay
    } else if (o.status == 'CANCELLED') {
      Navigator.of(context).pop(false);
    }
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Huỷ thanh toán?'),
        content: const Text('Đơn này sẽ bị huỷ và mã QR không còn dùng được. Bạn có thể chọn gói lại bất cứ lúc nào.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Huỷ đơn')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final o = await context.read<PaymentRepository>().cancel(_order.id);
      if (!mounted) return;
      _stopTimers();
      // Khách vừa thanh toán xong ngay lúc bấm huỷ thì backend trả 6008 và đơn đã PAID.
      if (o.status == 'CANCELLED') {
        Navigator.of(context).pop(false);
      } else {
        _apply(o);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      await showErrorDialog(context, errorMessage(e), title: 'Không huỷ được đơn');
      if (mounted) _check(); // có thể đơn đã được thanh toán hoặc huỷ ở nơi khác
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _recreate() async {
    setState(() => _busy = true);
    try {
      final next = await context.read<PaymentRepository>().checkout(_order.planCode);
      if (!mounted) return;
      setState(() {
        _order = next;
        _now = DateTime.now();
        _pollFailures = 0;
      });
      _startTimers();
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e), title: 'Không tạo lại được mã');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openPayOs() async {
    final url = _order.checkoutUrl;
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) showSnack(context, 'Không mở được trang thanh toán PayOS');
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = _order;
    final Widget body;
    if (o.status == 'PAID') {
      body = _Success(o);
    } else if (o.status == 'FAILED') {
      body = _Message(
        icon: LucideIcons.circleX,
        color: context.cs.error,
        title: 'Thanh toán thất bại',
        text: 'Giao dịch không thành công. Bạn có thể quay lại và thử thanh toán lại.',
        actions: [FilledButton(onPressed: () => Navigator.pop(context, false), child: const Text('Quay lại'))],
      );
    } else if (!o.isPending) {
      body = const Center(child: CircularProgressIndicator()); // đang đóng màn (đơn đã huỷ)
    } else if (!o.isPayable(_now)) {
      body = _Message(
        icon: LucideIcons.clock,
        color: Colors.orange,
        title: 'Mã QR đã hết hạn',
        text: 'Đơn ${planName(o.planCode)} đã quá thời gian thanh toán. Hãy tạo lại mã QR mới để tiếp tục.',
        actions: [
          FilledButton.icon(
            onPressed: _busy ? null : _recreate,
            icon: _busy
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(LucideIcons.refreshCw),
            label: const Text('Tạo lại mã'),
          ),
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Quay lại')),
        ],
      );
    } else {
      body = _QrView(
        order: o,
        now: _now,
        busy: _busy,
        connectionTrouble: _pollFailures >= 3,
        onCancel: _cancel,
        onOpenPayOs: _openPayOs,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: body,
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String text;
  final List<Widget> actions;
  const _Message(
      {required this.icon, required this.color, required this.title, required this.text, required this.actions});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(text, textAlign: TextAlign.center, style: TextStyle(color: context.textMuted)),
            const SizedBox(height: 20),
            ...actions,
          ]),
        ),
      );
}

class _Success extends StatelessWidget {
  final UserOrder order;
  const _Success(this.order);

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<SubscriptionController>().subscription;
    final expires = sub != null && sub.planCode == order.planCode ? sub.expiresAt : null;
    return _Message(
      icon: LucideIcons.circleCheck,
      color: Colors.green,
      title: 'Thanh toán thành công',
      text: '${planName(order.planCode)} đã được kích hoạt cho tài khoản của bạn.'
          '${expires == null ? '' : '\nHạn sử dụng đến ${fmtDateTime(expires)}.'}'
          '\nSố tiền: ${formatVnd(order.amount)}.',
      actions: [FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hoàn tất'))],
    );
  }
}

class _QrView extends StatelessWidget {
  final UserOrder order;
  final DateTime now;
  final bool busy;
  final bool connectionTrouble;
  final VoidCallback onCancel;
  final VoidCallback onOpenPayOs;
  const _QrView({
    required this.order,
    required this.now,
    required this.busy,
    required this.connectionTrouble,
    required this.onCancel,
    required this.onOpenPayOs,
  });

  Widget _info(BuildContext context, String label, String? value, {bool strong = false, String? copy}) {
    final shown = (value ?? '').isEmpty ? '-' : value!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 12, color: context.textMuted)),
            Text(shown,
                style: TextStyle(
                    fontSize: strong ? 18 : 14.5,
                    fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
                    color: strong ? context.cs.primary : null)),
          ]),
        ),
        if (copy != null && copy.isNotEmpty)
          IconButton(
            tooltip: 'Sao chép',
            icon: const Icon(LucideIcons.copy, size: 18),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: copy));
              if (context.mounted) showSnack(context, 'Đã sao chép $label');
            },
          ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final o = order;
    return ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 32), children: [
      Text('Quét mã để thanh toán',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text('Mở app ngân hàng và quét mã VietQR bên dưới. Gói sẽ tự kích hoạt sau khi thanh toán thành công.',
          textAlign: TextAlign.center, style: TextStyle(color: context.textMuted)),
      const SizedBox(height: 16),
      Center(
        // Nền trắng cố định để mã QR luôn quét được ở chế độ tối.
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: QrImageView(data: o.qrCode!, size: 240, backgroundColor: Colors.white),
        ),
      ),
      const SizedBox(height: 12),
      if (o.expiredAt != null)
        Center(
          child: Text('Hết hạn sau ${formatCountdown(o.expiredAt!, now)}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()])),
        ),
      const SizedBox(height: 4),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
        const SizedBox(width: 8),
        Text('Đang chờ thanh toán...', style: TextStyle(fontSize: 13, color: context.textMuted)),
      ]),
      if (connectionTrouble)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('Chưa kết nối được máy chủ để kiểm tra, đang thử lại...',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: context.cs.error)),
        ),
      const SizedBox(height: 16),
      Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(children: [
            _info(context, 'Gói', planName(o.planCode)),
            _info(context, 'Số tiền', formatVnd(o.amount), strong: true, copy: '${o.amount}'),
            _info(context, 'Chủ tài khoản', o.accountName, copy: o.accountName),
            _info(context, 'Số tài khoản', o.accountNumber, copy: o.accountNumber),
            _info(context, 'Ngân hàng', o.bankName),
            _info(context, 'Nội dung chuyển khoản', o.description, copy: o.description),
          ]),
        ),
      ),
      const SizedBox(height: 8),
      Text('Giữ nguyên số tiền và nội dung chuyển khoản để hệ thống tự xác nhận.',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: context.textMuted)),
      const SizedBox(height: 16),
      if ((o.checkoutUrl ?? '').isNotEmpty)
        OutlinedButton.icon(
          onPressed: onOpenPayOs,
          icon: const Icon(LucideIcons.externalLink),
          label: const Text('Mở trang thanh toán PayOS'),
        ),
      const SizedBox(height: 8),
      TextButton.icon(
        onPressed: busy ? null : onCancel,
        style: TextButton.styleFrom(foregroundColor: context.cs.error),
        icon: busy
            ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(LucideIcons.x),
        label: const Text('Huỷ thanh toán'),
      ),
    ]);
  }
}
