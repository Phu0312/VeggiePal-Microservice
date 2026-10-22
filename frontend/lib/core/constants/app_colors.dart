import 'package:flutter/material.dart';

/// Bảng màu thương hiệu VeggiePal (lấy cảm hứng từ rau củ tươi).
/// Các màu chữ/nền phụ thuộc chế độ sáng/tối được lấy qua [AppThemeX] (theo ColorScheme).
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF2E7D32); // Xanh lá rau củ tươi
  static const Color accent = Color(0xFF8BC34A); // Xanh đọt chuối
  static const Color background = Color(0xFFF7F9F6); // Trắng kem dịu mắt
  static const Color surface = Colors.white;
  static const Color textDark = Color(0xFF1B2B1C);
  static const Color textMuted = Color(0xFF6B7A6C);
  static const Color star = Color(0xFFFFB300);

  // Dark mode
  static const Color primaryDark = Color(0xFF81C784);
  static const Color backgroundDark = Color(0xFF111611);
  static const Color surfaceDark = Color(0xFF1D251D);
  static const Color textDarkMode = Color(0xFFE6EDE6);
  static const Color textMutedDarkMode = Color(0xFFA9B8AA);
}

/// Truy cập màu theo theme hiện tại, tự đổi khi bật chế độ sáng/tối để chữ luôn đủ tương phản.
extension AppThemeX on BuildContext {
  ColorScheme get cs => Theme.of(this).colorScheme;
  Color get textMuted => cs.onSurfaceVariant;
}
