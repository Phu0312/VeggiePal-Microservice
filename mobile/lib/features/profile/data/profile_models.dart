/// Hồ sơ người dùng (identity-service: UserProfileResponse).
class UserProfile {
  final int id;
  final String email;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final DateTime? dateOfBirth;
  final String? gender; // MALE | FEMALE | OTHER
  final String? activityLevel; // SEDENTARY | LIGHT | MODERATE | ACTIVE | VERY_ACTIVE
  final String role; // USER | ADMIN
  final String status; // PENDING | ACTIVE | INACTIVE | BLOCKED
  final bool emailVerified;
  final DateTime? createdAt;

  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.avatarUrl,
    this.dateOfBirth,
    this.gender,
    this.activityLevel,
    required this.role,
    required this.status,
    this.emailVerified = false,
    this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        id: (j['id'] as num).toInt(),
        email: '${j['email'] ?? ''}',
        fullName: '${j['fullName'] ?? ''}',
        phone: j['phone'] as String?,
        avatarUrl: j['avatarUrl'] as String?,
        dateOfBirth: j['dateOfBirth'] == null ? null : DateTime.tryParse('${j['dateOfBirth']}'),
        gender: j['gender'] as String?,
        activityLevel: j['activityLevel'] as String?,
        role: '${j['role'] ?? 'USER'}',
        status: '${j['status'] ?? ''}',
        emailVerified: j['emailVerified'] == true,
        createdAt: j['createdAt'] == null ? null : DateTime.tryParse('${j['createdAt']}'),
      );
}

/// Giới tính và mức vận động (identity-service: Gender, ActivityLevel) - backend dùng để tính calo mục tiêu.
const genderLabels = {'MALE': 'Nam', 'FEMALE': 'Nữ', 'OTHER': 'Khác'};
const activityLabels = {
  'SEDENTARY': 'Ít vận động (ngồi nhiều)',
  'LIGHT': 'Vận động nhẹ (1-3 buổi/tuần)',
  'MODERATE': 'Vận động vừa (3-5 buổi/tuần)',
  'ACTIVE': 'Vận động nhiều (6-7 buổi/tuần)',
  'VERY_ACTIVE': 'Vận động rất nhiều (lao động nặng)',
};

/// Thông tin công khai của tác giả (GET /users/batch): không có email/SĐT.
class PublicUser {
  final int id;
  final String fullName;
  final String? avatarUrl;
  const PublicUser(this.id, this.fullName, this.avatarUrl);

  factory PublicUser.fromJson(Map<String, dynamic> j) => PublicUser(
      (j['id'] as num).toInt(), '${j['fullName'] ?? ''}', j['avatarUrl'] as String?);
}

/// Một chất gây dị ứng trong danh mục (nutrition-service: AllergenResponse).
class Allergen {
  final int id;
  final String code;
  final String name;
  final String category;

  const Allergen(this.id, this.code, this.name, this.category);

  factory Allergen.fromJson(Map<String, dynamic> j) => Allergen(
      (j['id'] as num).toInt(), '${j['code']}', '${j['name']}', '${j['category']}');

  /// Thứ tự hiển thị các nhóm (theo thứ tự khai báo ở backend) và tên tiếng Việt.
  static const categoryLabels = {
    'GRAIN': 'Ngũ cốc',
    'LEGUME': 'Đậu',
    'NUT_SEED': 'Hạt',
    'VEGETABLE': 'Rau củ',
    'FRUIT': 'Trái cây',
    'MUSHROOM': 'Nấm',
    'SPICE': 'Gia vị',
    'ADDITIVE': 'Phụ gia',
  };
}

/// Một bản ghi chiều cao/cân nặng (nutrition-service: HealthRecordResponse).
class HealthRecord {
  final int id;
  final double heightCm;
  final double weightKg;
  final double bmi;
  final DateTime? recordedAt;

  const HealthRecord(this.id, this.heightCm, this.weightKg, this.bmi, this.recordedAt);

  factory HealthRecord.fromJson(Map<String, dynamic> j) => HealthRecord(
        (j['id'] as num).toInt(),
        (j['heightCm'] as num).toDouble(),
        (j['weightKg'] as num).toDouble(),
        (j['bmi'] as num).toDouble(),
        j['recordedAt'] == null ? null : DateTime.tryParse('${j['recordedAt']}'),
      );
}

// ---------------- Yêu thích và huy hiệu (identity-service) ----------------

/// Loại mục có thể lưu vào danh sách yêu thích (identity-service: FavoriteTargetType).
enum FavoriteType {
  recipe('RECIPE', 'Công thức'),
  blog('BLOG', 'Bài viết'),
  video('VIDEO', 'Video');

  final String code;
  final String label;
  const FavoriteType(this.code, this.label);

  static FavoriteType? fromCode(String? code) {
    for (final t in values) {
      if (t.code == code) return t;
    }
    return null;
  }
}

/// Một mục yêu thích: chỉ lưu tiêu đề và ảnh tại thời điểm lưu, nội dung đầy đủ mở lại theo [targetId].
class FavoriteItem {
  final int id;
  final FavoriteType type;
  final int targetId;
  final String title;
  final String? imageUrl;
  final DateTime? createdAt;

  const FavoriteItem(
      {required this.id,
      required this.type,
      required this.targetId,
      required this.title,
      this.imageUrl,
      this.createdAt});

  /// Null nếu BE trả loại mà app chưa biết.
  static FavoriteItem? tryParse(Map<String, dynamic> j) {
    final type = FavoriteType.fromCode(j['targetType'] as String?);
    if (type == null) return null;
    return FavoriteItem(
      id: (j['id'] as num?)?.toInt() ?? 0,
      type: type,
      targetId: (j['targetId'] as num).toInt(),
      title: '${j['title'] ?? ''}',
      imageUrl: j['imageUrl'] as String?,
      createdAt: j['createdAt'] == null ? null : DateTime.tryParse('${j['createdAt']}'),
    );
  }
}

/// Một huy hiệu xanh và trạng thái đã đạt (identity-service: BadgeItemResponse).
class GreenBadge {
  final String code;
  final String title;
  final String description;
  final String icon; // tên biểu tượng: sprout | check | user | calendar | droplets | sparkles
  final bool earned;
  final DateTime? earnedAt;

  const GreenBadge(
      {required this.code,
      required this.title,
      required this.description,
      required this.icon,
      required this.earned,
      this.earnedAt});

  factory GreenBadge.fromJson(Map<String, dynamic> j) => GreenBadge(
        code: '${j['code'] ?? ''}',
        title: '${j['title'] ?? ''}',
        description: '${j['description'] ?? ''}',
        icon: '${j['icon'] ?? ''}',
        earned: j['earned'] == true,
        earnedAt: j['earnedAt'] == null ? null : DateTime.tryParse('${j['earnedAt']}'),
      );
}

class BadgeCollection {
  final int earnedCount;
  final int totalCount;
  final List<GreenBadge> badges;
  const BadgeCollection(this.earnedCount, this.totalCount, this.badges);

  factory BadgeCollection.fromJson(Map<String, dynamic> j) => BadgeCollection(
        (j['earnedCount'] as num?)?.toInt() ?? 0,
        (j['totalCount'] as num?)?.toInt() ?? 0,
        [for (final b in (j['badges'] as List? ?? const [])) GreenBadge.fromJson(Map<String, dynamic>.from(b as Map))],
      );
}
