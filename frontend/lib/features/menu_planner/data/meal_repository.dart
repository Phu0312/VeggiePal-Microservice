import '../../../core/constants/endpoints.dart';
import '../../../core/network/api_client.dart';
import 'meal_models.dart';

/// meal-service: công thức (công khai) và nguyên liệu trong tủ của tôi (cần JWT).
/// Mọi lỗi được ném lại cho UI hiển thị popup.
class MealRepository {
  final ApiClient _api;
  MealRepository(this._api);

  // GET /nutrition/recipes?keyword=&excludeAllergen=
  // Lưu ý: BE ưu tiên excludeAllergen, nếu có thì bỏ qua keyword.
  Future<List<RecipeItem>> recipes({String? keyword, String? excludeAllergen}) async {
    final r = await _api.get(Endpoints.recipes, query: {
      if (excludeAllergen != null && excludeAllergen.isNotEmpty) 'excludeAllergen': excludeAllergen,
      if ((excludeAllergen ?? '').isEmpty && keyword != null && keyword.isNotEmpty) 'keyword': keyword,
    });
    return asList(r)
        .map((e) => RecipeItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // GET /nutrition/recipes/{id}
  Future<RecipeItem> recipe(int id) async {
    final r = await _api.get(Endpoints.recipeById(id));
    return RecipeItem.fromJson(Map<String, dynamic>.from(r as Map));
  }

  void _requireLogin() {
    if (_api.token == null) throw ApiException('Vui lòng đăng nhập để sử dụng chức năng này.');
  }

  // GET /nutrition/me/ingredients
  Future<List<PantryItem>> pantry() async {
    _requireLogin();
    final r = await _api.get(Endpoints.myIngredients);
    return asList(r)
        .map((e) => PantryItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // POST /nutrition/me/ingredients {name, quantity, unit, expiryDate(yyyy-MM-dd)}
  Future<PantryItem> addPantryItem(
      {required String name, String? quantity, String? unit, String? expiryDate}) async {
    _requireLogin();
    final r = await _api.post(Endpoints.myIngredients, body: {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'expiryDate': expiryDate,
    });
    return PantryItem.fromJson(Map<String, dynamic>.from(r as Map));
  }

  // PATCH /nutrition/me/ingredients/{id}; trường null được BE giữ nguyên.
  Future<PantryItem> updatePantryItem(int id,
      {String? name, String? quantity, String? unit, String? expiryDate}) async {
    _requireLogin();
    final r = await _api.patch(Endpoints.myIngredientById(id), body: {
      if (name != null) 'name': name,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (expiryDate != null) 'expiryDate': expiryDate,
    });
    return PantryItem.fromJson(Map<String, dynamic>.from(r as Map));
  }

  // DELETE /nutrition/me/ingredients/{id}
  Future<void> deletePantryItem(int id) async {
    _requireLogin();
    await _api.delete(Endpoints.myIngredientById(id));
  }
}
