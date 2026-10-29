import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/paged_list_view.dart';
import '../../home/data/home_models.dart';
import '../data/video_models.dart';
import '../data/video_repository.dart';
import 'video_watch_screen.dart';

Color videoStatusColor(BuildContext context, String status) => switch (status) {
      'PUBLISHED' => Colors.green,
      'PENDING' || 'DRAFT' => Colors.orange,
      'REJECTED' || 'BANNED' => context.cs.error,
      _ => context.textMuted,
    };

/// Thẻ video: ảnh đại diện 16:9 có nút phát và nhãn nguồn (YouTube / MP4), tiêu đề, danh mục, lượt xem.
class VideoCard extends StatelessWidget {
  final Video video;
  final VoidCallback onTap;
  final bool showStatus;
  const VideoCard({super.key, required this.video, required this.onTap, this.showStatus = false});

  @override
  Widget build(BuildContext context) {
    final when = video.publishedAt ?? video.createdAt;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(alignment: Alignment.center, children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: VegImage(video.thumbnailUrl, width: double.infinity, height: double.infinity),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
              child: const Icon(LucideIcons.play, color: Colors.white, size: 26),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration:
                    BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(6)),
                child: Text(video.isYoutube ? 'YouTube' : 'MP4',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (showStatus) ...[
                StatusPill(videoStatusLabel(video.status), videoStatusColor(context, video.status)),
                const SizedBox(height: 6),
              ],
              Text(video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
              const SizedBox(height: 4),
              Text(
                [
                  if (video.categoryName != null) video.categoryName!,
                  '${video.viewCount} lượt xem',
                  if (when != null) timeAgo(when.toLocal()),
                ].join('  •  '),
                style: TextStyle(fontSize: 12.5, color: context.textMuted),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Mở màn xem video; trả về khi người xem quay lại.
Future<void> openVideo(BuildContext context, Video v) => Navigator.of(context)
    .push(MaterialPageRoute(builder: (_) => VideoWatchScreen(videoId: v.id, initial: v)));

/// Bảng tin video ở Trang chủ (GET /videos): lọc theo danh mục, phân trang, kéo để tải lại.
class VideoFeed extends StatefulWidget {
  final List<CategoryItem> categories;
  const VideoFeed({super.key, required this.categories});

  @override
  State<VideoFeed> createState() => VideoFeedState();
}

class VideoFeedState extends State<VideoFeed> {
  final _list = GlobalKey<PagedListViewState<Video>>();
  int? _categoryId;

  /// Tải lại (vd sau khi người dùng vừa đăng video).
  void reload() => _list.currentState?.reload();

  @override
  Widget build(BuildContext context) {
    final repo = context.read<VideoRepository>();
    return Column(children: [
      SizedBox(
        height: 48,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          itemCount: widget.categories.length + 1,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final id = i == 0 ? null : widget.categories[i - 1].id;
            return ChoiceChip(
              label: Text(i == 0 ? 'Tất cả' : widget.categories[i - 1].name),
              selected: _categoryId == id,
              onSelected: (_) {
                setState(() => _categoryId = id);
                _list.currentState?.reload();
              },
            );
          },
        ),
      ),
      Expanded(
        child: PagedListView<Video>(
          key: _list,
          errorTitle: 'Không tải được video',
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
          spacing: 12,
          load: (page) => repo.published(categoryId: _categoryId, page: page),
          emptyText: 'Chưa có video nào được đăng.',
          itemBuilder: (context, v) => VideoCard(
            video: v,
            onTap: () async {
              await openVideo(context, v);
              if (mounted) reload(); // lượt xem vừa tăng
            },
          ),
        ),
      ),
    ]);
  }
}
