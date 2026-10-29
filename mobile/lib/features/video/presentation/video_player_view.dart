import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../core/constants/app_colors.dart';
import '../data/video_models.dart';

/// Trình phát video: YouTube phát bằng khung nhúng, video tải lên (.mp4) phát bằng video_player.
class VideoPlayerView extends StatelessWidget {
  final Video video;
  const VideoPlayerView(this.video, {super.key});

  @override
  Widget build(BuildContext context) {
    if (video.isYoutube) {
      final id = video.youtubeId;
      return id == null ? const _PlayerMessage('Link YouTube của video không hợp lệ.') : _YoutubePlayer(id);
    }
    if (video.videoUrl.isEmpty) return const _PlayerMessage('Video chưa có nguồn phát.');
    return _Mp4Player(video.videoUrl);
  }
}

class _PlayerMessage extends StatelessWidget {
  final String text;
  const _PlayerMessage(this.text);

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: Colors.black,
          child: Center(
              child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
          )),
        ),
      );
}

class _YoutubePlayer extends StatefulWidget {
  final String videoId;
  const _YoutubePlayer(this.videoId);

  @override
  State<_YoutubePlayer> createState() => _YoutubePlayerState();
}

class _YoutubePlayerState extends State<_YoutubePlayer> {
  late final YoutubePlayerController _controller = YoutubePlayerController.fromVideoId(
    videoId: widget.videoId,
    autoPlay: false,
    params: const YoutubePlayerParams(showFullscreenButton: true),
  );

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => YoutubePlayer(controller: _controller, aspectRatio: 16 / 9);
}

class _Mp4Player extends StatefulWidget {
  final String url;
  const _Mp4Player(this.url);

  @override
  State<_Mp4Player> createState() => _Mp4PlayerState();
}

class _Mp4PlayerState extends State<_Mp4Player> {
  late final VideoPlayerController _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTick);
    _controller.initialize().then((_) {
      if (mounted) setState(() => _ready = true);
    }).catchError((Object _) {
      if (mounted) setState(() => _failed = true);
    });
  }

  void _onTick() {
    if (!mounted) return;
    if (_controller.value.hasError && !_failed) {
      setState(() => _failed = true);
    } else {
      setState(() {}); // cập nhật nút phát / tiến độ
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    final v = _controller.value;
    if (v.isPlaying) {
      _controller.pause();
    } else {
      // Phát xong thì phát lại từ đầu.
      if (v.position >= v.duration) _controller.seekTo(Duration.zero);
      _controller.play();
    }
  }

  static String _fmt(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    if (_failed) return const _PlayerMessage('Không phát được video. Kiểm tra mạng rồi mở lại.');
    if (!_ready) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(color: Colors.black, child: Center(child: CircularProgressIndicator())),
      );
    }
    final v = _controller.value;
    return AspectRatio(
      aspectRatio: v.aspectRatio > 0 ? v.aspectRatio : 16 / 9,
      child: Stack(alignment: Alignment.center, children: [
        const Positioned.fill(child: ColoredBox(color: Colors.black)),
        VideoPlayer(_controller),
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggle,
            child: AnimatedOpacity(
              opacity: v.isPlaying ? 0 : 1,
              duration: const Duration(milliseconds: 200),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: Icon(v.isPlaying ? LucideIcons.pause : LucideIcons.play,
                      color: Colors.white, size: 32),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 8,
          right: 8,
          bottom: 4,
          child: Row(children: [
            Text(_fmt(v.position), style: const TextStyle(color: Colors.white, fontSize: 12)),
            const SizedBox(width: 8),
            Expanded(
              child: VideoProgressIndicator(_controller,
                  allowScrubbing: true,
                  colors: VideoProgressColors(
                      playedColor: AppColors.accent,
                      bufferedColor: Colors.white38,
                      backgroundColor: Colors.white24)),
            ),
            const SizedBox(width: 8),
            Text(_fmt(v.duration), style: const TextStyle(color: Colors.white, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }
}
