import '../../../core/constants/endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../recipe/data/recipe_models.dart';
import 'home_models.dart';

/// Một nội dung do AI gợi ý (ai-service: Recommendation): bài viết hoặc công thức, kèm lý do.
class Recommendation {
  final String type; // BLOG | RECIPE
  final int id;
  final String reason;
  final Map<String, dynamic> content; // bản tóm tắt của nội dung gốc, cùng dạng với danh sách ở blog / recipe-service

  const Recommendation(this.type, this.id, this.reason, this.content);

  factory Recommendation.fromJson(Map<String, dynamic> j) => Recommendation(
        '${j['type']}',
        (j['id'] as num).toInt(),
        '${j['reason'] ?? ''}'.trim(),
        j['content'] is Map ? Map<String, dynamic>.from(j['content'] as Map) : const {},
      );

  bool get isRecipe => type == 'RECIPE';
  bool get isBlog => type == 'BLOG';

  String get title => '${content['title'] ?? ''}'.trim();

  String? get imageUrl => (isRecipe ? content['imageUrl'] : content['thumbnailUrl']) as String?;

  BlogItem toBlog() => BlogItem.fromJson({...content, 'id': id});
  Recipe toRecipe() => Recipe.fromJson({...content, 'id': id});

  String get typeLabel => isRecipe ? 'Công thức' : 'Bài viết';
}

/// ai-service: gợi ý nội dung cá nhân hoá (cần JWT). Mọi lỗi được ném lại cho UI.
class RecommendationRepository {
  final ApiClient _api;
  RecommendationRepository(this._api);

  // GET /ai/recommendations?interest=&limit= (limit 1-10): AI chọn từ bài viết và công thức mới nhất.
  // Mỗi lần gọi tốn token AI (không trừ lượt theo gói); lỗi 6003 = hết hạn mức token trong ngày.
  Future<List<Recommendation>> recommend({String? interest, int limit = 6}) async {
    final r = await _api.get(Endpoints.aiRecommendations, query: {
      if (interest != null && interest.trim().isNotEmpty) 'interest': interest.trim(),
      'limit': limit,
    });
    return [
      for (final e in asList(r))
        if (e is Map) Recommendation.fromJson(Map<String, dynamic>.from(e)),
    ].where((x) => x.title.isNotEmpty).toList();
  }
}
