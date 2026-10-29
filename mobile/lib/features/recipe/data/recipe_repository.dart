import '../../../core/constants/endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../blog/data/blog_models.dart';
import 'recipe_models.dart';

/// Nội dung gửi lên khi tạo / sửa công thức (recipe-service: RecipeRequest).
class RecipePayload {
  final String title;
  final String description;
  final String imageUrl;
  final int servings;
  final int? prepTime;
  final int? cookTime;
  final List<RecipeIngredientDraft> ingredients;
  final List<String> steps;

  const RecipePayload({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.servings,
    required this.prepTime,
    required this.cookTime,
    required this.ingredients,
    required this.steps,
  });

  Map<String, dynamic> toJson() => {
        'title': title.trim(),
        'description': description.trim(),
        'imageUrl': imageUrl.trim(),
        'servings': servings,
        'prepTime': prepTime,
        'cookTime': cookTime,
        'ingredients': [
          for (final i in ingredients)
            {
              'ingredientId': i.ingredientId,
              'quantity': parseQuantity(i.quantity),
              'unit': i.unit,
              'note': i.note.trim().isEmpty ? null : i.note.trim(),
            },
        ],
        'steps': [
          for (var i = 0; i < steps.length; i++)
            {'stepNumber': i + 1, 'instruction': steps[i].trim()},
        ],
      };
}

/// recipe-service: công thức và danh mục nguyên liệu. Đọc là công khai; tạo / sửa / đăng / xoá cần JWT
/// và chỉ chủ công thức hoặc ADMIN được sửa. Mọi lỗi được ném lại cho UI hiển thị popup.
class RecipeRepository {
  final ApiClient _api;
  RecipeRepository(this._api);

  /// Công thức đã tải cho các màn chỉ cần xem nhanh (chi tiết bữa trong thực đơn); xoá khi có thay đổi.
  final _cache = <int, Future<Recipe>>{};

  void _requireLogin() {
    if (_api.token == null) throw ApiException('Vui lòng đăng nhập để sử dụng chức năng này.');
  }

  Recipe _recipe(dynamic r) => Recipe.fromJson(Map<String, dynamic>.from(r as Map));

  PageData<Recipe> _page(dynamic r, int page) {
    final m = r is Map ? r : const {};
    return PageData(
      asList(r).map(_recipe).toList(),
      (m['page'] as num?)?.toInt() ?? page,
      (m['totalPages'] as num?)?.toInt() ?? 1,
      (m['totalElements'] as num?)?.toInt() ?? 0,
    );
  }

  // GET /recipes?keyword=&page=&size= : công thức đã đăng, mới nhất trước.
  Future<PageData<Recipe>> published({String? keyword, int page = 0, int size = 10}) async {
    final r = await _api.get(Endpoints.recipes, query: {
      if (keyword != null && keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
      'page': page,
      'size': size,
    });
    return _page(r, page);
  }

  // GET /recipes/me : của tôi ở mọi trạng thái trừ đã xoá.
  Future<PageData<Recipe>> mine({int page = 0, int size = 10}) async {
    _requireLogin();
    final r = await _api.get(Endpoints.myRecipes, query: {'page': page, 'size': size});
    return _page(r, page);
  }

  // GET /recipes/{id}: bản nháp / đang ẩn chỉ chủ công thức và ADMIN đọc được (kèm token), người khác nhận 4100.
  Future<Recipe> recipe(int id) async => _recipe(await _api.get(Endpoints.recipeById(id)));

  /// Như [recipe] nhưng nhớ kết quả cho các lần mở lại.
  Future<Recipe> cachedRecipe(int id) {
    return _cache.putIfAbsent(id, () async {
      try {
        return await recipe(id);
      } catch (_) {
        _cache.remove(id); // lần sau cho phép thử lại
        rethrow;
      }
    });
  }

  // POST /recipes : luôn tạo ở trạng thái DRAFT.
  Future<Recipe> create(RecipePayload p) async {
    _requireLogin();
    return _recipe(await _api.post(Endpoints.recipes, body: p.toJson()));
  }

  // PUT /recipes/{id} : không đổi trạng thái; công thức đã xoá / đang ẩn không sửa được (4108).
  Future<Recipe> update(int id, RecipePayload p) async {
    _requireLogin();
    final r = _recipe(await _api.put(Endpoints.recipeById(id), body: p.toJson()));
    _cache.remove(id);
    return r;
  }

  // POST /recipes/{id}/publish : DRAFT -> PUBLISHED, không kiểm duyệt (4103 nếu đã đăng).
  Future<Recipe> publish(int id) async {
    _requireLogin();
    final r = _recipe(await _api.post(Endpoints.recipePublish(id)));
    _cache.remove(id);
    return r;
  }

  // DELETE /recipes/{id} : xoá mềm (chuyển ARCHIVED), thực đơn cũ vẫn đọc được món này.
  Future<void> delete(int id) async {
    _requireLogin();
    await _api.delete(Endpoints.recipeById(id));
    _cache.remove(id);
  }
}
