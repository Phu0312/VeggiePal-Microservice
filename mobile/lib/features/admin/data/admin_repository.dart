import '../../../core/constants/endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../profile/data/profile_models.dart';

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
  Future<List<AdminUser>> users({String? keyword}) async {
    final r = await _api.get(Endpoints.adminUsers, query: {
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      'size': 50,
    });
    return asList(r)
        .map((e) => AdminUser.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // GET /admin/users/{id}
  Future<UserProfile> userDetail(int id) async {
    final r = await _api.get(Endpoints.adminUser(id));
    return UserProfile.fromJson(Map<String, dynamic>.from(r as Map));
  }

  // PATCH /admin/users/{id}/status {status}
  Future<void> setUserStatus(int id, String status) async {
    await _api.patch(Endpoints.adminUserStatus(id), body: {'status': status});
  }

  // GET /admin/moderation/queue?status=PENDING
  Future<List<ModerationItem>> moderationQueue() async {
    final r = await _api.get(Endpoints.moderationQueue, query: {'status': 'PENDING'});
    return asList(r)
        .map((e) => ModerationItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // POST /admin/moderation/{id}/review {decision: APPROVED|REJECTED, reason}
  Future<void> review(int id, bool approve, String reason) async {
    await _api.post(Endpoints.moderationReview(id),
        body: {'decision': approve ? 'APPROVED' : 'REJECTED', 'reason': reason});
  }

  // GET /admin/ai/metrics
  Future<Map<String, dynamic>> aiMetrics() async {
    final r = await _api.get(Endpoints.aiMetrics);
    return Map<String, dynamic>.from(r as Map);
  }
}
