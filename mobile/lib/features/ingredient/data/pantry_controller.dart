import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ingredient_models.dart';

/// Tủ nguyên liệu của người dùng, lưu trên máy theo từng tài khoản (backend không có API tủ nguyên liệu).
/// Dùng để điền nhanh "nguyên liệu bạn có" khi tạo thực đơn tuần.
class PantryController extends ChangeNotifier {
  /// Backend nhận tối đa 30 nguyên liệu mỗi lần tạo thực đơn.
  static const maxForPlan = 30;

  int? _userId;
  List<PantryItem> items = [];

  String get _storageKey => 'pantry_items_$_userId';

  /// Gọi khi đăng nhập/đăng xuất (từ ProxyProvider).
  void bindUser(int? userId) {
    if (userId == _userId) return;
    _userId = userId;
    items = [];
    // Được gọi từ ProxyProvider.update (đang trong build) nên hoãn thông báo sang microtask.
    Future.microtask(notifyListeners);
    if (userId != null) _load(userId);
  }

  Future<void> _load(int userId) async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_storageKey);
      if (userId != _userId || raw == null) return;
      items = [
        for (final e in jsonDecode(raw) as List)
          PantryItem.fromJson(Map<String, dynamic>.from(e as Map)),
      ];
      notifyListeners();
    } catch (_) {
      // Dữ liệu hỏng thì coi như tủ trống.
    }
  }

  Future<void> _save() async {
    try {
      await (await SharedPreferences.getInstance())
          .setString(_storageKey, jsonEncode(items.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  bool contains(String name) => items.any((e) => e.key == PantryItem.normalizeName(name));

  /// Thêm nguyên liệu; trả false nếu đã có nguyên liệu cùng tên.
  bool add(PantryItem item) {
    if (_userId == null || contains(item.name)) return false;
    items = [...items, item];
    notifyListeners();
    _save();
    return true;
  }

  /// Thay [old] bằng [updated]; trả false nếu đổi sang tên đã có ở nguyên liệu khác.
  bool update(PantryItem old, PantryItem updated) {
    final clash = updated.key != old.key && contains(updated.name);
    if (clash) return false;
    items = [for (final e in items) e.key == old.key ? updated : e];
    notifyListeners();
    _save();
    return true;
  }

  void remove(PantryItem item) {
    items = items.where((e) => e.key != item.key).toList();
    notifyListeners();
    _save();
  }

  /// Tên các nguyên liệu còn dùng được để gửi cho AI: bỏ nguyên liệu đã hết hạn, dùng đồ sắp hết hạn trước
  /// (nguyên liệu không có hạn xếp sau), tối đa [max].
  List<String> namesForPlan({int max = maxForPlan, DateTime? now}) {
    final usable = items.where((e) => !e.isExpired(now)).toList();
    usable.sort((a, b) => (a.daysLeft(now) ?? 1 << 30).compareTo(b.daysLeft(now) ?? 1 << 30));
    return [for (final e in usable.take(max)) e.name];
  }
}
