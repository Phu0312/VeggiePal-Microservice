class CategoryItem {
  final int id;
  final String name;
  final String type; // FOOD_TYPE | RECIPE_TYPE
  const CategoryItem(this.id, this.name, [this.type = 'FOOD_TYPE']);

  factory CategoryItem.fromJson(Map<String, dynamic> j) => CategoryItem(
      (j['id'] as num).toInt(), '${j['name']}', '${j['type'] ?? 'FOOD_TYPE'}');
}

class VideoItem {
  final int id;
  final String title;
  final String? thumbnailUrl;
  final String? videoUrl;
  final int durationSeconds;
  final int viewCount;
  final int voteScore;
  final String? categoryName;

  const VideoItem({
    required this.id,
    required this.title,
    this.thumbnailUrl,
    this.videoUrl,
    this.durationSeconds = 0,
    this.viewCount = 0,
    this.voteScore = 0,
    this.categoryName,
  });

  factory VideoItem.fromJson(Map<String, dynamic> j) => VideoItem(
        id: (j['id'] as num).toInt(),
        title: '${j['title']}',
        thumbnailUrl: j['thumbnailUrl'] as String?,
        videoUrl: j['videoUrl'] as String?,
        durationSeconds: (j['durationSeconds'] as num?)?.toInt() ?? 0,
        viewCount: (j['viewCount'] as num?)?.toInt() ?? 0,
        voteScore: (j['voteScore'] as num?)?.toInt() ?? 0,
        categoryName: j['categoryName'] as String?,
      );

  String get durationText {
    final m = durationSeconds ~/ 60, s = durationSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class BlogItem {
  final int id;
  final String title;
  final String? thumbnailUrl;
  final String? categoryName;
  final int viewCount;
  final int voteScore;
  final DateTime? publishedAt;
  final String? content; // chỉ có ở API chi tiết
  final String? status; // DRAFT | PENDING | PUBLISHED | REJECTED | BANNED (chỉ có ở /blogs/me)
  final int? authorId;
  final int? categoryId;
  final DateTime? createdAt;
  final String? moderationReason; // chỉ có khi kiểm duyệt từ chối/hoãn (BlogResponse)

  const BlogItem({
    required this.id,
    required this.title,
    this.thumbnailUrl,
    this.categoryName,
    this.viewCount = 0,
    this.voteScore = 0,
    this.publishedAt,
    this.content,
    this.status,
    this.authorId,
    this.categoryId,
    this.createdAt,
    this.moderationReason,
  });

  factory BlogItem.fromJson(Map<String, dynamic> j) => BlogItem(
        id: (j['id'] as num).toInt(),
        title: '${j['title']}',
        thumbnailUrl: j['thumbnailUrl'] as String?,
        categoryName: j['categoryName'] as String?,
        viewCount: (j['viewCount'] as num?)?.toInt() ?? 0,
        voteScore: (j['voteScore'] as num?)?.toInt() ?? 0,
        publishedAt: j['publishedAt'] == null
            ? null
            : DateTime.tryParse('${j['publishedAt']}'),
        content: j['content'] as String?,
        status: j['status'] as String?,
        authorId: (j['authorId'] as num?)?.toInt(),
        categoryId: (j['categoryId'] as num?)?.toInt(),
        createdAt: j['createdAt'] == null ? null : DateTime.tryParse('${j['createdAt']}'),
        moderationReason: j['moderationReason'] as String?,
      );
}

/// Tên trạng thái bài viết tiếng Việt.
String blogStatusLabel(String? status) => switch (status) {
      'DRAFT' => 'Bản nháp',
      'PENDING' => 'Chờ duyệt',
      'PUBLISHED' => 'Đã đăng',
      'REJECTED' => 'Bị từ chối',
      'BANNED' => 'Bị gỡ',
      _ => status ?? '',
    };
