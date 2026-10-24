/// Hồ sơ người dùng (identity-service: UserProfileResponse).
class UserProfile {
  final int id;
  final String email;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final DateTime? dateOfBirth;
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
        role: '${j['role'] ?? 'USER'}',
        status: '${j['status'] ?? ''}',
        emailVerified: j['emailVerified'] == true,
        createdAt: j['createdAt'] == null ? null : DateTime.tryParse('${j['createdAt']}'),
      );
}

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
