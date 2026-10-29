import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_client.dart';
import '../home/data/home_repository.dart';
import '../video/data/video_repository.dart';

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
/// dữ liệu thật: so sánh trạng thái các bài viết (GET /blogs/me) và video (GET /videos/me) của tôi với lần kiểm tra
/// trước (lưu cục bộ). Trạng thái đổi (chờ duyệt -> đã duyệt/bị từ chối/bị gỡ) thì sinh thông báo mới.
class NotificationController extends ChangeNotifier {
  NotificationController(this._repo, this._videos);

  final HomeRepository _repo;
  final VideoRepository _videos;
  static const _pollInterval = Duration(seconds: 60);
  static const _maxItems = 50;
  static const _videoPrefix = 'v:'; // khoá video trong ảnh chụp trạng thái, tránh trùng id bài viết
  static const _videoMarker = '_v'; // có khoá này nghĩa là ảnh chụp đã gồm phần video

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
      final titles = <String, String>{};
      if (uid != _userId) return null;
      final p = await SharedPreferences.getInstance();
      final prevRaw = p.getString(_snapshotKey);
      final prev = prevRaw == null
          ? null
          : Map<String, dynamic>.from(jsonDecode(prevRaw) as Map);

      // Video: lỗi tải không được chặn thông báo bài viết; khi đó giữ nguyên phần video của lần trước.
      List<MapEntry<String, String>>? videoStatuses;
      try {
        final page = await _videos.mine(size: 100);
        videoStatuses = [for (final v in page.items) MapEntry('$_videoPrefix${v.id}', v.status)];
        titles.addAll({for (final v in page.items) '$_videoPrefix${v.id}': v.title});
      } catch (_) {}
      if (uid != _userId) return null;

      final fresh = <AppNotification>[];
      if (prev != null) {
        for (final b in blogs) {
          final msg = statusMessage('Bài viết', b.title, prev['${b.id}'] as String?, b.status);
          if (msg != null) fresh.add(AppNotification('Bài viết của bạn', msg, DateTime.now()));
        }
        // Lần đầu có phần video trong ảnh chụp chỉ để lấy mốc, không báo mọi video đang có.
        if (videoStatuses != null && prev.containsKey(_videoMarker)) {
          for (final e in videoStatuses) {
            final msg = statusMessage('Video', titles[e.key] ?? '', prev[e.key] as String?, e.value);
            if (msg != null) fresh.add(AppNotification('Video của bạn', msg, DateTime.now()));
          }
        }
      }
      final snapshot = <String, String>{for (final b in blogs) if (b.status != null) '${b.id}': b.status!};
      if (videoStatuses != null) {
        snapshot[_videoMarker] = '1';
        snapshot.addEntries(videoStatuses);
      } else if (prev != null) {
        // Giữ phần video cũ để lần sau còn so sánh được.
        for (final e in prev.entries) {
          if (e.key.startsWith(_videoPrefix) || e.key == _videoMarker) snapshot[e.key] = '${e.value}';
        }
      }
      await p.setString(_snapshotKey, jsonEncode(snapshot));

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

  /// Nội dung thông báo khi trạng thái của [noun] ("Bài viết" / "Video") đổi từ [old] sang [now]; null nếu không cần báo.
  @visibleForTesting
  static String? statusMessage(String noun, String title, String? old, String? now) {
    if (old == now || now == null) return null;
    final isNew = old == null;
    switch (now) {
      case 'PUBLISHED':
        return isNew ? '$noun "$title" đã được đăng.' : '$noun "$title" đã được duyệt và đăng.';
      case 'PENDING':
        return '$noun "$title" đang chờ kiểm duyệt.';
      case 'REJECTED':
        return '$noun "$title" không được duyệt.';
      case 'BANNED':
        return '$noun "$title" đã bị gỡ do vi phạm quy định.';
    }
    return null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
