import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import 'recommendation_repository.dart';

/// Gợi ý nội dung của AI cho Trang chủ. Đặt ở Provider để giữ kết quả khi chuyển tab và tránh gọi AI lặp lại
/// (mỗi lần gọi tốn token): kết quả được dùng lại [freshFor]; muốn lấy mới thì gọi [refresh].
class RecommendationController extends ChangeNotifier {
  RecommendationController(this._repo, {DateTime Function()? clock}) : _now = clock ?? DateTime.now;

  static const freshFor = Duration(minutes: 5);

  final RecommendationRepository _repo;
  final DateTime Function() _now;

  int? _userId;
  int _epoch = 0;
  DateTime? _loadedAt;
  List<Recommendation> items = [];
  bool loading = false;
  String? error;

  bool get hasLoaded => _loadedAt != null;

  /// Gọi khi đăng nhập / đăng xuất (từ ProxyProvider): xoá gợi ý của tài khoản trước.
  void bindUser(int? userId) {
    if (userId == _userId) return;
    _userId = userId;
    _epoch++;
    items = [];
    error = null;
    loading = false;
    _loadedAt = null;
    // Được gọi từ ProxyProvider.update (đang trong build) nên hoãn thông báo sang microtask.
    Future.microtask(notifyListeners);
  }

  /// Tải gợi ý nếu chưa có hoặc đã cũ; không làm gì khi đang tải hoặc còn mới.
  Future<void> ensureLoaded() async {
    final at = _loadedAt;
    if (_userId == null || loading) return;
    if (at != null && _now().difference(at) < freshFor) return; // kể cả khi lần trước lỗi
    await refresh();
  }

  /// Lấy gợi ý mới từ AI (bỏ qua bộ nhớ đệm).
  Future<void> refresh() async {
    if (_userId == null || loading) return;
    final epoch = _epoch;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final r = await _repo.recommend();
      if (epoch != _epoch) return;
      items = r;
      _loadedAt = _now();
    } catch (e) {
      if (epoch != _epoch) return;
      error = errorMessage(e);
      // Lỗi cũng đánh dấu đã thử, để không gọi lại liên tục mỗi lần dựng màn hình; người dùng bấm "Thử lại".
      _loadedAt = _now();
    } finally {
      if (epoch == _epoch) {
        loading = false;
        notifyListeners();
      }
    }
  }
}
