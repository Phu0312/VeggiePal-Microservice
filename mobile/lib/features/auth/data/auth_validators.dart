// Kiểm tra dữ liệu form đăng nhập / đăng ký, khớp luật của identity-service (RegisterRequest, LoginRequest).
// Mỗi hàm trả thông báo lỗi tiếng Việt hoặc null nếu hợp lệ, dùng trực tiếp làm `validator` của TextFormField.

final _email = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]{2,}$");

String? validateEmail(String? v) {
  final t = (v ?? '').trim();
  if (t.isEmpty) return 'Vui lòng nhập email';
  return _email.hasMatch(t) ? null : 'Email không hợp lệ';
}

/// Backend yêu cầu mật khẩu tối thiểu 6 ký tự (RegisterRequest.password).
String? validatePassword(String? v) {
  final t = v ?? '';
  if (t.isEmpty) return 'Vui lòng nhập mật khẩu';
  return t.length < 6 ? 'Mật khẩu tối thiểu 6 ký tự' : null;
}

String? validateFullName(String? v) => (v ?? '').trim().isEmpty ? 'Vui lòng nhập họ và tên' : null;

/// Số điện thoại không bắt buộc; nếu nhập thì chỉ gồm chữ số, khoảng trắng, dấu chấm, gạch ngang và dấu + ở đầu.
String? validatePhone(String? v) {
  final t = (v ?? '').trim();
  if (t.isEmpty) return null;
  if (!RegExp(r'^\+?[\d\s.\-]{8,15}$').hasMatch(t)) return 'Số điện thoại không hợp lệ';
  return null;
}

String? validateConfirmPassword(String? v, String password) {
  if ((v ?? '').isEmpty) return 'Vui lòng nhập lại mật khẩu';
  return v == password ? null : 'Mật khẩu nhập lại không khớp';
}
