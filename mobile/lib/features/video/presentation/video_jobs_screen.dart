import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/paged_list_view.dart';
import '../data/video_models.dart';
import '../data/video_repository.dart';
import 'extraction_view.dart';

/// Bóc tách công thức từ video bằng AI: gửi một tệp video (POST /ai/videos/process, ≤ 100MB, ≤ 30 phút, trừ 1 lượt
/// của gói) và xem lịch sử (GET /ai/videos). Lượt đang xử lý tự cập nhật mỗi 4 giây; kết quả được lưu 30 ngày.
class VideoJobsScreen extends StatefulWidget {
  const VideoJobsScreen({super.key});

  @override
  State<VideoJobsScreen> createState() => _VideoJobsScreenState();
}

class _VideoJobsScreenState extends State<VideoJobsScreen> {
  static const _poll = Duration(seconds: 4);

  final _list = GlobalKey<PagedListViewState<VideoJob>>();
  Timer? _timer;
  double? _progress; // 0..1 khi đang tải tệp lên
  bool _uploading = false;
  bool _polling = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_poll, (_) => _refreshProcessing());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Hỏi lại backend về các lượt đang xử lý; lỗi mạng tạm thời được bỏ qua.
  Future<void> _refreshProcessing() async {
    final state = _list.currentState;
    if (_polling || !mounted || state == null) return;
    final pending = state.items.where((j) => j.processing).toList();
    if (pending.isEmpty) return;
    _polling = true;
    try {
      final repo = context.read<VideoRepository>();
      for (final j in pending) {
        final fresh = await repo.job(j.id);
        if (!mounted) return;
        if (!fresh.processing) {
          _list.currentState?.replaceWhere((x) => x.id == j.id, fresh);
          if (fresh.status == 'COMPLETED' && fresh.extraction != null) {
            showSnack(context, 'AI đã bóc tách xong "${fresh.extraction!.title}"');
          }
        }
      }
    } catch (_) {
    } finally {
      _polling = false;
    }
  }

  Future<void> _pick() async {
    final XFile? f;
    try {
      f = await ImagePicker().pickVideo(source: ImageSource.gallery);
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e), title: 'Không chọn được video');
      return;
    }
    if (f == null || !mounted) return;
    final bytes = await f.length();
    if (!mounted) return;
    final invalid = validateJobFile(bytes: bytes);
    if (invalid != null) {
      showErrorDialog(context, invalid, title: 'Video không hợp lệ');
      return;
    }
    final name = f.name.isNotEmpty ? f.name : 'video.mp4';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bóc tách công thức'),
        content: Text('Gửi "$name" (${formatFileSize(bytes)}) cho AI bóc tách? '
            'Việc này trừ 1 lượt bóc tách video của gói hiện tại. Video cần có lời hướng dẫn nấu ăn '
            'và dài tối đa ${VideoLimits.jobMaxMinutes} phút.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Gửi')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _upload(f.path, name);
  }

  Future<void> _upload(String path, String name) async {
    setState(() {
      _uploading = true;
      _progress = 0;
    });
    try {
      await context.read<VideoRepository>().processFile(path, name, onSendProgress: (sent, total) {
        if (mounted && total > 0) setState(() => _progress = sent / total);
      });
      if (!mounted) return;
      showSnack(context, 'Đã gửi video, AI đang bóc tách. Bạn có thể rời màn hình này.');
      _list.currentState?.reload();
    } catch (e) {
      if (mounted) {
        showErrorDialog(
            context,
            e is ApiException && e.code == 6003
                ? 'Bạn đã hết lượt bóc tách video của gói hiện tại (gói FREE chưa có lượt). Hãy nâng cấp gói để dùng tính năng này.'
                : errorMessage(e),
            title: 'Không gửi được video');
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
          _progress = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<VideoRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Bóc tách công thức từ video')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(LucideIcons.sparkles, color: context.cs.primary),
                  const SizedBox(width: 8),
                  const Expanded(
                      child: Text('AI nghe lời trong video nấu ăn rồi liệt kê nguyên liệu và các bước làm.',
                          style: TextStyle(fontWeight: FontWeight.w600))),
                ]),
                const SizedBox(height: 6),
                Text('Tệp video tối đa 100MB, dài tối đa ${VideoLimits.jobMaxMinutes} phút.',
                    style: TextStyle(fontSize: 12.5, color: context.textMuted)),
                const SizedBox(height: 12),
                if (_uploading) ...[
                  LinearProgressIndicator(value: _progress),
                  const SizedBox(height: 6),
                  Text('Đang tải lên ${((_progress ?? 0) * 100).round()}%...',
                      style: TextStyle(fontSize: 12.5, color: context.textMuted)),
                ] else
                  FilledButton.icon(
                    onPressed: _pick,
                    icon: const Icon(LucideIcons.upload),
                    label: const Text('Chọn video để bóc tách'),
                  ),
              ]),
            ),
          ),
        ),
        Expanded(
          child: PagedListView<VideoJob>(
            key: _list,
            errorTitle: 'Không tải được lịch sử bóc tách',
            load: (page) => repo.jobs(page: page),
            emptyText: 'Bạn chưa bóc tách video nào.',
            itemBuilder: (context, j) => _JobCard(j, onView: () => showJobResultSheet(context, j)),
          ),
        ),
      ]),
    );
  }
}

class _JobCard extends StatelessWidget {
  final VideoJob job;
  final VoidCallback onView;
  const _JobCard(this.job, {required this.onView});

  @override
  Widget build(BuildContext context) {
    final color = switch (job.status) {
      'COMPLETED' => Colors.green,
      'FAILED' => context.cs.error,
      _ => Colors.orange,
    };
    final title = job.status == 'COMPLETED' && job.extraction != null
        ? job.extraction!.title
        : job.sourceLabel;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            StatusPill(jobStatusLabel(job.status), color),
            const SizedBox(width: 8),
            if (job.processing)
              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
            const Spacer(),
            if (job.createdAt != null)
              Text(timeAgo(job.createdAt!), style: TextStyle(fontSize: 12, color: context.textMuted)),
          ]),
          const SizedBox(height: 8),
          Text(title,
              maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
          if (job.status == 'COMPLETED' && job.extraction != null)
            Text('Từ ${job.sourceVideoId != null ? job.sourceLabel.toLowerCase() : 'video “${job.filename}”'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, color: context.textMuted)),
          if (job.processing)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('AI đang bóc tách, bạn có thể rời màn hình này.',
                  style: TextStyle(fontSize: 12.5, color: context.textMuted)),
            ),
          if (job.status == 'FAILED')
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(describeJobError(job.error),
                  style: TextStyle(fontSize: 12.5, color: context.cs.error)),
            ),
          if (job.resultExpired)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Kết quả đã hết hạn lưu (hệ thống chỉ giữ 30 ngày).',
                  style: TextStyle(fontSize: 12.5, color: context.textMuted)),
            ),
          if (job.status == 'COMPLETED' && job.extraction != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: onView, child: const Text('Xem kết quả')),
            ),
        ]),
      ),
    );
  }
}
