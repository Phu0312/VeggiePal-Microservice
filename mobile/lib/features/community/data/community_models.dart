// Cộng đồng VeggiePal (blog-service: `/blogs/community/*`, `/videos/channels`, theo dõi tác giả, thử thách 7 ngày).

int _i(Object? v) => v is num ? v.toInt() : 0;

/// Thống kê chung của cộng đồng (CommunityStatsResponse).
class CommunityStats {
  final int publishedBlogs, publishedVideos, totalPosts, activeAuthors, totalComments;
  const CommunityStats(
      {this.publishedBlogs = 0,
      this.publishedVideos = 0,
      this.totalPosts = 0,
      this.activeAuthors = 0,
      this.totalComments = 0});

  factory CommunityStats.fromJson(Map<String, dynamic> j) => CommunityStats(
        publishedBlogs: _i(j['publishedBlogs']),
        publishedVideos: _i(j['publishedVideos']),
        totalPosts: _i(j['totalPosts']),
        activeAuthors: _i(j['activeAuthors']),
        totalComments: _i(j['totalComments']),
      );
}

/// Chủ đề được nhiều bài đăng nhất (TrendingTopicResponse).
class TrendingTopic {
  final int categoryId;
  final String name;
  final int count;
  const TrendingTopic(this.categoryId, this.name, this.count);

  factory TrendingTopic.fromJson(Map<String, dynamic> j) =>
      TrendingTopic(_i(j['categoryId']), '${j['name'] ?? ''}', _i(j['count']));
}

/// Một tác giả trong bảng xếp hạng hoặc một kênh video: cùng dạng số liệu, khác nhau ở thứ được xếp hạng.
/// BE chỉ trả mã tác giả nên tên và ảnh được lấy riêng qua `/users/batch`.
class CommunityAuthor {
  final int authorId;
  final int articles; // bài viết (bảng xếp hạng)
  final int videos; // video
  final int views; // lượt xem (kênh video)
  final int likes;
  final int followers;
  final bool following;

  const CommunityAuthor({
    required this.authorId,
    this.articles = 0,
    this.videos = 0,
    this.views = 0,
    this.likes = 0,
    this.followers = 0,
    this.following = false,
  });

  /// LeaderboardEntryResponse.
  factory CommunityAuthor.fromLeaderboard(Map<String, dynamic> j) => CommunityAuthor(
        authorId: _i(j['authorId']),
        articles: _i(j['articlesCount']),
        videos: _i(j['videosCount']),
        likes: _i(j['totalLikes']),
        followers: _i(j['followersCount']),
        following: j['following'] == true,
      );

  /// VideoChannelResponse.
  factory CommunityAuthor.fromChannel(Map<String, dynamic> j) => CommunityAuthor(
        authorId: _i(j['authorId']),
        videos: _i(j['videoCount']),
        views: _i(j['totalViews']),
        likes: _i(j['totalLikes']),
        followers: _i(j['followersCount']),
        following: j['following'] == true,
      );

  CommunityAuthor withFollow({required bool following, required int followers}) => CommunityAuthor(
        authorId: authorId,
        articles: articles,
        videos: videos,
        views: views,
        likes: likes,
        followers: followers,
        following: following,
      );
}

/// Kết quả theo dõi / bỏ theo dõi một tác giả (FollowResponse).
class FollowState {
  final int authorId;
  final bool following;
  final int followers;
  const FollowState(this.authorId, this.following, this.followers);

  factory FollowState.fromJson(Map<String, dynamic> j) =>
      FollowState(_i(j['authorId']), j['following'] == true, _i(j['followersCount']));
}

/// Tiến độ thử thách "7 ngày sống thuần chay" (ChallengeProgressResponse).
class ChallengeProgress {
  final int days;
  final int total;
  final bool checkedToday;
  final bool completed;
  final bool broken; // chuỗi bị đứt: lần điểm danh kế tiếp bắt đầu lại từ ngày 1
  final bool justCompleted;
  final String? badgeName;

  const ChallengeProgress({
    this.days = 0,
    this.total = 7,
    this.checkedToday = false,
    this.completed = false,
    this.broken = false,
    this.justCompleted = false,
    this.badgeName,
  });

  factory ChallengeProgress.fromJson(Map<String, dynamic> j) => ChallengeProgress(
        days: _i(j['days']),
        total: j['total'] == null ? 7 : _i(j['total']),
        checkedToday: j['checkedToday'] == true,
        completed: j['completed'] == true,
        broken: j['broken'] == true,
        justCompleted: j['justCompleted'] == true,
        badgeName: j['badgeName'] as String?,
      );

  bool get canCheckIn => !completed && !checkedToday;
}
