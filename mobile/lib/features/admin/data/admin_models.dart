// Model của app quản trị: tài khoản (identity-service), kiểm duyệt nội dung và giám sát AI (ai-service),
// thanh toán (payment-service).

double _d(Object? v) => v is num ? v.toDouble() : 0;
int _i(Object? v) => v is num ? v.toInt() : 0;
DateTime? _t(Object? v) => v == null ? null : DateTime.tryParse('$v')?.toLocal();

// ---------------- Kiểm duyệt nội dung (ai-service) ----------------

const moderationTypeLabels = {'BLOG': 'Bài viết', 'VIDEO': 'Video', 'COMMENT': 'Bình luận'};

/// Một ca kiểm duyệt đang chờ admin xử lý (ai-service: ModerationResponse với decision REVIEW_REQUIRED).
class ModerationCase {
  final int caseId;
  final String contentType; // BLOG | VIDEO | COMMENT
  final int? externalContentId;
  final int? authorId;
  final String content; // đoạn văn bản bị AI gắn cờ
  final List<String> categories;
  final String? reason; // giải thích của AI
  final double confidence; // 0..1
  final DateTime? createdAt;

  const ModerationCase({
    required this.caseId,
    required this.contentType,
    this.externalContentId,
    this.authorId,
    this.content = '',
    this.categories = const [],
    this.reason,
    this.confidence = 0,
    this.createdAt,
  });

  factory ModerationCase.fromJson(Map<String, dynamic> j) => ModerationCase(
        caseId: _i(j['caseId']),
        contentType: '${j['contentType'] ?? ''}',
        externalContentId: (j['externalContentId'] as num?)?.toInt(),
        authorId: (j['authorId'] as num?)?.toInt(),
        content: '${j['content'] ?? ''}',
        categories: [for (final c in (j['categories'] as List? ?? const [])) '$c'],
        reason: j['reason'] as String?,
        confidence: _d(j['confidence']),
        createdAt: _t(j['createdAt']),
      );

  String get typeLabel => moderationTypeLabels[contentType] ?? contentType;
}

// ---------------- Giám sát AI (ai-service) ----------------

/// Tổng hợp sử dụng AI trong N ngày gần nhất.
class UsageSummary {
  final int periodDays;
  final int requests;
  final int promptTokens;
  final int completionTokens;
  final double averageLatencyMs;
  final int failedRequests;
  const UsageSummary(this.periodDays, this.requests, this.promptTokens, this.completionTokens,
      this.averageLatencyMs, this.failedRequests);

  factory UsageSummary.fromJson(Map<String, dynamic> j) => UsageSummary(
        _i(j['periodDays']),
        _i(j['requests']),
        _i(j['promptTokens']),
        _i(j['completionTokens']),
        _d(j['averageLatencyMs']),
        _i(j['failedRequests']),
      );

  int get totalTokens => promptTokens + completionTokens;
  double get failureRate => requests == 0 ? 0 : failedRequests / requests;
}

/// Một lượt gọi AI trong nhật ký (ai-service: UsageLog).
class UsageLog {
  final int id;
  final int? userId; // null = khách
  final String feature; // CHAT | MEAL_PLAN | MODERATION | RECOMMENDATION | TRANSCRIPTION | VIDEO
  final String model;
  final String status; // SUCCESS | FAILED
  final int promptTokens;
  final int completionTokens;
  final int latencyMs;
  final String? errorMessage;
  final DateTime? createdAt;

  const UsageLog({
    required this.id,
    this.userId,
    required this.feature,
    required this.model,
    required this.status,
    this.promptTokens = 0,
    this.completionTokens = 0,
    this.latencyMs = 0,
    this.errorMessage,
    this.createdAt,
  });

