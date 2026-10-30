/// Ba vai trò dùng cho phân quyền giao diện.
enum UserRole { guest, user, admin }

class AuthUser {
  final int id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? avatarUrl;

  /// Email đã xác minh bằng mã OTP chưa. Lấy từ `emailVerified` của LoginResponse; thiếu trường này thì mặc định
  /// `true` (không nhắc nhầm). AuthController vẫn nạp lại từ GET /users/me sau khi đăng nhập.
  final bool emailVerified;

  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.avatarUrl,
    this.emailVerified = true,
  });

  AuthUser copyWith({String? fullName, String? avatarUrl, UserRole? role, bool? emailVerified}) => AuthUser(
        id: id,
        email: email,
        fullName: fullName ?? this.fullName,
        role: role ?? this.role,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        emailVerified: emailVerified ?? this.emailVerified,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'role': role.name,
        'avatarUrl': avatarUrl,
        'emailVerified': emailVerified,
      };

  factory AuthUser.fromStored(Map<String, dynamic> j) => AuthUser(
        id: (j['id'] as num).toInt(),
        email: '${j['email'] ?? ''}',
        fullName: '${j['fullName'] ?? ''}',
        role: UserRole.values.firstWhere((r) => r.name == j['role'], orElse: () => UserRole.user),
        avatarUrl: j['avatarUrl'] as String?,
        emailVerified: j['emailVerified'] != false,
      );

  /// Chữ cái đầu hiển thị khi chưa có ảnh đại diện.
  String get initial {
    final n = fullName.trim().isNotEmpty ? fullName.trim() : email.trim();
    return n.isEmpty ? '?' : n[0].toUpperCase();
  }

  /// Map từ `LoginResponse` của identity-service: userId, email, emailVerified, fullName, role.
  factory AuthUser.fromLogin(Map<String, dynamic> j) => AuthUser(
        id: (j['userId'] as num?)?.toInt() ?? 0,
        email: '${j['email'] ?? ''}',
        fullName: '${j['fullName'] ?? ''}',
        role: '${j['role']}'.toUpperCase().contains('ADMIN')
            ? UserRole.admin
            : UserRole.user,
        emailVerified: j['emailVerified'] != false,
      );
}

class AuthSession {
  final String token;
  final AuthUser user;

  /// Mã làm mới phiên (`refreshToken` của LoginResponse). Null nếu BE không cấp.
  final String? refreshToken;
  const AuthSession(this.token, this.user, {this.refreshToken});

  /// Map từ `LoginResponse` của identity-service (dùng cho login, Google và refresh).
  factory AuthSession.fromLogin(Map<String, dynamic> j) {
    final refresh = j['refreshToken'];
    return AuthSession('${j['accessToken']}', AuthUser.fromLogin(j),
        refreshToken: refresh is String && refresh.isNotEmpty ? refresh : null);
  }
}

/// Phản hồi gửi mã OTP: BE trả cùng một câu dù email có tồn tại hay không.
class OtpSent {
  final int expiresInSeconds;
  const OtpSent(this.expiresInSeconds);

  factory OtpSent.fromJson(Map<String, dynamic> j) =>
      OtpSent((j['expiresInSeconds'] as num?)?.toInt() ?? 300);
}
