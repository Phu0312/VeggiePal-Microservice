
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/login_screen.dart';
import '../../profile/data/profile_models.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/presentation/favorite_button.dart';
import '../data/video_models.dart';
import '../data/video_repository.dart';
import 'video_nutrition_widgets.dart';
import 'video_player_view.dart';

/// Xem video (GET /videos/{id}, mỗi lần mở tính một lượt xem): trình phát, tác giả, mô tả và thẻ
/// "Công thức AI" bóc tách từ lời trong video. [initial] hiện ngay trong lúc tải; video chưa đăng
/// (xem từ "Video của tôi") dùng luôn [initial] vì backend chỉ trả video đã đăng.
class VideoWatchScreen extends StatefulWidget {
  final int videoId;
  final Video? initial;
  const VideoWatchScreen({super.key, required this.videoId, this.initial});

  @override
  State<VideoWatchScreen> createState() => _VideoWatchScreenState();
}

class _VideoWatchScreenState extends State<VideoWatchScreen> {
  Video? _video;
  PublicUser? _author;
  bool _loading = true;
  bool _failed = false;
  int? _myVote;
  int? _score; // điểm sau khi bầu; null = dùng điểm trong dữ liệu video
  bool _voting = false;

  @override
  void initState() {
    super.initState();
    _video = widget.initial;
    _load();
  }

  Future<void> _load() async {
    final initial = widget.initial;
    if (initial != null && initial.status != 'PUBLISHED') {
      setState(() => _loading = false);
      _loadAuthor(initial.authorId);
      return;
    }
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final v = await context.read<VideoRepository>().detail(widget.videoId);
      if (!mounted) return;
      setState(() => _video = v);
      _loadAuthor(v.authorId);
      _loadMyVote(v.id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _failed = _video == null);
      showErrorDialog(context, errorMessage(e), title: 'Không tải được video');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Phiếu bầu của tôi chỉ là thông tin phụ, lỗi được bỏ qua.
  Future<void> _loadMyVote(int id) async {
    if (!context.read<AuthController>().isLoggedIn) return;
    try {
      final votes = await context.read<VideoRepository>().myVotes([id]);
      if (mounted && votes.isNotEmpty) setState(() => _myVote = votes.first.myVote);
    } catch (_) {}
  }

  Future<void> _vote(int value) async {
    final v = _video;
    if (v == null) return;
    if (!context.read<AuthController>().isLoggedIn) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    setState(() => _voting = true);
    try {
      // Bầu lại đúng giá trị đang chọn thì BE tự rút phiếu.
      final r = await context.read<VideoRepository>().vote(v.id, value);
      if (mounted) {
        setState(() {
          _myVote = r.myVote;
          _score = r.voteScore;
        });
      }
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e), title: 'Không bầu chọn được');
    } finally {
      if (mounted) setState(() => _voting = false);
    }
  }

  bool get _canEditNutrition {
    final v = _video;
    final auth = context.read<AuthController>();
    return v != null && auth.isLoggedIn && (v.authorId == auth.user?.id || auth.isAdmin);
  }

  Future<void> _editNutrition() async {
    final v = _video!;
    final saved = await showEditVideoNutrition(context, v.id, v.nutrition);
    if (saved != null && mounted) {
      setState(() => _video = v.withNutrition(saved));
      showSnack(context, 'Đã cập nhật dinh dưỡng');
    }
  }

  Widget _voteButton(IconData icon, int value, String label) {
    final selected = _myVote == value;
    return IconButton.filledTonal(
      tooltip: label,
      onPressed: _voting ? null : () => _vote(value),
      isSelected: selected,
      icon: Icon(icon),
      selectedIcon: Icon(icon, color: context.cs.primary),
    );
  }

  /// Tên tác giả chỉ là thông tin phụ, lỗi được bỏ qua.
  Future<void> _loadAuthor(int authorId) async {
    if (authorId <= 0) return;
    try {
      final users = await context.read<ProfileRepository>().publicUsers([authorId]);
      if (mounted && users.isNotEmpty) setState(() => _author = users.first);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final v = _video;
    return Scaffold(
      appBar: AppBar(
        title: Text(v?.title ?? 'Video', maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (v != null)
            FavoriteButton(type: FavoriteType.video, targetId: v.id, title: v.title, imageUrl: v.thumbnailUrl),
        ],
      ),
      body: v == null
          ? (_loading
              ? const Center(child: CircularProgressIndicator())
              : RetryView(message: _failed ? 'Không tải được video.' : 'Video không tồn tại.', onRetry: _load))
          : ListView(children: [
              VideoPlayerView(v),
              if (_loading) const LinearProgressIndicator(minHeight: 2),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(v.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(
                    [
                      if (_author != null) _author!.fullName,
                      if (v.categoryName != null) v.categoryName!,
                      '${v.viewCount} lượt xem',
                      if ((v.publishedAt ?? v.createdAt) != null)
                        timeAgo((v.publishedAt ?? v.createdAt)!.toLocal()),
                    ].join('  •  '),
                    style: TextStyle(fontSize: 13, color: context.textMuted),
                  ),
                  if (v.status != 'PUBLISHED') ...[
                    const SizedBox(height: 8),
                    Text('Video chưa được đăng (${videoStatusLabel(v.status).toLowerCase()}), chỉ mình bạn xem được.',
                        style: const TextStyle(fontSize: 13, color: Colors.deepOrange)),
                  ],
                  if ((v.description ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(v.description!.trim(), style: const TextStyle(height: 1.4)),
                  ],
                  if (v.status == 'PUBLISHED') ...[
                    const SizedBox(height: 12),
                    Row(children: [
                      _voteButton(LucideIcons.thumbsUp, 1, 'Thích'),
                      const SizedBox(width: 8),
                      Text('${_score ?? v.voteScore}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(width: 8),
                      _voteButton(LucideIcons.thumbsDown, -1, 'Không thích'),
                    ]),
                    const SizedBox(height: 12),
                    VideoNutritionCard(nutrition: v.nutrition, onEdit: _canEditNutrition ? _editNutrition : null),
                    const SizedBox(height: 16),
                  ],
                ]),
              ),
            ]),
    );
  }
}