  factory UsageLog.fromJson(Map<String, dynamic> j) => UsageLog(
        id: _i(j['id']),
        userId: (j['userId'] as num?)?.toInt(),
        feature: '${j['feature'] ?? ''}',
        model: '${j['model'] ?? ''}',
        status: '${j['status'] ?? ''}',
        promptTokens: _i(j['promptTokens']),
        completionTokens: _i(j['completionTokens']),
        latencyMs: _i(j['latencyMs']),
        errorMessage: j['errorMessage'] as String?,
        createdAt: _t(j['createdAt']),
      );

  bool get failed => status != 'SUCCESS';
}

const aiFeatureLabels = {
  'CHAT': 'Chatbot',
  'MEAL_PLAN': 'Thực đơn',
  'MODERATION': 'Kiểm duyệt',
  'RECOMMENDATION': 'Gợi ý',
  'TRANSCRIPTION': 'Chép lời video',
  'VIDEO': 'Bóc tách video',
};

String aiFeatureLabel(String f) => aiFeatureLabels[f] ?? f;

/// Model đang cấu hình cho từng tác vụ (GET /ai/admin/monitoring/models).
const aiModelLabels = {
  'chat': 'Chatbot',
  'mealPlan': 'Thực đơn',
  'moderation': 'Kiểm duyệt',
  'recommendation': 'Gợi ý',
  'videoExtraction': 'Bóc tách video',
  'transcription': 'Chép lời video',
};

/// Giới hạn sử dụng đang áp dụng (GET /ai/admin/monitoring/limits).
const aiLimitLabels = {
  'guestChatRequestsPerDay': 'Lượt chat của khách mỗi ngày',
  'memberChatRequestsPerDay': 'Lượt chat của thành viên mỗi ngày (mặc định)',
  'dailyTokenLimit': 'Giới hạn token mỗi ngày',
  'maxHistoryMessages': 'Số tin nhắn lịch sử gửi kèm',
  'maxInputCharacters': 'Độ dài câu hỏi tối đa (ký tự)',
};

// ---------------- Thanh toán (payment-service) ----------------

const paymentStatusLabels = {
  'PENDING': 'Đang chờ',
  'PAID': 'Đã thanh toán',
  'CANCELLED': 'Đã huỷ',
  'FAILED': 'Thất bại',
};

String paymentStatusLabel(String s) => paymentStatusLabels[s] ?? s;

class PaymentSummary {
  final int totalRevenue;
  final int totalTransactions;
  final int paid;
  final int pending;
  final int cancelled;
  final int failed;
  final int averagePaidAmount;
  const PaymentSummary(this.totalRevenue, this.totalTransactions, this.paid, this.pending, this.cancelled,
      this.failed, this.averagePaidAmount);

  factory PaymentSummary.fromJson(Map<String, dynamic> j) => PaymentSummary(
        _i(j['totalRevenue']),
        _i(j['totalTransactions']),
        _i(j['paidTransactions']),
        _i(j['pendingTransactions']),
        _i(j['cancelledTransactions']),
        _i(j['failedTransactions']),
        _i(j['averagePaidAmount']),
      );
}

/// Một nhóm trong thống kê (theo trạng thái hoặc theo gói).
class Distribution {
  final String key;
  final int count;
  final int amount;
  const Distribution(this.key, this.count, this.amount);

  factory Distribution.fromJson(Map<String, dynamic> j) =>
      Distribution('${j['key']}', _i(j['count']), _i(j['amount']));
}

/// Một điểm doanh thu theo kỳ (ngày hoặc tháng).
class RevenuePoint {
  final String period;
  final int transactionCount;
  final int revenue;
  const RevenuePoint(this.period, this.transactionCount, this.revenue);

  factory RevenuePoint.fromJson(Map<String, dynamic> j) =>
      RevenuePoint('${j['period']}', _i(j['transactionCount']), _i(j['revenue']));
}

class Revenue {
  final int totalRevenue;
  final int paidTransactions;
  final List<RevenuePoint> points;
  const Revenue(this.totalRevenue, this.paidTransactions, this.points);

