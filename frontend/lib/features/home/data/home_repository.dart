import '../../../core/constants/endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/mock_fallback.dart';
import '../../../core/widgets/common_widgets.dart' show mockImage;
import 'home_models.dart';

/// Gọi blog-service: danh mục, video, bài viết (đọc công khai, ghi cần JWT).
class HomeRepository {
  final ApiClient _api;
  HomeRepository(this._api);

  // GET /categories -> cây danh mục; làm phẳng cấp con để hiển thị chip ngang.
  Future<List<CategoryItem>> categories() => withFallback(() async {
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
      }, () => _mockCategories);

  // GET /videos?keyword=&categoryId= (chỉ trả video PUBLISHED).
  Future<List<VideoItem>> videos({String? keyword, int? categoryId}) => withFallback(() async {
        final r = await _api.get(Endpoints.videos, query: {
          if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
          if (categoryId != null) 'categoryId': categoryId,
          'size': 10,
        });
        return asList(r)
            .map((e) => VideoItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }, () {
        final k = (keyword ?? '').toLowerCase();
        return _mockVideos.where((v) => k.isEmpty || v.title.toLowerCase().contains(k)).toList();
      });

  // GET /blogs?keyword=&categoryId=
  Future<List<BlogItem>> blogs({String? keyword, int? categoryId}) => withFallback(() async {
        final r = await _api.get(Endpoints.blogs, query: {
          if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
          if (categoryId != null) 'categoryId': categoryId,
          'size': 10,
        });
        return asList(r)
            .map((e) => BlogItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }, () {
        final k = (keyword ?? '').toLowerCase();
        return _mockBlogs.where((b) => k.isEmpty || b.title.toLowerCase().contains(k)).toList();
      });

  // GET /blogs/{id} -> có thêm nội dung đầy đủ.
  Future<BlogItem> blogDetail(BlogItem summary) => withFallback(() async {
        final r = await _api.get(Endpoints.blogById(summary.id));
        return BlogItem.fromJson(Map<String, dynamic>.from(r as Map));
      }, () => BlogItem(
            id: summary.id,
            title: summary.title,
            thumbnailUrl: summary.thumbnailUrl,
            categoryName: summary.categoryName,
            viewCount: summary.viewCount,
            voteScore: summary.voteScore,
            publishedAt: summary.publishedAt,
            content: 'Đây là nội dung mẫu (chế độ offline).\n\nĂn chay giúp cơ thể nhẹ nhàng, '
                'giàu chất xơ và vitamin. Hãy bắt đầu với các món đơn giản từ đậu hũ, nấm và rau củ '
                'theo mùa, kết hợp đủ đạm thực vật từ đậu, hạt và ngũ cốc nguyên hạt.',
          ));

  // POST /blogs với publish=true (backend tự kiểm duyệt rồi xuất bản/chờ duyệt).
  Future<void> createBlog(String title, String content, int? categoryId) =>
      withFallback(() async {
        await _api.post(Endpoints.blogs, body: {
          'title': title,
          'content': content,
          'categoryId': categoryId,
          'publish': true,
        });
      }, () {});

  // POST /videos (video lưu bằng URL, không upload file).
  Future<void> createVideo(String title, String url, String? thumb, int? categoryId) =>
      withFallback(() async {
        await _api.post(Endpoints.videos, body: {
          'title': title,
          'videoUrl': url,
          'thumbnailUrl': thumb,
          'categoryId': categoryId,
          'publish': true,
        });
      }, () {});

  // ---------------- MOCK DATA ----------------
  static const _mockCategories = [
    CategoryItem(1, 'Món chính'),
    CategoryItem(2, 'Súp & Canh'),
    CategoryItem(3, 'Salad'),
    CategoryItem(4, 'Đồ uống'),
    CategoryItem(5, 'Tráng miệng'),
    CategoryItem(6, 'Món nướng'),
  ];

  static final _mockVideos = [
    VideoItem(id: 1, title: 'Bún riêu chay thanh đạm', thumbnailUrl: mockImage(0), durationSeconds: 512, viewCount: 12400, voteScore: 320, categoryName: 'Món chính'),
    VideoItem(id: 2, title: 'Salad quinoa bơ và đậu gà', thumbnailUrl: mockImage(1), durationSeconds: 305, viewCount: 8300, voteScore: 210, categoryName: 'Salad'),
    VideoItem(id: 3, title: 'Đậu hũ sốt cà chua 10 phút', thumbnailUrl: mockImage(2), durationSeconds: 421, viewCount: 15800, voteScore: 402, categoryName: 'Món chính'),
    VideoItem(id: 4, title: 'Sinh tố xanh detox', thumbnailUrl: mockImage(3), durationSeconds: 188, viewCount: 6100, voteScore: 145, categoryName: 'Đồ uống'),
    VideoItem(id: 5, title: 'Chè hạt sen long nhãn chay', thumbnailUrl: mockImage(4), durationSeconds: 640, viewCount: 4900, voteScore: 98, categoryName: 'Tráng miệng'),
  ];

  static final _mockBlogs = [
    BlogItem(id: 1, title: '7 nguồn đạm thực vật thay thế thịt', thumbnailUrl: mockImage(5), categoryName: 'Dinh dưỡng', viewCount: 2300, voteScore: 54, publishedAt: DateTime(2026, 9, 12)),
    BlogItem(id: 2, title: 'Bắt đầu ăn chay: lộ trình 30 ngày', thumbnailUrl: mockImage(6), categoryName: 'Kinh nghiệm', viewCount: 4100, voteScore: 120, publishedAt: DateTime(2026, 9, 5)),
    BlogItem(id: 3, title: 'Thay thế trứng trong làm bánh chay', thumbnailUrl: mockImage(7), categoryName: 'Mẹo bếp', viewCount: 1800, voteScore: 41, publishedAt: DateTime(2026, 8, 28)),
    BlogItem(id: 4, title: 'Nấm - siêu thực phẩm cho người ăn chay', thumbnailUrl: mockImage(1), categoryName: 'Dinh dưỡng', viewCount: 990, voteScore: 23, publishedAt: DateTime(2026, 8, 20)),
  ];
}
