import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import 'profile_models.dart';
import 'profile_repository.dart';

/// Danh sách yêu thích của người dùng đang đăng nhập (GET /users/me/favorites), dùng chung cho nút lưu ở
/// công thức, bài viết, video và màn "Yêu thích". Đặt ở Provider để mọi màn cùng thấy trạng thái mới.
class FavoritesController extends ChangeNotifier {
  FavoritesController(this._repo);

  final ProfileRepository _repo;

  int? _userId;
  List<FavoriteItem> _items = const [];
  bool loaded = false;
  bool loading = false;
  String? error;

  /// Mục yêu thích, mới lưu trước.
  List<FavoriteItem> get items => _items;

  List<FavoriteItem> ofType(FavoriteType type) => [for (final i in _items) if (i.type == type) i];

  bool isFavorite(FavoriteType type, int targetId) =>
      _items.any((i) => i.type == type && i.targetId == targetId);

  /// Gọi khi đăng nhập / đăng xuất (từ ProxyProvider). Quản trị viên không dùng yêu thích nên không tải.
  void bindUser(int? userId) {
    if (userId == _userId) return;
    _userId = userId;
    _items = const [];
    loaded = false;
    loading = false;
    error = null;
    Future.microtask(notifyListeners);
    if (userId != null) Future.microtask(refresh);
  }

  /// Tải lại toàn bộ danh sách; trả về thông báo lỗi nếu thất bại (null = thành công).
  Future<String?> refresh() async {
    final user = _userId;
    if (user == null) return null;
    loading = true;
    notifyListeners();
    try {
      final list = await _repo.favorites();
      if (user != _userId) return null;
      _items = list;
      loaded = true;
      error = null;
    } catch (e) {
      if (user != _userId) return null;
      error = errorMessage(e);
    } finally {
      if (user == _userId) {
        loading = false;
        notifyListeners();
      }
    }
    return error;
  }

  /// Lưu hoặc bỏ lưu một mục. Trả về thông báo lỗi nếu thất bại (null = thành công).
  Future<String?> toggle(FavoriteType type, int targetId, {required String title, String? imageUrl}) async {
    try {
      if (isFavorite(type, targetId)) {
        await _repo.removeFavorite(type, targetId);
        _items = [for (final i in _items) if (!(i.type == type && i.targetId == targetId)) i];
      } else {
        final saved = await _repo.saveFavorite(type, targetId, title, imageUrl);
        _items = [
          saved ?? FavoriteItem(id: 0, type: type, targetId: targetId, title: title, imageUrl: imageUrl),
          ..._items,
        ];
      }
      notifyListeners();
      return null;
    } catch (e) {
      return errorMessage(e);
    }
  }

  /// Bỏ lưu một mục (nút xoá ở màn Yêu thích).
  Future<String?> remove(FavoriteItem item) async {
    if (!isFavorite(item.type, item.targetId)) return null;
    return toggle(item.type, item.targetId, title: item.title, imageUrl: item.imageUrl);
  }
}
