import '../../../core/constants/endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../blog/data/blog_models.dart';
import 'home_models.dart';

/// Gọi blog-service: danh mục, bài viết (đọc công khai, ghi cần JWT).
/// Mọi lỗi được ném lại cho UI hiển thị popup.
class HomeRepository {
  final ApiClient _api;
  HomeRepository(this._api);

  // GET /categories -> cây danh mục (cả FOOD_TYPE lẫn RECIPE_TYPE, bài viết gắn được với loại nào cũng
  // được); làm phẳng cấp con để hiển thị chip ngang. Lọc bài theo categoryId là khớp đúng danh mục đó.
  Future<List<CategoryItem>> categories() async {
    final r = await _api.get(Endpoints.categories);
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

  // GET /blogs?keyword=&categoryId=&sort=&page=&size= (bài đã đăng) -> một trang cho bảng tin.
  // sort: '' = mới đăng trước, 'popular' = điểm bầu chọn cao, 'mostViewed' = nhiều lượt xem.
  Future<PageData<BlogItem>> blogsPage(
      {String? keyword, int? categoryId, String sort = '', int page = 0, int size = 10}) async {
    final r = await _api.get(Endpoints.blogs, query: {
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      if (categoryId != null) 'categoryId': categoryId,
      if (sort.isNotEmpty) 'sort': sort,
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

  // GET /blogs/me?size=1 -> chỉ lấy tổng số bài viết của tôi (totalElements của PageResponse).
  Future<int> myBlogsTotal() async {
    final r = await _api.get(Endpoints.myBlogs, query: {'size': 1});
    return r is Map ? (r['totalElements'] as num?)?.toInt() ?? asList(r).length : asList(r).length;
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
}
