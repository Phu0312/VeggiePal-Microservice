import 'package:dio/dio.dart' show ProgressCallback;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:VeggiePal/core/constants/endpoints.dart';
import 'package:VeggiePal/core/network/api_client.dart';
import 'package:VeggiePal/core/storage/session_store.dart';
import 'package:VeggiePal/features/auth/data/auth_models.dart';
import 'package:VeggiePal/features/auth/data/auth_repository.dart';
import 'package:VeggiePal/features/auth/presentation/auth_controller.dart';
import 'package:VeggiePal/features/blog/data/blog_repository.dart';
import 'package:VeggiePal/features/blog/presentation/blog_editor_screen.dart';
import 'package:VeggiePal/features/home/data/home_models.dart';
import 'package:VeggiePal/features/home/data/home_repository.dart';
import 'package:VeggiePal/features/home/data/recommendation_controller.dart';
import 'package:VeggiePal/features/home/data/recommendation_repository.dart';
import 'package:VeggiePal/features/home/presentation/blog_detail_screen.dart';
import 'package:VeggiePal/features/home/presentation/home_screen.dart';
import 'package:VeggiePal/features/home/presentation/post_card.dart';
import 'package:VeggiePal/features/profile/data/profile_repository.dart';
import 'package:VeggiePal/features/recipe/data/recipe_repository.dart';

/// ApiClient giả: trả kết quả theo đường dẫn, ghi lại mọi lời gọi (đường dẫn + query) để kiểm tra.
class FakeApi extends ApiClient {
  final calls = <String>[];
  final queries = <String, List<Map<String, dynamic>?>>{};
  final results = <String, Object? Function()>{};

  void on(String path, Object? Function() answer) => results[path] = answer;

  List<Map<String, dynamic>?> queriesOf(String path) => queries[path] ?? const [];
  int count(String path) => calls.where((c) => c == path).length;

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    calls.add(path);
    (queries[path] ??= []).add(query);
    return results[path]?.call();
  }

  @override
  Future<dynamic> post(String path,
          {Object? body, Map<String, String>? headers, ProgressCallback? onSendProgress, Duration? receiveTimeout}) async =>
      null;
}

Map<String, dynamic> _page(List<Map<String, dynamic>> items, {int total = 0}) => {
      'content': items,
      'page': 0,
      'size': 10,
      'totalElements': total == 0 ? items.length : total,
      'totalPages': 1,
    };

Map<String, dynamic> _blog(int id, String title,
        {int authorId = 9, String? status, String? content, String? reason, int score = 3}) =>
    {
      'id': id,
      'title': title,
      'authorId': authorId,
      'categoryId': 2,
      'categoryName': 'Món chính',
      'viewCount': 5,
      'voteScore': score,
      'publishedAt': status == null || status == 'PUBLISHED' ? '2026-10-20T08:00:00' : null,
      'createdAt': '2026-10-19T08:00:00',
      'status': status,
      'content': content,
      'moderationReason': reason,
    };

final _tree = [
  {
    'id': 1,
    'name': 'Món mặn',
    'type': 'FOOD_TYPE',
    'children': [
      {'id': 2, 'name': 'Món chính', 'type': 'FOOD_TYPE'},
    ],
  },
  {'id': 3, 'name': 'Mẹo vặt', 'type': 'RECIPE_TYPE', 'children': <dynamic>[]},
];

const _owner = AuthSession('t', AuthUser(id: 9, email: 'a@b.c', fullName: 'An', role: UserRole.user));
const _other = AuthSession('t', AuthUser(id: 4, email: 'c@d.e', fullName: 'Bình', role: UserRole.user));

FakeApi _api() => FakeApi()
  ..on(Endpoints.categories, () => _tree)
  ..on(Endpoints.blogs, () => _page([_blog(1, 'Đậu hũ sốt cà'), _blog(2, 'Canh nấm')]))
  ..on(Endpoints.comments, () => _page(const []))
  ..on(Endpoints.recipes, () => _page(const []))
  ..on(Endpoints.usersBatch, () => [
        {'id': 9, 'fullName': 'An'}
      ]);

