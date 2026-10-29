import '../../../core/constants/endpoints.dart';
import '../../../core/network/api_client.dart';
import 'meal_models.dart';

/// Nguyên liệu trong tủ của tôi (cần JWT). Công thức nằm ở RecipeRepository.
/// Mọi lỗi được ném lại cho UI hiển thị popup.
class MealRepository {
  final ApiClient _api;
  MealRepository(this._api);

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
