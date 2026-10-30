import '../../../core/constants/endpoints.dart';
import '../../../core/network/api_client.dart';
import 'community_models.dart';

/// blog-service: cộng đồng. Số liệu chung, bảng xếp hạng và kênh video đọc được khi chưa đăng nhập
/// (có token thì BE trả thêm `following`); theo dõi tác giả và thử thách cần JWT.
/// Mọi lỗi được ném lại cho UI hiển thị popup.
class CommunityRepository {
  final ApiClient _api;
  CommunityRepository(this._api);

  void _requireLogin() {
    if (_api.token == null) throw ApiException('Vui lòng đăng nhập để sử dụng chức năng này.');
  }

  List<Map<String, dynamic>> _maps(dynamic r) =>
      [for (final e in asList(r)) Map<String, dynamic>.from(e as Map)];

  // GET /blogs/community/stats
  Future<CommunityStats> stats() async =>
      CommunityStats.fromJson(Map<String, dynamic>.from(await _api.get(Endpoints.communityStats) as Map));

  // GET /blogs/community/trending-topics?limit= : chủ đề nhiều bài đăng nhất.
  Future<List<TrendingTopic>> trendingTopics({int limit = 8}) async {
    final r = await _api.get(Endpoints.communityTrending, query: {'limit': limit});
    return _maps(r).map(TrendingTopic.fromJson).toList();
  }

  // GET /blogs/community/leaderboard?limit= : tác giả xếp theo số bài và lượt thích.
  Future<List<CommunityAuthor>> leaderboard({int limit = 5}) async {
    final r = await _api.get(Endpoints.communityLeaderboard, query: {'limit': limit});
    return _maps(r).map(CommunityAuthor.fromLeaderboard).toList();
  }

  // GET /videos/channels?limit= : người đăng video xếp theo số video và lượt xem.
  Future<List<CommunityAuthor>> videoChannels({int limit = 10}) async {
    final r = await _api.get(Endpoints.videoChannels, query: {'limit': limit});
    return _maps(r).map(CommunityAuthor.fromChannel).toList();
  }

  // POST /blogs/authors/{id}/follow và DELETE cùng đường dẫn. Lỗi 3070 = tự theo dõi chính mình.
  Future<FollowState> setFollow(int authorId, bool follow) async {
    _requireLogin();
    final r = follow
        ? await _api.post(Endpoints.authorFollow(authorId))
        : await _api.delete(Endpoints.authorFollow(authorId));
    return FollowState.fromJson(Map<String, dynamic>.from(r as Map));
  }

  // GET /blogs/me/following -> mã các tác giả tôi đang theo dõi.
  Future<Set<int>> myFollowing() async {
    _requireLogin();
    final r = await _api.get(Endpoints.myFollowing);
    return {for (final e in asList(r)) (e as num).toInt()};
  }

  // GET /blogs/challenge/me
  Future<ChallengeProgress> challenge() async {
    _requireLogin();
    final r = await _api.get(Endpoints.challengeMe);
    return ChallengeProgress.fromJson(Map<String, dynamic>.from(r as Map));
  }

  // POST /blogs/challenge/check-in : điểm danh hôm nay (lặp lại trong ngày không tính thêm).
  Future<ChallengeProgress> checkIn() async {
    _requireLogin();
    final r = await _api.post(Endpoints.challengeCheckIn);
    return ChallengeProgress.fromJson(Map<String, dynamic>.from(r as Map));
  }
}
