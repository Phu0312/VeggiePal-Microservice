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
import 'package:VeggiePal/features/community/presentation/community_widgets.dart';
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

    testWidgets('hiện chủ đề (cuộn ngang) và bảng xếp hạng với tên tác giả; không còn thống kê, "x/7 ngày", kênh video', (tester) async {
      await mount(tester, _seed());
      expect(find.text('Món chính • 8'), findsOneWidget);
      expect(find.text('Mẹo vặt • 3'), findsOneWidget);
      expect(find.text('An Nguyễn'), findsOneWidget);
      expect(find.text('Bình Trần'), findsOneWidget);
      expect(find.textContaining('5 bài • 1 video • 40 lượt thích'), findsOneWidget);
      expect(find.text('Đang theo dõi'), findsOneWidget);
      expect(find.text('bài đăng'), findsNothing); // đã bỏ hàng thống kê
      expect(find.text('0/7 ngày'), findsNothing);
      expect(find.text('Kênh video đề xuất'), findsNothing); // đã chuyển sang tab Video
      expect(api.calls, isNot(contains('GET /videos/channels')));
    });

    testWidgets('theo dõi một tác giả cập nhật nút và số người theo dõi ở mọi nơi tác giả đó xuất hiện', (tester) async {
      await mount(tester, _seed());
      api.results[Endpoints.authorFollow(7)] = {'authorId': 7, 'following': true, 'followersCount': 4};
      await tester.tap(find.widgetWithText(FilledButton, 'Theo dõi').first);
      await tester.pumpAndSettle();

      expect(api.calls, contains('POST /blogs/authors/7/follow'));
      expect(find.text('Đang theo dõi'), findsNWidgets(2)); // Bình Trần sẵn có + An Nguyễn vừa theo dõi
      expect(find.textContaining('4 người theo dõi'), findsOneWidget);
    });

    testWidgets('điểm danh thử thách: hiện tiến độ mới', (tester) async {
      await mount(tester, _seed());
      api.results[Endpoints.challengeCheckIn] = _challenge(days: 1, today: true);
      await tester.tap(find.text('Điểm danh hôm nay'));
      await tester.pumpAndSettle();

      expect(api.calls, contains('POST /blogs/challenge/check-in'));
      expect(find.text('Điểm danh hôm nay'), findsNothing); // đã điểm danh hôm nay thì ẩn nút
      expect(find.textContaining('Hôm nay bạn đã điểm danh'), findsOneWidget);
    });

    testWidgets('ngày thứ 7: báo hoàn thành, huy hiệu do BE cấp nên app không tự mở khoá', (tester) async {
      await mount(tester, _seed(challenge: _challenge(days: 6)));
      api.results[Endpoints.challengeCheckIn] = _challenge(days: 7, today: true, completed: true, just: true);
      await tester.tap(find.text('Điểm danh hôm nay'));
      await tester.pumpAndSettle();

      expect(find.text('Hoàn thành thử thách!'), findsOneWidget);
      expect(api.calls.where((c) => c.contains('/users/me/badges/')), isEmpty);
    });

    testWidgets('BE chưa cấp được huy hiệu (3053): tiến độ vẫn hoàn thành, có nút nhận lại huy hiệu', (tester) async {
      await mount(tester, _seed(challenge: _challenge(days: 6)));
      api.errors[Endpoints.challengeCheckIn] =
          ApiException('Badge award is temporarily unavailable', code: 3053, statusCode: 503);
      api.results[Endpoints.challengeMe] = _challenge(days: 7, today: true, completed: true);
      await tester.tap(find.text('Điểm danh hôm nay'));
      await tester.pumpAndSettle();

      expect(find.text('Đã hoàn thành thử thách'), findsOneWidget);
      expect(find.text('Không điểm danh được'), findsNothing);
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();
      expect(find.text('Nhận huy hiệu'), findsOneWidget);

      // Lần nhận lại thành công: BE cấp huy hiệu rồi nút biến mất.
      api.errors.remove(Endpoints.challengeCheckIn);
      api.results[Endpoints.challengeCheckIn] = _challenge(days: 7, today: true, completed: true);
      await tester.tap(find.text('Nhận huy hiệu'));
      await tester.pumpAndSettle();
      expect(api.calls.where((c) => c == 'POST /blogs/challenge/check-in'), hasLength(2));
      expect(find.text('Nhận huy hiệu'), findsNothing);
    });

    testWidgets('3053 nhưng thử thách chưa hoàn thành: hiện lỗi như thường, không có nút nhận huy hiệu', (tester) async {
      await mount(tester, _seed(challenge: _challenge(days: 2)));
      api.errors[Endpoints.challengeCheckIn] = ApiException('Dịch vụ tạm lỗi', code: 3053, statusCode: 503);
      await tester.tap(find.text('Điểm danh hôm nay'));
      await tester.pumpAndSettle();

      expect(find.text('Không điểm danh được'), findsOneWidget);
      expect(find.text('Nhận huy hiệu'), findsNothing);
    });

    Map<String, dynamic> badgesJson({required bool earned}) => {
          'earnedCount': earned ? 1 : 0,
          'totalCount': 6,
          'badges': [
            {'code': 'VEGGIE_GREEN_HEART', 'title': 'Trái Tim Xanh Veggie', 'description': 'd', 'icon': 'calendar', 'earned': earned},
          ],
        };

    testWidgets('mở màn hình khi đã hoàn thành mà hồ sơ chưa có huy hiệu: hiện nút nhận huy hiệu', (tester) async {
      await mount(
          tester,
          _seed(challenge: _challenge(days: 7, today: true, completed: true))
            ..results[Endpoints.myBadges] = badgesJson(earned: false));
      expect(find.text('Nhận huy hiệu'), findsOneWidget);
      expect(find.textContaining('huy hiệu chưa được cấp'), findsOneWidget);
    });

    testWidgets('mở màn hình khi đã hoàn thành và đã có huy hiệu: không có nút nhận', (tester) async {
      await mount(
          tester,
          _seed(challenge: _challenge(days: 7, today: true, completed: true))
            ..results[Endpoints.myBadges] = badgesJson(earned: true));
      expect(find.text('Nhận huy hiệu'), findsNothing);
      expect(find.textContaining('đã hoàn thành thử thách và nhận huy hiệu'), findsOneWidget);
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
      // tác giả mã 3 là tôi: không có dòng của tôi trong bảng xếp hạng, chỉ còn Bình Trần (đang được theo dõi)
      expect(find.byType(AuthorTile), findsOneWidget);
      expect(find.text('Bình Trần'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Theo dõi'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Đang theo dõi'), findsOneWidget);
    });
  });

  group('VideoChannelsStrip', () {
    Future<_Api> mount(WidgetTester tester, {bool loggedIn = true}) async {
      final api = _seed();
      (api.results[Endpoints.videoChannels] as List).add(
          {'authorId': 3, 'videoCount': 9, 'totalViews': 5000, 'totalLikes': 1, 'followersCount': 0, 'following': false});
      api.results[Endpoints.usersBatch] = [
        {'id': 7, 'fullName': 'An Nguyễn'},
        {'id': 3, 'fullName': 'Tôi Đây'},
      ];
      if (loggedIn) api.token = 't';
      final auth = AuthController(api, AuthRepository(api), SessionStore(),
          initial: loggedIn ? const AuthSession('t', AuthUser(id: 3, email: 'a@b.c', fullName: 'Tôi', role: UserRole.user)) : null);
      await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<CommunityRepository>.value(value: CommunityRepository(api)),
          Provider<ProfileRepository>.value(value: ProfileRepository(api)),
          ChangeNotifierProvider<AuthController>.value(value: auth),
        ],
        child: const MaterialApp(home: Scaffold(body: VideoChannelsStrip())),
      ));
      await tester.pumpAndSettle();
      return api;
    }

    testWidgets('hiện các kênh đề xuất nhưng không có chính mình', (tester) async {
      await mount(tester);
      expect(find.text('Kênh video đề xuất'), findsOneWidget);
      expect(find.text('An Nguyễn'), findsOneWidget);
      expect(find.text('Tôi Đây'), findsNothing);
      expect(find.textContaining('1.200 lượt xem'), findsOneWidget);
    });

    testWidgets('khách thấy cả kênh mã 3 (không có ai là "mình"); bấm theo dõi thì mở đăng nhập', (tester) async {
      final api = await mount(tester, loggedIn: false);
      expect(find.text('Tôi Đây'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Theo dõi').first);
      await tester.pumpAndSettle();
      expect(api.calls.where((c) => c.startsWith('POST')), isEmpty);
      expect(find.text('Đăng nhập'), findsWidgets);
    });
  });
}
