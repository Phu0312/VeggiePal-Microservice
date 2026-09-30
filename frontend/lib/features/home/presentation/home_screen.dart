import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/home_models.dart';
import '../data/home_repository.dart';
import 'blog_detail_screen.dart';
import 'create_content_sheet.dart';

/// TAB 1 - Trang chủ.
/// Widget tree: Scaffold(FAB cho thành viên)
///   └─ RefreshIndicator └─ ListView
///        ├─ VegSearchBar
///        ├─ Danh mục (ListView ngang của ChoiceChip)
///        ├─ Section "Video hướng dẫn" (carousel ngang)
///        └─ Section "Bài viết & Blog" (danh sách dọc)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  List<CategoryItem> _categories = [];
  List<VideoItem> _videos = [];
  List<BlogItem> _blogs = [];
  int? _categoryId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Tải danh mục + video + blog song song. Repository đã có Mock Fallback nên
  /// không bao giờ ném lỗi kết nối; chỉ bắt lỗi nghiệp vụ còn lại.
  Future<void> _load() async {
    setState(() => _loading = true);
    final repo = context.read<HomeRepository>();
    final kw = _search.text.trim();
    try {
      final r = await Future.wait([
        repo.categories(),
        repo.videos(keyword: kw, categoryId: _categoryId),
        repo.blogs(keyword: kw, categoryId: _categoryId),
      ]);
      if (!mounted) return;
      setState(() {
        _categories = r[0] as List<CategoryItem>;
        _videos = r[1] as List<VideoItem>;
        _blogs = r[2] as List<BlogItem>;
      });
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Chỉ thành viên (User/Admin) mới thấy nút đăng nội dung; khách chỉ xem/tìm kiếm.
    final canPost = context.watch<AuthController>().isLoggedIn;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: canPost
          ? FloatingActionButton.extended(
              onPressed: () async {
                final posted = await showCreateContentSheet(context, _categories);
                if (posted == true) _load();
              },
              icon: const Icon(Icons.add),
              label: const Text('Đăng video/bài viết'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 88),
          children: [
            VegSearchBar(
              controller: _search,
              hint: 'Tìm món ăn, công thức, video nấu chay...',
              onSubmitted: (_) => _load(),
            ),
            _buildCategories(),
            if (_loading)
              const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()))
            else ...[
              const SectionHeader('Video hướng dẫn nấu ăn'),
              _buildVideos(),
              const SectionHeader('Bài viết & Blog chia sẻ'),
              _buildBlogs(),
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

  Widget _buildVideos() {
    if (_videos.isEmpty) return const _Empty('Chưa có video phù hợp');
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _videos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _VideoCard(_videos[i]),
      ),
    );
  }

  Widget _buildBlogs() {
    if (_blogs.isEmpty) return const _Empty('Chưa có bài viết phù hợp');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (final b in _blogs)
            Padding(
                padding: const EdgeInsets.only(bottom: 12), child: _BlogCard(b)),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
            child: Text(text, style: const TextStyle(color: AppColors.textMuted))),
      );
}

/// Thẻ video: thumbnail + badge thời lượng + lượt xem.
class _VideoCard extends StatelessWidget {
  final VideoItem v;
  const _VideoCard(this.v);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showModalBottomSheet(
            context: context,
            builder: (_) => Padding(
              padding: const EdgeInsets.all(20),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(v.title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('${v.categoryName ?? ''} • ${v.durationText} • ${v.viewCount} lượt xem'),
                const SizedBox(height: 12),
                Text(v.videoUrl ?? 'Video sẽ phát tại đây (trình phát chưa tích hợp).',
                    style: const TextStyle(color: AppColors.textMuted)),
              ]),
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(children: [
              VegImage(v.thumbnailUrl, width: 220, height: 120, radius: BorderRadius.zero),
              const Positioned.fill(
                  child: Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 40))),
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                  child: Text(v.durationText,
                      style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(v.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('${v.viewCount} lượt xem',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _BlogCard extends StatelessWidget {
  final BlogItem b;
  const _BlogCard(this.b);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => BlogDetailScreen(summary: b))),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            VegImage(b.thumbnailUrl, width: 88, height: 88),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (b.categoryName != null)
                  Text(b.categoryName!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                Text(b.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.visibility_outlined, size: 14, color: AppColors.textMuted),
                  Text(' ${b.viewCount}   ',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const Icon(Icons.favorite_border, size: 14, color: AppColors.textMuted),
                  Text(' ${b.voteScore}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
