import '../../../core/constants/endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../blog/data/blog_models.dart';
import 'ingredient_models.dart';

/// recipe-service: danh mục nguyên liệu chung (đọc công khai, không cần đăng nhập).
/// Mọi lỗi được ném lại cho UI hiển thị popup.
class IngredientRepository {
  final ApiClient _api;
  IngredientRepository(this._api);

  // GET /ingredients?keyword=&vegan=&allergen=&page=&size= : chỉ trả nguyên liệu đang hoạt động.
  Future<PageData<Ingredient>> page({
    String? keyword,
    IngredientFilter filter = IngredientFilter.all,
    int page = 0,
    int size = 20,
  }) async {
    final r = await _api.get(Endpoints.ingredients, query: {
      if (keyword != null && keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
      if (filter == IngredientFilter.vegan) 'vegan': true,
      if (filter == IngredientFilter.allergen) 'allergen': true,
      'page': page,
      'size': size,
    });
    final m = r is Map ? r : const {};
    return PageData(
      asList(r).map((e) => Ingredient.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      (m['page'] as num?)?.toInt() ?? page,
      (m['totalPages'] as num?)?.toInt() ?? 1,
      (m['totalElements'] as num?)?.toInt() ?? 0,
    );
  }
}
