import 'package:dio/dio.dart' show ProgressCallback;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:VeggiePal/core/constants/endpoints.dart';
import 'package:VeggiePal/core/network/api_client.dart';
import 'package:VeggiePal/core/storage/session_store.dart';
import 'package:VeggiePal/features/auth/data/auth_models.dart';
import 'package:VeggiePal/features/auth/data/auth_repository.dart';
import 'package:VeggiePal/features/auth/presentation/auth_controller.dart';
import 'package:VeggiePal/features/community/data/community_models.dart';
import 'package:VeggiePal/features/community/data/community_repository.dart';
import 'package:VeggiePal/features/community/presentation/community_screen.dart';
import 'package:VeggiePal/features/profile/data/profile_repository.dart';

/// ApiClient giả: ghi lại lời gọi, query và body, trả kết quả theo đường dẫn; ném lỗi cho đường dẫn đã đặt.
class _Api extends ApiClient {
  final calls = <String>[];
  final queries = <String, Map<String, dynamic>?>{};
  final results = <String, Object?>{};
  final errors = <String, ApiException>{};

  Object? _hit(String method, String path, [Map<String, dynamic>? q]) {
    calls.add('$method $path');
    queries[path] = q;
    final e = errors[path];
    if (e != null) throw e;
    return results[path];
  }

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async => _hit('GET', path, query);

  @override
  Future<dynamic> post(String path,
          {Object? body, Map<String, String>? headers, ProgressCallback? onSendProgress, Duration? receiveTimeout}) async =>
      _hit('POST', path);

  @override
  Future<dynamic> delete(String path) async => _hit('DELETE', path);
}

Map<String, dynamic> _challenge({int days = 0, bool today = false, bool completed = false, bool broken = false, bool just = false}) => {
      'days': days,
      'total': 7,
      'checkedToday': today,
      'completed': completed,
      'broken': broken,
      'justCompleted': just,
      'badgeName': 'Trái Tim Xanh Veggie',
      'checkIns': <String>[],
    };

_Api _seed({Map<String, dynamic>? challenge}) => _Api()
  ..results[Endpoints.communityStats] = {
    'publishedBlogs': 12,
    'publishedVideos': 5,
    'totalPosts': 17,
    'activeAuthors': 4,
    'totalComments': 30
  }
  ..results[Endpoints.communityTrending] = [
    {'categoryId': 1, 'name': 'Món chính', 'tag': 'mon-chinh', 'count': 8},
    {'categoryId': 2, 'name': 'Mẹo vặt', 'tag': 'meo-vat', 'count': 3},
  ]
  ..results[Endpoints.communityLeaderboard] = [
    {'authorId': 7, 'articlesCount': 5, 'videosCount': 1, 'postsCount': 6, 'totalLikes': 40, 'followersCount': 3, 'following': false},
    {'authorId': 9, 'articlesCount': 2, 'videosCount': 0, 'postsCount': 2, 'totalLikes': 10, 'followersCount': 1, 'following': true},
  ]
  ..results[Endpoints.videoChannels] = [
    {'authorId': 7, 'videoCount': 1, 'totalViews': 1200, 'totalLikes': 8, 'followersCount': 3, 'following': false},
  ]
  ..results[Endpoints.usersBatch] = [
    {'id': 7, 'fullName': 'An Nguyễn'},
    {'id': 9, 'fullName': 'Bình Trần'},
  ]
  ..results[Endpoints.challengeMe] = challenge ?? _challenge();

