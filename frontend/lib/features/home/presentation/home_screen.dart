import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/login_screen.dart';
import '../../blog/data/blog_models.dart';
import '../../blog/data/blog_repository.dart';
import '../../profile/data/profile_models.dart';
import '../../profile/data/profile_repository.dart';
import '../data/home_models.dart';
import '../data/home_repository.dart';
import 'blog_detail_screen.dart';
import 'create_content_sheet.dart';
import 'post_card.dart';

/// TAB 1 - Trang chủ: bảng tin bài viết xếp theo chiều dọc (mới nhất trước), cuộn xuống tự tải thêm.
/// Widget tree: Scaffold(FAB cho thành viên)
///   └─ RefreshIndicator └─ ListView
///        ├─ VegSearchBar
///        ├─ Danh mục (ListView ngang của ChoiceChip)
///        └─ Danh sách PostCard (tác giả, tiêu đề + ảnh bìa, thích / không thích / bình luận)
/// Tác giả lấy bằng GET /users/batch, phiếu bầu của tôi bằng GET /blogs/me/votes, số bình luận bằng
/// GET /comments (chỉ gọi cho các bài mới tải của mỗi trang).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();

  List<CategoryItem> _categories = [];
  List<BlogItem> _blogs = [];
  int? _categoryId;
  int _page = 0;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  bool _loadFailed = false;

  final _authors = <int, PublicUser>{};
  final _myVotes = <int, int?>{};
  final _scores = <int, int>{};
  final _commentCounts = <int, int>{};
  int? _votesFor; // userId mà _myVotes đang tương ứng

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.hasClients && _scroll.position.extentAfter < 400) _loadMore();
    });
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Tải lại từ trang đầu: danh mục + trang bài viết đầu tiên.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    final repo = context.read<HomeRepository>();
    final kw = _search.text.trim();
    try {
      final r = await Future.wait<Object>([
        repo.categories(),
        repo.blogsPage(keyword: kw, categoryId: _categoryId, page: 0),
      ]);
      if (!mounted) return;
      final page = r[1] as PageData<BlogItem>;
      setState(() {
        _categories = r[0] as List<CategoryItem>;
        _blogs = page.items;
        _page = page.page;
        _hasMore = page.hasMore;
        for (final b in page.items) {
          _scores[b.id] = b.voteScore;
        }
      });
      await _enrich(page.items);
    } catch (e) {
      if (mounted) {
        setState(() => _loadFailed = true);
        showErrorDialog(context, errorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final p = await context.read<HomeRepository>().blogsPage(
          keyword: _search.text.trim(), categoryId: _categoryId, page: _page + 1);
      if (!mounted) return;
      setState(() {
        _blogs = [..._blogs, ...p.items];
        _page = p.page;
        _hasMore = p.hasMore;
        for (final b in p.items) {
          _scores[b.id] = b.voteScore;
        }
      });
      await _enrich(p.items);
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e), title: 'Không tải thêm được bài viết');
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  /// Bổ sung thông tin cho các bài vừa tải: tên + avatar tác giả (1 request cho cả trang),
  /// phiếu bầu của tôi (1 request, nếu đã đăng nhập) và số bình luận từng bài.
  Future<void> _enrich(List<BlogItem> items) async {
    if (items.isEmpty) return;
    final profileRepo = context.read<ProfileRepository>();
    final blogRepo = context.read<BlogRepository>();
    final auth = context.read<AuthController>();
    final ids = items.map((b) => b.id).toList();
    final unknownAuthors = {
      for (final b in items)
        if (b.authorId != null && !_authors.containsKey(b.authorId)) b.authorId!,
    }.toList();
    try {
      final users = await profileRepo.publicUsers(unknownAuthors);
      final votes = auth.isLoggedIn ? await blogRepo.myVotes(ids) : <VoteInfo>[];
      if (!mounted) return;
      setState(() {
        for (final u in users) {
          _authors[u.id] = u;
        }
        for (final v in votes) {
          _myVotes[v.blogId] = v.myVote;
        }
        _votesFor = auth.user?.id;
      });
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e), title: 'Không tải được thông tin bài viết');
    }
    // Số bình luận: lỗi từng bài thì bỏ qua (thẻ hiện chữ "Bình luận" không kèm số).
    await Future.wait(ids.map((id) async {
      try {
        final n = await blogRepo.commentCount(id);
        if (mounted) setState(() => _commentCounts[id] = n);
      } catch (_) {}
    }));
  }

  /// Đăng nhập/đăng xuất thì nạp lại (hoặc xoá) phiếu bầu của tôi.
  void _syncVotes(int? userId) {
    if (_blogs.isEmpty || _votesFor == userId) return;
    _votesFor = userId;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (userId == null) {
        setState(_myVotes.clear);
        return;
      }
      try {
        final votes = await context.read<BlogRepository>().myVotes(_blogs.map((b) => b.id).toList());
        if (!mounted) return;
        setState(() {
          _myVotes
            ..clear()
            ..addEntries(votes.map((v) => MapEntry(v.blogId, v.myVote)));
        });
      } catch (e) {
        if (mounted) showErrorDialog(context, errorMessage(e), title: 'Không tải được phiếu bầu');
      }
    });
  }

  Future<void> _vote(BlogItem b, int value) async {
    if (!context.read<AuthController>().isLoggedIn) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    try {
      // Bầu lại đúng giá trị đang chọn thì BE tự rút phiếu.
      final v = await context.read<BlogRepository>().vote(b.id, value);
      if (!mounted) return;
      setState(() {
        _myVotes[b.id] = v.myVote;
        if (v.voteScore != null) _scores[b.id] = v.voteScore!;
      });
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e), title: 'Không bầu chọn được');
    }
  }

  Future<void> _open(BlogItem b) async {
    final blogRepo = context.read<BlogRepository>();
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlogDetailScreen(
        summary: b,
        onVoteChanged: (myVote, score) {
          if (!mounted) return;
          setState(() {
            _myVotes[b.id] = myVote;
            if (score != null) _scores[b.id] = score;
          });
        },
      ),
    ));
    // Quay lại: cập nhật số bình luận (người dùng có thể vừa bình luận hoặc xoá).
    try {
      final n = await blogRepo.commentCount(b.id);
      if (mounted) setState(() => _commentCounts[b.id] = n);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    _syncVotes(auth.user?.id);
    // Chỉ thành viên (User/Admin) mới thấy nút đăng nội dung; khách chỉ xem/tìm kiếm.
    final canPost = auth.isLoggedIn;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: canPost
          ? FloatingActionButton.extended(
              onPressed: () async {
                final posted = await showCreateContentSheet(context, _categories);
                if (posted == true) _load();
              },
              icon: const Icon(Icons.add),
              label: const Text('Đăng bài'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            VegSearchBar(
              controller: _search,
              hint: 'Tìm bài viết, công thức, mẹo nấu chay...',
              onSubmitted: (_) => _load(),
            ),
            _buildCategories(),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                  padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()))
            else if (_loadFailed)
              RetryView(onRetry: _load)
            else if (_blogs.isEmpty)
              Padding(
                padding: const EdgeInsets.all(48),
                child: Center(
                    child: Text('Chưa có bài viết phù hợp', style: TextStyle(color: context.textMuted))),
              )
            else ...[
              for (final b in _blogs)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: PostCard(
                    blog: b,
                    author: _authors[b.authorId],
                    myVote: _myVotes[b.id],
                    score: _scores[b.id] ?? b.voteScore,
                    commentCount: _commentCounts[b.id],
                    onOpen: () => _open(b),
                    onVote: (v) => _vote(b, v),
                  ),
                ),
              if (_loadingMore)
                const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
              else if (!_hasMore)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                      child: Text('Bạn đã xem hết bài viết', style: TextStyle(color: context.textMuted))),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategories() => SizedBox(
        height: 48,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          itemCount: _categories.length + 1,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final id = i == 0 ? null : _categories[i - 1].id;
            return ChoiceChip(
              label: Text(i == 0 ? 'Tất cả' : _categories[i - 1].name),
              selected: _categoryId == id,
              onSelected: (_) {
                _categoryId = id;
                _load();
              },
            );
          },
        ),
      );
}