Future<void> _mount(WidgetTester tester, FakeApi api, Widget child, {AuthSession? session}) async {
  if (session != null) api.token = session.token;
  final auth = AuthController(api, AuthRepository(api), SessionStore(), initial: session);
  tester.view.physicalSize = const Size(800, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MultiProvider(
    providers: [
      Provider<ApiClient>.value(value: api),
      Provider<HomeRepository>.value(value: HomeRepository(api)),
      Provider<BlogRepository>.value(value: BlogRepository(api)),
      Provider<ProfileRepository>.value(value: ProfileRepository(api)),
      Provider<RecipeRepository>.value(value: RecipeRepository(api)),
      ChangeNotifierProvider<AuthController>.value(value: auth),
      ChangeNotifierProvider<RecommendationController>.value(
          value: RecommendationController(RecommendationRepository(api))..bindUser(session?.user.id)),
    ],
    child: MaterialApp(home: child),
  ));
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() => dotenv.loadFromString(envString: 'APP=test'));

  group('HomeRepository', () {
    test('categories lấy mọi loại danh mục (không lọc type) và làm phẳng cấp con', () async {
      final api = _api();
      final cats = await HomeRepository(api).categories();
      expect(api.queriesOf(Endpoints.categories).single, isNull);
      expect(cats.map((c) => c.name), ['Món mặn', 'Món chính', 'Mẹo vặt']);
      expect(cats.map((c) => c.type), ['FOOD_TYPE', 'FOOD_TYPE', 'RECIPE_TYPE']);
    });

    test('blogsPage chỉ gửi sort khi khác mặc định', () async {
      final api = _api();
      final repo = HomeRepository(api);
      await repo.blogsPage();
      await repo.blogsPage(sort: 'popular', categoryId: 3, keyword: '', page: 2);
      final q = api.queriesOf(Endpoints.blogs);
      expect(q[0], {'page': 0, 'size': 10});
      expect(q[1], {'categoryId': 3, 'sort': 'popular', 'page': 2, 'size': 10});
    });
  });

  group('HomeScreen: lọc bảng tin', () {
    Future<FakeApi> boot(WidgetTester tester, {AuthSession? session}) async {
      final api = _api();
      await _mount(tester, api, const Scaffold(body: HomeScreen()), session: session);
      return api;
    }

    Map<String, dynamic>? lastFeedQuery(FakeApi api) => api.queriesOf(Endpoints.blogs).last;

    testWidgets('mặc định mới nhất; chọn Nổi bật / Xem nhiều gửi đúng sort, danh mục không bị tải lại', (tester) async {
      final api = await boot(tester);
      expect(lastFeedQuery(api), {'page': 0, 'size': 10});
      expect(find.widgetWithText(ChoiceChip, 'Mẹo vặt'), findsOneWidget); // danh mục thuộc loại RECIPE_TYPE cũng có chip
      expect(find.widgetWithText(ChoiceChip, 'Món chính'), findsOneWidget); // danh mục con cũng có chip
      expect(find.text('Xoá bộ lọc'), findsNothing);

      await tester.tap(find.text('Nổi bật'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(lastFeedQuery(api), {'sort': 'popular', 'page': 0, 'size': 10});

      await tester.tap(find.text('Xem nhiều'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(lastFeedQuery(api), {'sort': 'mostViewed', 'page': 0, 'size': 10});
      expect(api.count(Endpoints.categories), 1);
    });

    testWidgets('gõ tìm kiếm: đợi 400ms rồi mới gọi một lần', (tester) async {
      final api = await boot(tester);
      final before = api.count(Endpoints.blogs);

      await tester.enterText(find.byType(TextField), 'n');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(find.byType(TextField), 'nấm');
      await tester.pump(const Duration(milliseconds: 300));
      expect(api.count(Endpoints.blogs), before); // chưa đủ 400ms kể từ phím cuối

      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 100));
      expect(api.count(Endpoints.blogs), before + 1);
      expect(lastFeedQuery(api), {'keyword': 'nấm', 'page': 0, 'size': 10});
    });

    testWidgets('không có kết quả: báo khớp bộ lọc và Xoá bộ lọc trả về bảng tin đầy đủ', (tester) async {
      final api = await boot(tester);
      api.on(Endpoints.blogs, () => _page(const []));

      await tester.tap(find.widgetWithText(ChoiceChip, 'Mẹo vặt'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(lastFeedQuery(api), {'categoryId': 3, 'page': 0, 'size': 10});
      expect(find.text('Không có bài viết khớp bộ lọc'), findsOneWidget);

      api.on(Endpoints.blogs, () => _page([_blog(1, 'Đậu hũ sốt cà')]));
      await tester.tap(find.text('Xoá bộ lọc').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(lastFeedQuery(api), {'page': 0, 'size': 10});
      expect(find.text('Đậu hũ sốt cà'), findsOneWidget);
      expect(find.text('Xoá bộ lọc'), findsNothing);
    });

    testWidgets('người khác xem: thẻ bài cho phép bầu chọn', (tester) async {
      await boot(tester, session: _other);
      final cards = tester.widgetList<PostCard>(find.byType(PostCard)).toList();
      expect(cards.every((c) => c.canVote), isTrue); // tác giả là user 9, người xem là user 4
    });

    testWidgets('tác giả xem: thẻ bài bị khoá nút bầu chọn', (tester) async {
      await boot(tester, session: _owner);
      final cards = tester.widgetList<PostCard>(find.byType(PostCard)).toList();
      expect(cards, isNotEmpty);
      expect(cards.every((c) => !c.canVote), isTrue);
    });
  });

  group('BlogDetailScreen', () {
    Future<FakeApi> boot(WidgetTester tester, Map<String, dynamic> detail, {AuthSession? session}) async {
      final api = _api()
        ..on(Endpoints.blogById(7), () => detail)
        ..on(Endpoints.blogRelated(7), () => [_blog(8, 'Bài liên quan')])
        ..on(Endpoints.myBlogVotes, () => <dynamic>[]);
      await _mount(tester, api, BlogDetailScreen(summary: BlogItem.fromJson(_blog(7, detail['title'] as String, status: detail['status'] as String?))),
          session: session);
      return api;
    }

    bool voteEnabled(WidgetTester tester) =>
        tester.widget<IconButton>(find.widgetWithIcon(IconButton, LucideIcons.thumbsUp)).onPressed != null;

    testWidgets('bài nháp của tác giả: hiện trạng thái, không gọi bài liên quan / phiếu bầu / bình luận', (tester) async {
      final api = await boot(tester, _blog(7, 'Bản nháp của tôi', status: 'DRAFT', content: 'Nội dung nháp đủ dài để xem'),
          session: _owner);
      expect(find.text('Nội dung nháp đủ dài để xem'), findsOneWidget);
      expect(find.textContaining('Bản nháp. Chỉ mình bạn xem được'), findsOneWidget);
      expect(find.byIcon(LucideIcons.thumbsUp), findsNothing);
      expect(find.text('Bài viết liên quan'), findsNothing);
      expect(api.count(Endpoints.blogRelated(7)), 0);
      expect(api.count(Endpoints.myBlogVotes), 0);
      expect(api.count(Endpoints.comments), 0);
      expect(find.byType(PopupMenuButton<String>), findsOneWidget); // Sửa / Xoá
    });

    testWidgets('bài bị từ chối hiện lý do kiểm duyệt', (tester) async {
      await boot(tester, _blog(7, 'Bài vi phạm', status: 'REJECTED', content: 'Nội dung bị từ chối ở đây', reason: 'Có quảng cáo'),
          session: _owner);
      expect(find.textContaining('Bị từ chối'), findsWidgets);
      expect(find.textContaining('Lý do: Có quảng cáo'), findsOneWidget);
    });

    testWidgets('bài đã đăng của người khác: bầu chọn được, có bài liên quan, không có menu Sửa / Xoá', (tester) async {
      final api = await boot(tester, _blog(7, 'Đậu hũ sốt cà', status: 'PUBLISHED', content: 'Nội dung bài đã đăng đầy đủ'),
          session: _other);
      expect(voteEnabled(tester), isTrue);
      expect(find.text('Bài viết liên quan'), findsOneWidget);
      expect(find.byType(PopupMenuButton<String>), findsNothing);
      expect(api.count(Endpoints.myBlogVotes), 1);
    });

    testWidgets('bài đã đăng của chính mình: khoá nút bầu chọn và giải thích', (tester) async {
      await boot(tester, _blog(7, 'Đậu hũ sốt cà', status: 'PUBLISHED', content: 'Nội dung bài đã đăng đầy đủ'),
          session: _owner);
      expect(voteEnabled(tester), isFalse);
      expect(find.text('Bạn không thể bầu chọn cho bài viết của mình'), findsOneWidget);
      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    });
  });

  group('BlogEditorScreen', () {
    Future<FakeApi> boot(WidgetTester tester, String status, {String? content}) async {
      final api = _api()
        ..on(Endpoints.blogById(7), () => _blog(7, 'Tiêu đề cũ', status: status, content: content));
      await _mount(tester, api, BlogEditorScreen(existing: BlogItem.fromJson(_blog(7, 'Tiêu đề cũ', status: status))), session: _owner);
      return api;
    }

    for (final status in ['DRAFT', 'PENDING', 'REJECTED', 'PUBLISHED']) {
      testWidgets('sửa bài $status: nạp lại nội dung cũ từ GET /blogs/{id}', (tester) async {
        final api = await boot(tester, status, content: 'Nội dung đã lưu trước đó của bài');
        expect(api.count(Endpoints.blogById(7)), 1);
        expect(find.text('Nội dung đã lưu trước đó của bài'), findsOneWidget);
        expect(find.textContaining('nhập lại nội dung'), findsNothing);
        expect(find.textContaining('32 ký tự'), findsOneWidget);
      });
    }

    testWidgets('viết bài mới: không gọi GET chi tiết, bộ đếm báo thiếu ký tự', (tester) async {
      final api = _api();
      await _mount(tester, api, const BlogEditorScreen(), session: _owner);
      expect(api.count(Endpoints.blogById(7)), 0);
      expect(find.textContaining('0 ký tự (tối thiểu 20)'), findsOneWidget);
    });
  });

  testWidgets('PostCard với canVote=false không phát sự kiện bầu chọn', (tester) async {
    final votes = <int>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PostCard(
          blog: BlogItem.fromJson(_blog(1, 'Bài của tôi')),
          author: null,
          myVote: null,
          score: 3,
          commentCount: 0,
          onOpen: () {},
          onVote: votes.add,
          canVote: false,
        ),
      ),
    ));
    await tester.tap(find.byIcon(LucideIcons.thumbsUp));
    await tester.tap(find.byIcon(LucideIcons.thumbsDown));
    expect(votes, isEmpty);
  });
}
