import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/moderation.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/paged_list_view.dart';
import '../data/video_models.dart';
import '../data/video_repository.dart';
import 'video_form_screen.dart';
import 'video_widgets.dart';

/// Video của tôi (GET /videos/me?status=): xem mọi trạng thái, đăng video, sửa, gửi duyệt bản nháp và xoá.
class MyVideosScreen extends StatefulWidget {
  const MyVideosScreen({super.key});

  @override
  State<MyVideosScreen> createState() => _MyVideosScreenState();
}

class _MyVideosScreenState extends State<MyVideosScreen> {
  static const _filters = {
    null: 'Tất cả',
    'DRAFT': 'Nháp',
    'PENDING': 'Chờ duyệt',
    'PUBLISHED': 'Đã đăng',
    'REJECTED': 'Bị từ chối',
    'BANNED': 'Bị gỡ',
  };

  final _list = GlobalKey<PagedListViewState<Video>>();
  String? _status;

  void _reload() => _list.currentState?.reload();

  Future<void> _create() async {
    final saved = await Navigator.of(context)
        .push<Video>(MaterialPageRoute(builder: (_) => const VideoFormScreen()));
    if (saved != null && mounted) _reload();
  }

  Future<void> _edit(Video v) async {
    final saved = await Navigator.of(context)
        .push<Video>(MaterialPageRoute(builder: (_) => VideoFormScreen(existing: v)));
    if (saved != null && mounted) _reload();
  }

  Future<void> _submit(Video v) async {
    try {
      final r = await context.read<VideoRepository>().submit(v.id);
      if (!mounted) return;
      final out = videoOutcome(r);
      if (out.needsDialog) {
        await showInfoDialog(context, out.title, out.message);
      } else {
        showSnack(context, out.message);
      }
      _reload();
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e), title: 'Không gửi duyệt được');
    }
  }

  Future<void> _delete(Video v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá video'),
        content: Text('Bạn có chắc muốn xoá "${v.title}"? Thao tác này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xoá')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<VideoRepository>().delete(v.id);
      if (!mounted) return;
      showSnack(context, 'Đã xoá video');
      _reload();
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e), title: 'Không xoá được video');
    }
  }

  void _showActions(Video v) {
    Widget tile(IconData icon, String label, VoidCallback onTap, {Color? color}) => ListTile(
          leading: Icon(icon, color: color),
          title: Text(label, style: TextStyle(color: color)),
          onTap: () {
            Navigator.pop(context);
            onTap();
          },
        );

    final reason = moderationReasonVi(v.moderationReason ?? '');
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            title: Text(v.title,
                maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(videoStatusLabel(v.status) + (reason.isEmpty ? '' : '\nLý do: $reason')),
            isThreeLine: reason.isNotEmpty,
          ),
          tile(LucideIcons.play, 'Xem video', () => openVideo(context, v)),
          if (v.status != 'BANNED') tile(LucideIcons.pencil, 'Sửa video', () => _edit(v)),
          if (v.status == 'DRAFT') tile(LucideIcons.send, 'Gửi duyệt', () => _submit(v)),
          tile(LucideIcons.trash2, 'Xoá video', () => _delete(v), color: context.cs.error),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<VideoRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Video của tôi')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'my-videos-add',
        onPressed: _create,
        icon: const Icon(LucideIcons.video),
        label: const Text('Đăng video'),
      ),
      body: Column(children: [
        FilterRow(children: [
          FilterDropdown<String?>(
            options: _filters,
            selected: _status,
            onChanged: (v) {
              setState(() => _status = v);
              _reload();
            },
          ),
        ]),
        Expanded(
          child: PagedListView<Video>(
            key: _list,
            errorTitle: 'Không tải được video của bạn',
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
            spacing: 12,
            load: (page) => repo.mine(status: _status, page: page),
            emptyText: _status == null ? 'Bạn chưa đăng video nào.' : 'Chưa có video nào ở mục này.',
            itemBuilder: (context, v) => VideoCard(video: v, showStatus: true, onTap: () => _showActions(v)),
          ),
        ),
      ]),
    );
  }
}
