// Gói thành viên và thanh toán PayOS VietQR (payment-service: `/payments`, `/subscriptions`).

DateTime? _t(Object? v) => v == null ? null : DateTime.tryParse('$v')?.toLocal();
int _i(Object? v) => v is num ? v.toInt() : 0;

/// Tên hiển thị của các gói.
const planNames = {'FREE': 'Gói Khám Phá', 'PLUS': 'Gói Plus', 'PRO': 'Gói Pro Chuyên Sâu'};

String planName(String code) => planNames[code] ?? 'Gói $code';

/// Một gói thành viên (payment-service: PlanResponse) cùng hạn mức sử dụng.
class Plan {
  final int id;
  final String code; // FREE | PLUS | PRO
  final int price; // VND
  final int durationDays;
  final int chatPerDay;
  final int mealPlansPerMonth;
  final int videosPerMonth;

  const Plan({
    required this.id,
    required this.code,
    required this.price,
    required this.durationDays,
    required this.chatPerDay,
    required this.mealPlansPerMonth,
    required this.videosPerMonth,
  });

  factory Plan.fromJson(Map<String, dynamic> j) => Plan(
        id: _i(j['id']),
        code: '${j['code']}',
        price: _i(j['price']),
        durationDays: _i(j['durationDays']),
        chatPerDay: _i(j['chatPerDay']),
        mealPlansPerMonth: _i(j['mealPlansPerMonth']),
        videosPerMonth: _i(j['videosPerMonth']),
      );

  bool get isFree => code == 'FREE' || price <= 0;
}

/// Gói đang hiệu lực của người dùng (payment-service: SubscriptionResponse). Gói FREE không có hạn.
class Subscription {
  final String planCode;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final int chatPerDay;
  final int mealPlansPerMonth;
  final int videosPerMonth;

  const Subscription({
    required this.planCode,
    this.startedAt,
    this.expiresAt,
    required this.chatPerDay,
    required this.mealPlansPerMonth,
    required this.videosPerMonth,
  });

  factory Subscription.fromJson(Map<String, dynamic> j) => Subscription(
        planCode: '${j['planCode'] ?? 'FREE'}',
        startedAt: _t(j['startedAt']),
        expiresAt: _t(j['expiresAt']),
        chatPerDay: _i(j['chatPerDay']),
        mealPlansPerMonth: _i(j['mealPlansPerMonth']),
        videosPerMonth: _i(j['videosPerMonth']),
      );

  bool get isPaid => planCode != 'FREE';
}

const _statusLabels = {
  'PENDING': 'Chưa thanh toán',
  'PAID': 'Đã thanh toán',
  'CANCELLED': 'Đã huỷ',
  'FAILED': 'Thất bại',
};

String orderStatusLabel(String status) => _statusLabels[status] ?? status;

/// Một đơn thanh toán của tôi (payment-service: PaymentOrderResponse).
class UserOrder {
  final int id; // id nội bộ (khác orderCode của PayOS)
  final int orderCode;
  final String planCode;
  final int amount;
  final String status; // PENDING | PAID | CANCELLED | FAILED
  final String? checkoutUrl;
  final String? qrCode; // chuỗi VietQR để dựng mã QR
  final String? accountName;
  final String? accountNumber;
  final String? bin;
  final String? description; // nội dung chuyển khoản
  final DateTime? expiredAt;
  final DateTime? createdAt;
  final DateTime? paidAt;

  const UserOrder({
    required this.id,
    required this.orderCode,
    required this.planCode,
    required this.amount,
    required this.status,
    this.checkoutUrl,
    this.qrCode,
    this.accountName,
    this.accountNumber,
    this.bin,
    this.description,
    this.expiredAt,
    this.createdAt,
    this.paidAt,
  });

  factory UserOrder.fromJson(Map<String, dynamic> j) => UserOrder(
        id: _i(j['id'] ?? j['orderId']),
        orderCode: _i(j['orderCode']),
        planCode: '${j['planCode'] ?? ''}',
        amount: _i(j['amount']),
        status: '${j['status'] ?? ''}',
        checkoutUrl: j['checkoutUrl'] as String?,
        qrCode: j['qrCode'] as String?,
        accountName: j['accountName'] as String?,
        accountNumber: j['accountNumber'] as String?,
        bin: j['bin'] == null ? null : '${j['bin']}',
        description: j['description'] as String?,
        expiredAt: _t(j['expiredAt']),
        createdAt: _t(j['createdAt']),
        paidAt: _t(j['paidAt']),
      );

  bool get isPending => status == 'PENDING';

  /// Còn dùng được mã QR để thanh toán: chưa thanh toán, có mã QR và chưa quá hạn.
  bool isPayable([DateTime? now]) =>
      isPending && (qrCode ?? '').isNotEmpty && (expiredAt == null || expiredAt!.isAfter(now ?? DateTime.now()));

  String get bankName => bankNameOf(bin);
}

// Các ngân hàng VietQR phổ biến theo mã BIN (cùng danh sách với bản web).
const _banks = {
  '970415': 'VietinBank',
  '970436': 'Vietcombank',
  '970418': 'BIDV',
  '970405': 'Agribank',
  '970422': 'MB Bank',
  '970407': 'Techcombank',
  '970416': 'ACB',
  '970432': 'VPBank',
  '970423': 'TPBank',
  '970403': 'Sacombank',
  '970437': 'HDBank',
  '970441': 'VIB',
  '970443': 'SHB',
  '970448': 'OCB',
  '970426': 'MSB',
  '970431': 'Eximbank',
  '970454': 'Viet Capital Bank',
  '970429': 'SCB',
  '970440': 'SeABank',
  '970452': 'KienlongBank',
  '970414': 'Oceanbank',
  '970425': 'ABBank',
  '970419': 'NCB',
  '970428': 'Nam A Bank',
  '970449': 'LPBank',
  '970438': 'BaoViet Bank',
  '970400': 'SaigonBank',
  '970412': 'PVcomBank',
  '970409': 'BacABank',
  '970427': 'VietABank',
  '970433': 'VietBank',
  '970446': 'COOPBANK',
  '970424': 'Shinhan Bank',
  '970434': 'Indovina Bank',
  '546034': 'CAKE by VPBank',
  '546035': 'Ubank by VPBank',
  '963388': 'Timo',
  '971005': 'Viettel Money',
  '971011': 'VNPT Money',
};

String bankNameOf(String? bin) {
  if (bin == null || bin.isEmpty) return '-';
  return _banks[bin] ?? 'Ngân hàng (BIN $bin)';
}

/// Đếm ngược "mm:ss" tới [to]; về 00:00 khi đã quá hạn.
String formatCountdown(DateTime to, [DateTime? now]) {
  final total = to.difference(now ?? DateTime.now()).inSeconds.clamp(0, 1 << 30);
  return '${(total ~/ 60).toString().padLeft(2, '0')}:${(total % 60).toString().padLeft(2, '0')}';
}