void main() {
  setUp(() => dotenv.loadFromString(envString: 'APP=test'));

  group('mô hình và repository', () {
    test('ChallengeProgress: chỉ điểm danh được khi chưa hoàn thành và chưa điểm danh hôm nay', () {
      expect(ChallengeProgress.fromJson(_challenge(days: 2)).canCheckIn, isTrue);
      expect(ChallengeProgress.fromJson(_challenge(days: 2, today: true)).canCheckIn, isFalse);
      expect(ChallengeProgress.fromJson(_challenge(days: 7, completed: true)).canCheckIn, isFalse);
      expect(ChallengeProgress.fromJson(_challenge(broken: true)).broken, isTrue);
    });

    test('CommunityAuthor đọc được cả bảng xếp hạng và kênh video; withFollow chỉ đổi theo dõi', () {
      final a = CommunityAuthor.fromLeaderboard({'authorId': 7, 'articlesCount': 5, 'videosCount': 1, 'totalLikes': 40, 'followersCount': 3, 'following': false});
      expect((a.articles, a.videos, a.likes, a.followers), (5, 1, 40, 3));
      final c = CommunityAuthor.fromChannel({'authorId': 7, 'videoCount': 4, 'totalViews': 900, 'totalLikes': 2, 'followersCount': 1});
      expect((c.videos, c.views), (4, 900));
      final f = a.withFollow(following: true, followers: 4);
      expect((f.following, f.followers, f.articles), (true, 4, 5));
    });

    test('repository gọi đúng đường dẫn và tham số', () async {
      final api = _seed()
        ..token = 't'
        ..results[Endpoints.authorFollow(7)] = {'authorId': 7, 'following': true, 'followersCount': 4}
        ..results[Endpoints.myFollowing] = [7, 9]
        ..results[Endpoints.challengeCheckIn] = _challenge(days: 1, today: true);
      final repo = CommunityRepository(api);

      expect((await repo.stats()).totalPosts, 17);
      expect((await repo.trendingTopics()).first.name, 'Món chính');
      expect(api.queries[Endpoints.communityTrending], {'limit': 8});
      expect((await repo.leaderboard(limit: 3)).length, 2);
      expect(api.queries[Endpoints.communityLeaderboard], {'limit': 3});
      expect((await repo.videoChannels()).single.views, 1200);

      final f = await repo.setFollow(7, true);
      expect((f.following, f.followers), (true, 4));
      await repo.setFollow(7, false);
      expect(api.calls.sublist(api.calls.length - 2), ['POST /blogs/authors/7/follow', 'DELETE /blogs/authors/7/follow']);
      expect(await repo.myFollowing(), {7, 9});
      expect((await repo.checkIn()).checkedToday, isTrue);
    });

    test('theo dõi và điểm danh khi chưa đăng nhập bị chặn trước khi gọi mạng', () async {
      final api = _Api();
      final repo = CommunityRepository(api);
      await expectLater(repo.setFollow(7, true), throwsA(isA<ApiException>()));
      await expectLater(repo.checkIn(), throwsA(isA<ApiException>()));
      expect(api.calls, isEmpty);
    });
  });

  group('CommunityScreen', () {
    late _Api api;

    Future<AuthController> mount(WidgetTester tester, _Api seeded, {bool loggedIn = true}) async {
      api = seeded;
      if (loggedIn) api.token = 't';
      final auth = AuthController(api, AuthRepository(api), SessionStore(),
          initial: loggedIn ? const AuthSession('t', AuthUser(id: 3, email: 'a@b.c', fullName: 'Tôi', role: UserRole.user)) : null);
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<CommunityRepository>.value(value: CommunityRepository(api)),
          Provider<ProfileRepository>.value(value: ProfileRepository(api)),
          ChangeNotifierProvider<AuthController>.value(value: auth),
        ],
        child: const MaterialApp(home: CommunityScreen()),
      ));
      await tester.pumpAndSettle();
      return auth;
    }

    testWidgets('hiện thống kê, chủ đề, bảng xếp hạng với tên tác giả và kênh video', (tester) async {
      await mount(tester, _seed());
      expect(find.text('17'), findsOneWidget);
      expect(find.text('Món chính • 8'), findsOneWidget);
      expect(find.text('An Nguyễn'), findsNWidgets(2)); // bảng xếp hạng + kênh video
      expect(find.text('Bình Trần'), findsOneWidget);
      expect(find.textContaining('5 bài • 1 video • 40 lượt thích'), findsOneWidget);
      expect(find.textContaining('1.200 lượt xem'), findsOneWidget);
      expect(find.text('Đang theo dõi'), findsOneWidget);
      expect(find.text('0/7 ngày'), findsOneWidget);
    });

    testWidgets('theo dõi một tác giả cập nhật nút và số người theo dõi ở mọi nơi tác giả đó xuất hiện', (tester) async {
      await mount(tester, _seed());
      api.results[Endpoints.authorFollow(7)] = {'authorId': 7, 'following': true, 'followersCount': 4};
      await tester.tap(find.widgetWithText(FilledButton, 'Theo dõi').first);
      await tester.pumpAndSettle();

      expect(api.calls, contains('POST /blogs/authors/7/follow'));
      expect(find.text('Đang theo dõi'), findsNWidgets(3)); // Bình Trần sẵn có + An Nguyễn ở bảng xếp hạng và kênh
      expect(find.textContaining('4 người theo dõi'), findsNWidgets(2));
    });

    testWidgets('điểm danh thử thách: hiện tiến độ mới', (tester) async {
      await mount(tester, _seed());
      api.results[Endpoints.challengeCheckIn] = _challenge(days: 1, today: true);
      await tester.tap(find.text('Điểm danh hôm nay'));
      await tester.pumpAndSettle();

      expect(api.calls, contains('POST /blogs/challenge/check-in'));
      expect(find.text('1/7 ngày'), findsOneWidget);
      expect(find.text('Điểm danh hôm nay'), findsNothing); // đã điểm danh hôm nay thì ẩn nút
      expect(find.textContaining('Hôm nay bạn đã điểm danh'), findsOneWidget);
    });

    testWidgets('ngày thứ 7: báo hoàn thành và mở khoá huy hiệu', (tester) async {
      await mount(tester, _seed(challenge: _challenge(days: 6)));
      api.results[Endpoints.challengeCheckIn] = _challenge(days: 7, today: true, completed: true, just: true);
      await tester.tap(find.text('Điểm danh hôm nay'));
      await tester.pumpAndSettle();

      expect(find.text('Hoàn thành thử thách!'), findsOneWidget);
      expect(api.calls, contains('POST /users/me/badges/VEGGIE_GREEN_HEART'));
    });

    testWidgets('chuỗi bị đứt: nhắc bắt đầu lại', (tester) async {
      await mount(tester, _seed(challenge: _challenge(broken: true)));
      expect(find.textContaining('bắt đầu lại từ ngày 1'), findsOneWidget);
      expect(find.text('Điểm danh hôm nay'), findsOneWidget);
    });

    testWidgets('khách: xem được cộng đồng, bấm tham gia hoặc theo dõi thì mở đăng nhập, không gọi BE', (tester) async {
      await mount(tester, _seed(), loggedIn: false);
      expect(api.calls, isNot(contains('GET /blogs/challenge/me')));
      expect(find.text('Bình Trần'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Theo dõi').first);
      await tester.pumpAndSettle();
      expect(api.calls.where((c) => c.startsWith('POST')), isEmpty);
      expect(find.text('Đăng nhập'), findsWidgets);
    });

    testWidgets('không có nút theo dõi cho chính mình', (tester) async {
      final seeded = _seed();
      (seeded.results[Endpoints.communityLeaderboard] as List)[0]['authorId'] = 3;
      await mount(tester, seeded);
      // tác giả mã 3 là tôi: chỉ còn nút của Bình Trần ở bảng xếp hạng và An Nguyễn (mã 7) ở kênh video
      expect(find.widgetWithText(FilledButton, 'Theo dõi'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Đang theo dõi'), findsOneWidget);
    });
  });
}
