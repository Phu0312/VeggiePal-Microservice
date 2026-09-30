import '../../../core/constants/endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/mock_fallback.dart';

class AdminUser {
  final int id;
  final String email;
  final String fullName;
  final String role;
  final String status; // PENDING | ACTIVE | INACTIVE | BLOCKED
  const AdminUser(this.id, this.email, this.fullName, this.role, this.status);

  factory AdminUser.fromJson(Map<String, dynamic> j) => AdminUser(
        (j['id'] as num).toInt(),
        '${j['email']}',
        '${j['fullName'] ?? ''}',
        '${j['role']}',
        '${j['status']}',
      );

  AdminUser copyWith({String? status}) => AdminUser(id, email, fullName, role, status ?? this.status);
}

/// Một mục trong hàng đợi kiểm duyệt (blog / video / bình luận bị cờ báo).
class ModerationItem {
  final int id;
  final String targetType; // BLOG | VIDEO | COMMENT
  final int targetId;
  final String snippet;
  final String keywords;
  const ModerationItem(this.id, this.targetType, this.targetId, this.snippet, this.keywords);

  factory ModerationItem.fromJson(Map<String, dynamic> j) => ModerationItem(
        (j['id'] as num).toInt(),
        '${j['targetType']}',
        (j['targetId'] as num).toInt(),
        '${j['contentSnippet'] ?? ''}',
        '${j['matchedKeywords'] ?? ''}',
      );
}

class AdminRepository {
  final ApiClient _api;
  AdminRepository(this._api);

  // GET /admin/users?keyword= (Spring Page -> `content`)
  Future<List<AdminUser>> users({String? keyword}) => withFallback(() async {
        final r = await _api.get(Endpoints.adminUsers, query: {
          if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
          'size': 50,
        });
        return asList(r)
            .map((e) => AdminUser.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }, () => _mockUsers);

  // PATCH /admin/users/{id}/status {status}
  Future<void> setUserStatus(int id, String status) => withFallback(() async {
        await _api.patch(Endpoints.adminUserStatus(id), body: {'status': status});
      }, () {});

  // GET /admin/moderation/queue?status=PENDING
  Future<List<ModerationItem>> moderationQueue() => withFallback(() async {
        final r = await _api.get(Endpoints.moderationQueue, query: {'status': 'PENDING'});
        return asList(r)
            .map((e) => ModerationItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }, () => _mockQueue);

  // POST /admin/moderation/{id}/review {decision: APPROVED|REJECTED, reason}
  Future<void> review(int id, bool approve, String reason) => withFallback(() async {
        await _api.post(Endpoints.moderationReview(id),
            body: {'decision': approve ? 'APPROVED' : 'REJECTED', 'reason': reason});
      }, () {});

  // POST /categories {name, type, parentId, displayOrder, active}
  Future<void> createCategory(String name, String type) => withFallback(() async {
        await _api.post(Endpoints.categories,
            body: {'name': name, 'type': type, 'displayOrder': 0, 'active': true});
      }, () {});

  // GET /admin/ai/metrics
  Future<Map<String, dynamic>> aiMetrics() => withFallback(() async {
        final r = await _api.get(Endpoints.aiMetrics);
        return Map<String, dynamic>.from(r as Map);
      }, () => {
            'totalRequests': 128,
            'successCount': 121,
            'failureCount': 7,
            'chatRequests': 84,
            'mealPlanRequests': 31,
            'moderationRequests': 9,
            'videoSummaryRequests': 4,
          });

  static const _mockUsers = [
    AdminUser(1, 'admin@veggiepal.com', 'Quản trị viên', 'ADMIN', 'ACTIVE'),
    AdminUser(2, 'user@veggiepal.com', 'Nguyễn Văn An', 'USER', 'ACTIVE'),
    AdminUser(3, 'user2@veggiepal.com', 'Trần Thị Bình', 'USER', 'ACTIVE'),
    AdminUser(4, 'spam@example.com', 'Tài khoản spam', 'USER', 'BLOCKED'),
  ];

  static const _mockQueue = [
    ModerationItem(1, 'BLOG', 12, 'Ăn chay giúp chữa khỏi mọi bệnh, không cần thuốc...', 'chữa khỏi'),
    ModerationItem(2, 'COMMENT', 45, 'Link mua hàng giảm giá tại đây!!!', 'link, giảm giá'),
    ModerationItem(3, 'VIDEO', 7, 'Video quảng cáo thực phẩm chức năng giảm cân cấp tốc', 'giảm cân cấp tốc'),
  ];
}
