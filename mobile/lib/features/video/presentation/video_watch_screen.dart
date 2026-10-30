import 'dart:async';

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
import '../../payment/presentation/upgrade_dialog.dart';
import '../data/video_models.dart';
import '../data/video_repository.dart';
import 'extraction_view.dart';
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
    } catch (e) {
      if (!mounted) return;
      setState(() => _failed = _video == null);
      showErrorDialog(context, errorMessage(e), title: 'Không tải được video');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
      appBar: AppBar(title: Text(v?.title ?? 'Video', maxLines: 1, overflow: TextOverflow.ellipsis)),
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
                    const SizedBox(height: 16),
                    _AiRecipeCard(video: v),
                  ],
                ]),
              ),
            ]),
    );
  }
}

/// Thẻ "Công thức AI" của video đã đăng: lấy công thức đã bóc tách (GET /ai/videos/by-video/{id}, dùng chung cho mọi
/// người nên xem không tốn lượt) hoặc mời bóc tách (POST /ai/videos/process-existing, trừ 1 lượt của gói).
/// Chỉ video tải lên (.mp4) bóc tách được; đang xử lý thì hỏi lại backend mỗi 4 giây.
class _AiRecipeCard extends StatefulWidget {
  final Video video;
  const _AiRecipeCard({required this.video});

  @override
  State<_AiRecipeCard> createState() => _AiRecipeCardState();
}

class _AiRecipeCardState extends State<_AiRecipeCard> {
  static const _poll = Duration(seconds: 4);

  VideoRecipe? _recipe; // null = đang kiểm tra
  String? _error;
  bool _starting = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.video.isYoutube) {
      _recipe = const VideoRecipe(RecipeState.unsupported);
    } else {
      _check();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    try {
      final r = await context.read<VideoRepository>().recipeOf(widget.video.id);
      if (!mounted) return;
      setState(() {
        _recipe = r;
        _error = null;
      });
      _schedulePoll(r);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = errorMessage(e);
        _recipe ??= const VideoRecipe(RecipeState.none);
      });
    }
  }

  void _schedulePoll(VideoRecipe r) {
    _timer?.cancel();
    if (r.state == RecipeState.processing) _timer = Timer(_poll, _check);
  }

  Future<void> _run() async {
    if (!context.read<AuthController>().isLoggedIn) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      final job = await context.read<VideoRepository>().processExisting(widget.video.id);
      if (!mounted) return;
      final r = VideoRecipe.fromJob(job);
      setState(() => _recipe = r);
      _schedulePoll(r);
    } catch (e) {
      if (mounted) {
        if (e is ApiException && e.code == 6003) {
          showUpgradeDialog(
              context,
              'Bạn đã hết lượt bóc tách video của gói hiện tại (gói FREE chưa có lượt). '
              'Hãy nâng cấp gói để dùng tính năng này.',
              title: 'Hết lượt bóc tách video');
        } else {
          setState(() => _error = errorMessage(e));
        }
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.watch<AuthController>().isLoggedIn;
    final r = _recipe;
    final Widget body;
    if (r == null) {
      body = const Row(children: [
        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
        SizedBox(width: 10),
        Text('Đang kiểm tra công thức AI...'),
      ]);
    } else {
      body = switch (r.state) {
        RecipeState.ready => ExtractionView(r.extraction!),
        RecipeState.processing => const Row(children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 10),
            Expanded(child: Text('AI đang bóc tách công thức, bạn có thể ở lại đây hoặc quay lại sau.')),
          ]),
        RecipeState.failed => Text(
            'Lần bóc tách trước của video này không thành công. Bạn có thể thử lại.',
            style: TextStyle(color: context.textMuted)),
        RecipeState.unsupported => Text(
            'Chưa hỗ trợ bóc tách video YouTube. Tính năng này hiện chỉ dùng cho video tải lên trực tiếp (.mp4).',
            style: TextStyle(color: context.textMuted)),
        RecipeState.none => Text(
            loggedIn
                ? 'Video này chưa có công thức AI. Bấm nút bên dưới để AI nghe lời trong video và liệt kê nguyên liệu, các bước làm (trừ 1 lượt bóc tách của gói).'
                : 'Video này chưa có công thức AI. Đăng nhập để yêu cầu AI bóc tách nguyên liệu và các bước nấu ăn.',
            style: TextStyle(color: context.textMuted)),
      };
    }

    final canRun = r != null && (r.state == RecipeState.none || r.state == RecipeState.failed);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(LucideIcons.sparkles, color: context.cs.primary),
            const SizedBox(width: 8),
            const Expanded(
                child: Text('Công thức AI từ video',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
          ]),
          const SizedBox(height: 12),
          body,
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: TextStyle(color: context.cs.error, fontSize: 13)),
          ],
          if (canRun) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _starting ? null : _run,
              icon: _starting
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(LucideIcons.sparkles),
              label: Text(loggedIn
                  ? (r.state == RecipeState.failed ? 'Bóc tách lại' : 'Bóc tách công thức bằng AI')
                  : 'Đăng nhập để bóc tách'),
            ),
          ],
          if (r?.state == RecipeState.ready) ...[
            const SizedBox(height: 8),
            Text('Kết quả do AI tạo từ lời trong video, bạn nên đối chiếu lại trước khi dùng.',
                style: TextStyle(fontSize: 12, color: context.textMuted)),
          ],
        ]),
      ),
    );
  }
}
