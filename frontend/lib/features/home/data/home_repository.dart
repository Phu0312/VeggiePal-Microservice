import '../../../core/constants/endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../blog/data/blog_models.dart';
import 'home_models.dart';

/// Gọi blog-service: danh mục, video, bài viết (đọc công khai, ghi cần JWT).
/// Mọi lỗi được ném lại cho UI hiển thị popup.
class HomeRepository {
  final ApiClient _api;
  HomeRepository(this._api);

  // GET /categories -> cây danh mục; làm phẳng cấp con để hiển thị chip ngang.
  Future<List<CategoryItem>> categories() async {
    final r = await _api.get(Endpoints.categories, query: {'type': 'RECIPE_TYPE'});
    final out = <CategoryItem>[];
    void walk(dynamic n) {
      for (final c in asList(n)) {
        final m = Map<String, dynamic>.from(c as Map);
        out.add(CategoryItem.fromJson(m));
        if (m['children'] != null) walk(m['children']);
      }
    }
    walk(r);
    return out;
  }

  // GET /videos?keyword=&categoryId= (chỉ trả video PUBLISHED).
  Future<List<VideoItem>> videos({String? keyword, int? categoryId}) async {
    final r = await _api.get(Endpoints.videos, query: {
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      if (categoryId != null) 'categoryId': categoryId,
      'size': 10,
    });
    return asList(r)
        .map((e) => VideoItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // GET /blogs?keyword=&categoryId=&page=&size= (bài đã đăng, mới nhất trước) -> một trang cho bảng tin.
  Future<PageData<BlogItem>> blogsPage(
      {String? keyword, int? categoryId, int page = 0, int size = 10}) async {
    final r = await _api.get(Endpoints.blogs, query: {
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      if (categoryId != null) 'categoryId': categoryId,
      'page': page,
      'size': size,
    });
    final m = Map<String, dynamic>.from(r as Map);
    return PageData(
      asList(r).map((e) => BlogItem.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      (m['page'] as num?)?.toInt() ?? page,
      (m['totalPages'] as num?)?.toInt() ?? 1,
      (m['totalElements'] as num?)?.toInt() ?? 0,
    );
  }

  Future<List<BlogItem>> blogs({String? keyword, int? categoryId}) async {
    final r = await _api.get(Endpoints.blogs, query: {
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      if (categoryId != null) 'categoryId': categoryId,
      'size': 10,
    });
    return asList(r)
        .map((e) => BlogItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // GET /blogs/me -> bài viết của tôi ở mọi trạng thái (cần JWT).
  Future<List<BlogItem>> myBlogs({String? status, int size = 100}) async {
    final r = await _api.get(Endpoints.myBlogs, query: {
      if (status != null) 'status': status,
      'size': size,
    });
    return asList(r)
        .map((e) => BlogItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // GET /blogs/{id} -> có thêm nội dung đầy đủ.
  Future<BlogItem> blogDetail(BlogItem summary) async {
    final r = await _api.get(Endpoints.blogById(summary.id));
    return BlogItem.fromJson(Map<String, dynamic>.from(r as Map));
  }

  // POST /blogs. publish=true: backend kiểm duyệt ngay (đăng luôn / chờ duyệt / từ chối);
  // publish=false: lưu bản nháp. Trả về bài viết kèm status và moderationReason.
  Future<BlogItem> createBlog(String title, String content, int categoryId,
      {bool publish = true}) async {
    final r = await _api.post(Endpoints.blogs, body: {
      'title': title,
      'content': content,
      'categoryId': categoryId,
      'publish': publish,
    });
    return BlogItem.fromJson(Map<String, dynamic>.from(r as Map));
  }

  // POST /videos (video lưu bằng URL, không upload file).
  Future<void> createVideo(String title, String url, String? thumb, int? categoryId) async {
    await _api.post(Endpoints.videos, body: {
      'title': title,
      'videoUrl': url,
      'thumbnailUrl': thumb,
      'categoryId': categoryId,
      'publish': true,
    });
  }
}
