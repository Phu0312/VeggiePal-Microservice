import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/header_actions.dart';
import '../../auth/data/auth_models.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/login_screen.dart';
import '../../blog/data/blog_models.dart';
import '../../blog/data/blog_repository.dart';
import '../../blog/presentation/comments_section.dart';
import '../../profile/data/profile_models.dart';
import '../../profile/data/profile_repository.dart';
import '../data/home_models.dart';
import '../data/home_repository.dart';

/// Chi tiết bài viết: hiển thị ngay dữ liệu tóm tắt, sau đó nạp nội dung đầy đủ (GET /blogs/{id}),
/// tác giả (GET /users/batch), phiếu bầu của tôi (GET /blogs/me/votes), bài liên quan
/// (GET /blogs/{id}/related) và bình luận. Bầu chọn: POST/DELETE /blogs/{id}/vote.
class BlogDetailScreen extends StatefulWidget {
  final BlogItem summary;

  /// Báo cho màn hình gọi (bảng tin) khi phiếu bầu thay đổi để thẻ bài viết cập nhật theo.
  final void Function(int? myVote, int? score)? onVoteChanged;
  const BlogDetailScreen({super.key, required this.summary, this.onVoteChanged});

  @override
  State<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  BlogItem? _detail;
  PublicUser? _author;
  int? _myVote;
  int? _score;
  List<BlogItem> _related = [];
  bool _loading = true;
  bool _voting = false;

  int get _id => widget.summary.id;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final home = context.read<HomeRepository>();
    try {
      final d = await home.blogDetail(widget.summary);
      if (!mounted) return;
      setState(() {
        _detail = d;
        _score = d.voteScore;
      });
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, errorMessage(e), title: 'Không tải được bài viết');
        setState(() => _loading = false);
      }
      return;
    }
    if (mounted) setState(() => _loading = false);
    _loadExtras();
  }

  /// Phần phụ (tác giả, phiếu bầu, bài liên quan): lỗi hiện popup nhưng không chặn việc đọc bài.
  Future<void> _loadExtras() async {
    final blogRepo = context.read<BlogRepository>();
    final profileRepo = context.read<ProfileRepository>();
    final loggedIn = context.read<AuthController>().isLoggedIn;
    final authorId = _detail?.authorId;
    try {
      final r = await Future.wait<Object?>([
        blogRepo.related(_id),
        if (authorId != null) profileRepo.publicUsers([authorId]) else Future.value(<PublicUser>[]),
        if (loggedIn) blogRepo.myVotes([_id]) else Future.value(<VoteInfo>[]),
      ]);
      if (!mounted) return;
      final users = r[1] as List<PublicUser>;
      final votes = r[2] as List<VoteInfo>;
      setState(() {
        _related = r[0] as List<BlogItem>;
        _author = users.isEmpty ? null : users.first;
        _myVote = votes.isEmpty ? null : votes.first.myVote;
      });
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e), title: 'Không tải được thông tin bài viết');
    }
  }

  Future<void> _vote(int value) async {
    if (!context.read<AuthController>().isLoggedIn) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    setState(() => _voting = true);
    try {
      // Bầu lại đúng giá trị đang chọn thì BE tự rút phiếu.
      final v = await context.read<BlogRepository>().vote(_id, value);
      if (mounted) {
        setState(() {
          _myVote = v.myVote;
          _score = v.voteScore ?? _score;
        });
        widget.onVoteChanged?.call(_myVote, _score);
      }
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e), title: 'Không bầu chọn được');
    } finally {
      if (mounted) setState(() => _voting = false);
    }
  }

  Widget _voteButton(IconData icon, int value, String tooltip) {
    final active = _myVote == value;
    return IconButton.filledTonal(
      tooltip: tooltip,
      isSelected: active,
      style: IconButton.styleFrom(
        backgroundColor: active ? context.cs.primary : null,
        foregroundColor: active ? context.cs.onPrimary : null,
      ),
      onPressed: _voting ? null : () => _vote(value),
      icon: Icon(icon, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = _detail ?? widget.summary;
    final authorUser = AuthUser(
        id: b.authorId ?? 0,
        email: '',
        fullName: _author?.fullName ?? '',
        role: UserRole.user,
        avatarUrl: _author?.avatarUrl);

    return Scaffold(
      appBar: AppBar(title: const Text('Bài viết')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Tác giả, ngày đăng, danh mục, lượt xem
          Row(children: [
            UserAvatar(authorUser, radius: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text((_author?.fullName ?? '').isEmpty ? 'Tác giả' : _author!.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                Text(
                    [
                      if (b.publishedAt != null) fmtDate(b.publishedAt!),
                      if (b.categoryName != null) b.categoryName!,
                      '${b.viewCount} lượt xem',
                    ].join('  •  '),
                    style: TextStyle(fontSize: 12, color: context.textMuted)),
              ]),
            ),
          ]),
          const SizedBox(height: 14),
          // 2. Tiêu đề
          Text(b.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          // 3. Ảnh bìa
          if ((b.thumbnailUrl ?? '').isNotEmpty) ...[
            const SizedBox(height: 14),
            VegImage(b.thumbnailUrl, height: 220, width: double.infinity),
          ],
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_detail == null)
            Center(
                child: OutlinedButton.icon(
                    onPressed: _load,
                    icon: const Icon(LucideIcons.refreshCw),
                    label: const Text('Thử lại')))
          else ...[
            // 4. Nội dung
            Text(b.content ?? '', style: const TextStyle(height: 1.5, fontSize: 16)),
            const SizedBox(height: 16),
            // 5. Thích / không thích
            Row(children: [
              _voteButton(LucideIcons.thumbsUp, 1, 'Thích'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('${_score ?? b.voteScore}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              _voteButton(LucideIcons.thumbsDown, -1, 'Không thích'),
            ]),
            const Divider(height: 40),
            CommentsSection(blogId: _id, initiallyOpen: true),
            if (_related.isNotEmpty) ...[
              const Divider(height: 40),
              Text('Bài viết liên quan',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              for (final r in _related)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => BlogDetailScreen(summary: r))),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(children: [
                        VegImage(r.thumbnailUrl, width: 64, height: 64),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(r.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text('${r.viewCount} lượt xem  •  ${r.voteScore} điểm',
                                style: TextStyle(fontSize: 12, color: context.textMuted)),
                          ]),
                        ),
                        Icon(LucideIcons.chevronRight, size: 20, color: context.textMuted),
                      ]),
                    ),
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }
}
