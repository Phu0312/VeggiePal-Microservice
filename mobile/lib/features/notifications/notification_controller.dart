import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_client.dart';
import '../home/data/home_repository.dart';

class AppNotification {
  final String title;
  final String body;
  final DateTime createdAt;
  bool read;

  AppNotification(this.title, this.body, this.createdAt, {this.read = false});

  Map<String, dynamic> toJson() =>
      {'title': title, 'body': body, 'at': createdAt.toIso8601String(), 'read': read};

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        '${j['title']}',
        '${j['body']}',
        DateTime.tryParse('${j['at']}') ?? DateTime.now(),
        read: j['read'] == true,
      );
}

/// Thông báo cho người dùng. Backend chưa có notification service nên thông báo được suy ra từ
/// dữ liệu thật: so sánh trạng thái các bài viết của tôi (GET /blogs/me) với lần kiểm tra trước
/// (lưu cục bộ). Trạng thái đổi (chờ duyệt -> đã duyệt/bị từ chối/bị gỡ) thì sinh thông báo mới.
class NotificationController extends ChangeNotifier {
  NotificationController(this._repo);

  final HomeRepository _repo;
  static const _pollInterval = Duration(seconds: 60);
  static const _maxItems = 50;

  int? _userId;
  Timer? _timer;
  bool _syncing = false;
  List<AppNotification> items = [];

  int get unread => items.where((n) => !n.read).length;

  String get _itemsKey => 'notif_items_$_userId';
  String get _snapshotKey => 'notif_snapshot_$_userId';

  /// Gọi khi đăng nhập/đăng xuất (từ ProxyProvider).
  void bindUser(int? userId) {
    if (userId == _userId) return;
    _userId = userId;
    _timer?.cancel();
    items = [];
    // Được gọi từ ProxyProvider.update (đang trong build) nên hoãn thông báo sang microtask.
    Future.microtask(notifyListeners);
    if (userId == null) return;
    _load().then((_) => refresh());
    _timer = Timer.periodic(_pollInterval, (_) => refresh());
  }

  Future<void> _load() async {
    final uid = _userId;
    try {
      final p = await SharedPreferences.getInstance();
      if (uid != _userId) return;
      final raw = p.getString(_itemsKey);
      if (raw != null) {
        items = (jsonDecode(raw) as List)
            .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _save(SharedPreferences p) =>
      p.setString(_itemsKey, jsonEncode(items.map((e) => e.toJson()).toList()));

  /// Đồng bộ với backend. Trả về thông báo lỗi nếu không lấy được dữ liệu (null = thành công).
  Future<String?> refresh() async {
    final uid = _userId;
    if (uid == null) return null;
    if (_syncing) return null;
    _syncing = true;
    try {
      final blogs = await _repo.myBlogs();
      if (uid != _userId) return null;
      final p = await SharedPreferences.getInstance();
      final prevRaw = p.getString(_snapshotKey);
      final prev = prevRaw == null
          ? null
          : Map<String, dynamic>.from(jsonDecode(prevRaw) as Map);

      final fresh = <AppNotification>[];
      if (prev != null) {
        for (final b in blogs) {
          final old = prev['${b.id}'] as String?;
          final msg = _message(b.title, old, b.status);
          if (msg != null) fresh.add(AppNotification('Bài viết của bạn', msg, DateTime.now()));
        }
      }
      await p.setString(_snapshotKey, jsonEncode({for (final b in blogs) '${b.id}': b.status}));

      if (fresh.isNotEmpty) {
        items = [...fresh, ...items].take(_maxItems).toList();
        await _save(p);
        notifyListeners();
      }
      return null;
    } catch (e) {
      return errorMessage(e);
    } finally {
      _syncing = false;
    }
  }

  Future<void> markAllRead() async {
    if (unread == 0) return;
    for (final n in items) {
      n.read = true;
    }
    notifyListeners();
    try {
      await _save(await SharedPreferences.getInstance());
    } catch (_) {}
  }

  /// Nội dung thông báo khi trạng thái bài viết đổi từ [old] sang [now]; null nếu không cần báo.
  static String? _message(String title, String? old, String? now) {
    if (old == now || now == null) return null;
    final isNew = old == null;
    switch (now) {
      case 'PUBLISHED':
        return isNew
            ? 'Bài viết "$title" đã được đăng.'
            : 'Bài viết "$title" đã được duyệt và đăng.';
      case 'PENDING':
        return 'Bài viết "$title" đang chờ kiểm duyệt.';
      case 'REJECTED':
        return 'Bài viết "$title" không được duyệt.';
      case 'BANNED':
        return 'Bài viết "$title" đã bị gỡ do vi phạm quy định.';
    }
    return null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
