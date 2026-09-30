/// Ba vai trò dùng cho phân quyền giao diện.
enum UserRole { guest, user, admin }

class AuthUser {
  final int id;
  final String email;
  final String fullName;
  final UserRole role;

  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
  });

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
  final String? token; // null khi đang dùng phiên demo (mock)
  final AuthUser user;
  const AuthSession(this.token, this.user);
}
