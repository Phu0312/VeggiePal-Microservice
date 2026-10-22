import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../home/data/home_models.dart';
import '../../home/data/home_repository.dart';
import '../../home/presentation/blog_detail_screen.dart';
import '../../notifications/notification_controller.dart';
import '../data/blog_models.dart';
import '../data/blog_repository.dart';
import 'blog_editor_screen.dart';

/// Bài viết của tôi (GET /blogs/me?status=): xem mọi trạng thái, viết bài, sửa, gửi duyệt bản nháp,
/// đổi ảnh bìa và xoá.
class MyBlogsScreen extends StatefulWidget {
  const MyBlogsScreen({super.key});

  @override
  State<MyBlogsScreen> createState() => _MyBlogsScreenState();
}

class _MyBlogsScreenState extends State<MyBlogsScreen> {
  static const _filters = {
    null: 'Tất cả',
    'DRAFT': 'Nháp',
    'PENDING': 'Chờ duyệt',
    'PUBLISHED': 'Đã đăng',
    'REJECTED': 'Bị từ chối',
    'BANNED': 'Bị gỡ',
  };

  List<BlogItem> _blogs = [];
  String? _status;
  bool _loading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final r = await context.read<HomeRepository>().myBlogs(status: _status);
      if (mounted) setState(() => _blogs = r);
    } catch (e) {
      if (mounted) {
        setState(() => _loadFailed = true);
        showErrorDialog(context, errorMessage(e), title: 'Không tải được bài viết của bạn');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Sau mỗi thay đổi, tải lại danh sách và đồng bộ chuông thông báo (trạng thái bài viết đổi).
  Future<void> _afterChange() async {
    context.read<NotificationController>().refresh();
    await _load();
  }

  Future<void> _openEditor([BlogItem? blog]) async {
    final changed = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => BlogEditorScreen(existing: blog)));
    if (changed == true) _afterChange();
  }

  Future<void> _submit(BlogItem b) async {
    try {
      final r = await context.read<BlogRepository>().submitBlog(b.id);
      if (!mounted) return;
      final out = blogOutcome(r);
      if (out.needsDialog) {
        await showInfoDialog(context, out.title, out.message);
      } else {
        showSnack(context, out.message);
      }
      _afterChange();
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e), title: 'Không gửi duyệt được');
    }
  }

  Future<void> _changeThumbnail(BlogItem b) async {
    final repo = context.read<BlogRepository>();
    try {
      final f = await ImagePicker()
          .pickImage(source: ImageSource.gallery, maxWidth: 1600, maxHeight: 1600, imageQuality: 85);
      if (f == null) return;
      await repo.uploadThumbnail(b.id, await f.readAsBytes());
      if (!mounted) return;
      showSnack(context, 'Đã cập nhật ảnh bìa');
      _load();
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e), title: 'Không đổi được ảnh bìa');
    }
  }

  Future<void> _delete(BlogItem b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá bài viết'),
        content: Text('Bạn có chắc muốn xoá "${b.title}"? Thao tác này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xoá')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<BlogRepository>().deleteBlog(b.id);
      if (!mounted) return;
      showSnack(context, 'Đã xoá bài viết');
      _load();
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e), title: 'Không xoá được bài viết');
    }
  }

  void _showActions(BlogItem b) {
    final status = b.status;
    Widget tile(IconData icon, String label, VoidCallback onTap, {Color? color}) => ListTile(
          leading: Icon(icon, color: color),
          title: Text(label, style: TextStyle(color: color)),
          onTap: () {
            Navigator.pop(context);
            onTap();
          },
        );

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            title: Text(b.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(blogStatusLabel(status)),
          ),
          if (status == 'PUBLISHED')
            tile(LucideIcons.eye, 'Xem bài viết', () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => BlogDetailScreen(summary: b)))),
          if (status != 'BANNED') tile(LucideIcons.pencil, 'Sửa bài viết', () => _openEditor(b)),
          if (status == 'DRAFT') tile(LucideIcons.send, 'Gửi duyệt', () => _submit(b)),
          if (status != 'BANNED') tile(LucideIcons.image, 'Đổi ảnh bìa', () => _changeThumbnail(b)),
          tile(LucideIcons.trash2, 'Xoá bài viết', () => _delete(b), color: context.cs.error),
        ]),
      ),
    );
  }

  Color _statusColor(String? s) => switch (s) {
        'PUBLISHED' => Colors.green,
        'PENDING' => Colors.orange,
        'REJECTED' || 'BANNED' => context.cs.error,
        _ => context.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bài viết của tôi')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'my-blogs-add',
        onPressed: () => _openEditor(),
        icon: const Icon(LucideIcons.penLine),
        label: const Text('Viết bài'),
      ),
      body: Column(children: [
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              for (final e in _filters.entries) ...[
                ChoiceChip(
                  label: Text(e.value),
                  selected: _status == e.key,
                  onSelected: (_) {
                    setState(() => _status = e.key);
                    _load();
                  },
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _loadFailed
                  ? RetryView(onRetry: _load)
                  : _blogs.isEmpty
                      ? Center(
                          child: Text('Chưa có bài viết nào ở mục này.',
                              style: TextStyle(color: context.textMuted)))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                            itemCount: _blogs.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final b = _blogs[i];
                              return Card(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _showActions(b),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Row(children: [
                                      VegImage(b.thumbnailUrl, width: 72, height: 72),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _statusColor(b.status).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(blogStatusLabel(b.status),
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: _statusColor(b.status))),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(b.title,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontWeight: FontWeight.w700)),
                                          const SizedBox(height: 2),
                                          Text(
                                              [
                                                if (b.categoryName != null) b.categoryName!,
                                                if (b.createdAt != null) fmtDate(b.createdAt!),
                                                '${b.viewCount} xem • ${b.voteScore} điểm',
                                              ].join('  •  '),
                                              style: TextStyle(fontSize: 12, color: context.textMuted)),
                                        ]),
                                      ),
                                      Icon(LucideIcons.ellipsisVertical, size: 20, color: context.textMuted),
                                    ]),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
        ),
      ]),
    );
  }
}