  factory Revenue.fromJson(Map<String, dynamic> j) => Revenue(
        _i(j['totalRevenue']),
        _i(j['paidTransactions']),
        [
          for (final p in (j['points'] as List? ?? const []))
            RevenuePoint.fromJson(Map<String, dynamic>.from(p as Map)),
        ],
      );
}

/// Thống kê phân bố theo trạng thái và theo gói.
class PaymentStatistics {
  final List<Distribution> byStatus;
  final List<Distribution> byPlan;
  const PaymentStatistics(this.byStatus, this.byPlan);

  factory PaymentStatistics.fromJson(Map<String, dynamic> j) {
    List<Distribution> list(Object? v) => [
          for (final e in (v as List? ?? const []))
            Distribution.fromJson(Map<String, dynamic>.from(e as Map)),
        ];
    return PaymentStatistics(list(j['statusDistribution']), list(j['planDistribution']));
  }
}

/// Một đơn thanh toán (payment-service: AdminPaymentDtos.Order).
class PaymentOrder {
  final int id;
  final int orderCode;
  final int userId;
  final String planCode; // FREE | PLUS | PRO
  final int amount;
  final String status; // PENDING | PAID | CANCELLED | FAILED
  final String? description;
  final DateTime? createdAt;
  final DateTime? paidAt;
  final DateTime? expiredAt;

  const PaymentOrder({
    required this.id,
    required this.orderCode,
    required this.userId,
    required this.planCode,
    required this.amount,
    required this.status,
    this.description,
    this.createdAt,
    this.paidAt,
    this.expiredAt,
  });

  factory PaymentOrder.fromJson(Map<String, dynamic> j) => PaymentOrder(
        id: _i(j['id']),
        orderCode: _i(j['orderCode']),
        userId: _i(j['userId']),
        planCode: '${j['planCode'] ?? ''}',
        amount: _i(j['amount']),
        status: '${j['status'] ?? ''}',
        description: j['description'] as String?,
        createdAt: _t(j['createdAt']),
        paidAt: _t(j['paidAt']),
        expiredAt: _t(j['expiredAt']),
      );
}

// ---------------- Tài khoản người dùng (identity-service) ----------------

const userStatusLabels = {
  'PENDING': 'Chờ kích hoạt',
  'ACTIVE': 'Đang hoạt động',
  'INACTIVE': 'Ngừng hoạt động',
  'BLOCKED': 'Bị khóa',
};

const userRoleLabels = {'USER': 'Thành viên', 'ADMIN': 'Quản trị viên'};

/// Một tài khoản trong danh sách quản trị (identity-service: UserProfileResponse).
class AdminUser {
  final int id;
  final String email;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final String role; // USER | ADMIN
  final String status; // PENDING | ACTIVE | INACTIVE | BLOCKED
  final bool emailVerified;
  final DateTime? createdAt;

  const AdminUser({
    required this.id,
    required this.email,
    this.fullName = '',
    this.phone,
    this.avatarUrl,
    this.role = 'USER',
    this.status = 'ACTIVE',
    this.emailVerified = false,
    this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> j) => AdminUser(
        id: _i(j['id']),
        email: '${j['email'] ?? ''}',
        fullName: '${j['fullName'] ?? ''}',
        phone: j['phone'] as String?,
        avatarUrl: j['avatarUrl'] as String?,
        role: '${j['role'] ?? 'USER'}',
        status: '${j['status'] ?? 'ACTIVE'}',
        emailVerified: j['emailVerified'] == true,
        createdAt: _t(j['createdAt']),
      );

  bool get isAdmin => role == 'ADMIN';
  bool get isBlocked => status == 'BLOCKED';
  String get displayName => fullName.trim().isEmpty ? email : fullName.trim();
  String get roleLabel => userRoleLabels[role] ?? role;
  String get statusLabel => userStatusLabels[status] ?? status;
}
