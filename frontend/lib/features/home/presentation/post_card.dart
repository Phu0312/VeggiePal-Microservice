import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/header_actions.dart';
import '../../auth/data/auth_models.dart';
import '../../profile/data/profile_models.dart';
import '../data/home_models.dart';

/// Một bài viết trên bảng tin Trang chủ (kiểu mạng xã hội):
/// avatar + tên tác giả + giờ đăng ở trên, tiêu đề và ảnh bìa ở giữa, hàng thích / không thích /
/// bình luận ở dưới. Danh sách bài viết của BE không trả nội dung nên thẻ chỉ có tiêu đề + ảnh bìa,
/// bấm vào để đọc đầy đủ.
class PostCard extends StatelessWidget {
  final BlogItem blog;
  final PublicUser? author;
  final int? myVote; // 1, -1 hoặc null
  final int score;
  final int? commentCount; // null = chưa tải được
  final VoidCallback onOpen;
  final void Function(int value) onVote;

  const PostCard({
    super.key,
    required this.blog,
    required this.author,
    required this.myVote,
    required this.score,
    required this.commentCount,
    required this.onOpen,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final authorUser = AuthUser(
        id: blog.authorId ?? 0,
        email: '',
        fullName: author?.fullName ?? '',
        role: UserRole.user,
        avatarUrl: author?.avatarUrl);
    final name = (author?.fullName ?? '').isEmpty ? 'Người dùng' : author!.fullName;
    final when = blog.publishedAt ?? blog.createdAt;
    final hasImage = (blog.thumbnailUrl ?? '').isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Tác giả: avatar, tên, giờ đăng.
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          child: Row(children: [
            UserAvatar(authorUser, radius: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                Row(children: [
                  if (when != null)
                    Text(timeAgo(when), style: TextStyle(fontSize: 12, color: context.textMuted)),
                  if (blog.categoryName != null) ...[
                    Text('  •  ', style: TextStyle(fontSize: 12, color: context.textMuted)),
                    Flexible(
                      child: Text(blog.categoryName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: context.cs.primary)),
                    ),
                  ],
                ]),
              ]),
            ),
          ]),
        ),
        // Nội dung: bấm để mở bài.
        InkWell(
          onTap: onOpen,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: EdgeInsets.fromLTRB(14, 4, 14, hasImage ? 10 : 12),
              child: Text(blog.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800, height: 1.3)),
            ),
            if (hasImage)
              VegImage(blog.thumbnailUrl, width: double.infinity, height: 220, radius: BorderRadius.zero),
          ]),
        ),
        Divider(height: 1, color: Theme.of(context).dividerColor),
        // Thích / không thích / bình luận.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Row(children: [
            // [👍] điểm [👎]: BE chỉ trả một con số (thích trừ không thích) nên đặt ở giữa hai icon.
            _Action(
              icon: LucideIcons.thumbsUp,
              label: null,
              active: myVote == 1,
              tooltip: 'Thích',
              onTap: () => onVote(1),
            ),
            Text('$score',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: myVote == null ? null : context.cs.primary)),
            _Action(
              icon: LucideIcons.thumbsDown,
              label: null,
              active: myVote == -1,
              tooltip: 'Không thích',
              onTap: () => onVote(-1),
            ),
            const Spacer(),
            _Action(
              icon: LucideIcons.messageCircle,
              label: commentCount == null ? 'Bình luận' : '$commentCount',
              active: false,
              tooltip: 'Bình luận',
              onTap: onOpen,
            ),
          ]),
        ),
      ]),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String? label; // null = chỉ hiện icon
  final bool active;
  final String tooltip;
  final VoidCallback onTap;
  const _Action(
      {required this.icon,
      required this.label,
      required this.active,
      required this.tooltip,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? context.cs.primary : context.textMuted;
    final style = TextButton.styleFrom(
        foregroundColor: color, padding: const EdgeInsets.symmetric(horizontal: 12));
    return Tooltip(
      message: tooltip,
      child: label == null
          ? TextButton(onPressed: onTap, style: style, child: Icon(icon, size: 20, color: color))
          : TextButton.icon(
              onPressed: onTap,
              style: style,
              icon: Icon(icon, size: 20, color: color),
              label: Text(label!,
                  style: TextStyle(
                      fontSize: 14, fontWeight: active ? FontWeight.w800 : FontWeight.w500, color: color)),
            ),
    );
  }
}
