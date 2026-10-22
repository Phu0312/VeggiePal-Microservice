import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Chế độ sáng/tối của toàn app, được lưu lại để lần mở sau giữ nguyên lựa chọn.
class ThemeController extends ChangeNotifier {
  ThemeController() {
    _restore();
  }

  static const _key = 'theme_mode';

  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  Future<void> _restore() async {
    try {
      final p = await SharedPreferences.getInstance();
      final saved = p.getString(_key);
      if (saved == 'dark') {
        _mode = ThemeMode.dark;
        notifyListeners();
      }
    } catch (_) {
      // Không đọc được bộ nhớ cục bộ thì dùng chế độ sáng mặc định.
    }
  }

  Future<void> toggle() async {
    _mode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    try {
      (await SharedPreferences.getInstance()).setString(_key, isDark ? 'dark' : 'light');
    } catch (_) {
      // Không lưu được thì chỉ mất lựa chọn ở lần mở sau.
    }
  }
}
