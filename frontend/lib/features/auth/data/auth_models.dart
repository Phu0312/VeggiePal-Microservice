/// Ba vai trò dùng cho phân quyền giao diện.
enum UserRole { guest, user, admin }

class AuthUser {
  final int id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? avatarUrl;

  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.avatarUrl,
  });

  AuthUser copyWith({String? fullName, String? avatarUrl}) => AuthUser(
        id: id,
        email: email,
        fullName: fullName ?? this.fullName,
        role: role,
        avatarUrl: avatarUrl ?? this.avatarUrl,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'role': role.name,
        'avatarUrl': avatarUrl,
      };

  factory AuthUser.fromStored(Map<String, dynamic> j) => AuthUser(
        id: (j['id'] as num).toInt(),
        email: '${j['email'] ?? ''}',
        fullName: '${j['fullName'] ?? ''}',
        role: UserRole.values.firstWhere((r) => r.name == j['role'], orElse: () => UserRole.user),
        avatarUrl: j['avatarUrl'] as String?,
      );

  /// Chữ cái đầu hiển thị khi chưa có ảnh đại diện.
  String get initial {
    final n = fullName.trim().isNotEmpty ? fullName.trim() : email.trim();
    return n.isEmpty ? '?' : n[0].toUpperCase();
  }

  /// Map từ `LoginResponse` của identity-service: accessToken, userId, email, fullName, role.
  factory AuthUser.fromLogin(Map<String, dynamic> j) => AuthUser(
        id: (j['userId'] as num?)?.toInt() ?? 0,
        email: '${j['email'] ?? ''}',
        fullName: '${j['fullName'] ?? ''}',
        role: '${j['role']}'.toUpperCase().contains('ADMIN')
            ? UserRole.admin
            : UserRole.user,
      );
}

class AuthSession {
  final String token;
  final AuthUser user;
  const AuthSession(this.token, this.user);
}
