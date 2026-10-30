import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/login_screen.dart';
import '../../profile/data/profile_models.dart';
import '../../profile/data/profile_repository.dart';
import '../data/community_models.dart';
import '../data/community_repository.dart';

/// Một dòng tác giả (bảng xếp hạng): hạng, ảnh, tên, số liệu và nút theo dõi.
class AuthorTile extends StatelessWidget {
  final int? rank;
  final CommunityAuthor author;
  final PublicUser? user;
  final bool isSelf;
  final bool busy;
  final String subtitle;
  final VoidCallback onFollow;
  const AuthorTile({
    super.key,
    this.rank,
    required this.author,
    required this.user,
    required this.isSelf,
    required this.busy,
    required this.subtitle,
    required this.onFollow,
  });

  @override
  Widget build(BuildContext context) {
    final name = (user?.fullName ?? '').isEmpty ? 'Thành viên #${author.authorId}' : user!.fullName;
    final avatar = user?.avatarUrl;
    return Card(
      child: ListTile(
        leading: Row(mainAxisSize: MainAxisSize.min, children: [
          if (rank != null)
            SizedBox(
                width: 22,
                child: Text('$rank',
                    style: TextStyle(fontWeight: FontWeight.w800, color: rank! <= 3 ? context.cs.primary : context.textMuted))),
          CircleAvatar(
            foregroundImage: (avatar == null || avatar.isEmpty) ? null : NetworkImage(avatar),
            onForegroundImageError: (avatar == null || avatar.isEmpty) ? null : (_, _) {},
            child: Text(name.characters.first.toUpperCase()),
          ),
        ]),
        title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('$subtitle\n${author.followers} người theo dõi'),
        isThreeLine: true,
        trailing: isSelf
            ? null
            : busy
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : author.following
                    ? OutlinedButton(onPressed: onFollow, child: const Text('Đang theo dõi'))
                    : FilledButton(onPressed: onFollow, child: const Text('Theo dõi')),
      ),
    );
  }
}

/// Dải "Kênh video đề xuất" ở đầu tab Video: người đăng video xếp theo số video và lượt xem (GET /videos/channels), cuộn
/// ngang, có nút theo dõi. Không bao giờ đề xuất chính người đang xem. Tự ẩn khi chưa có kênh nào hoặc tải lỗi (chỉ là phần
/// phụ nên không bật popup). BE chỉ trả mã tác giả nên tên và ảnh lấy qua `/users/batch`.
class VideoChannelsStrip extends StatefulWidget {
  const VideoChannelsStrip({super.key});

  @override
  State<VideoChannelsStrip> createState() => _VideoChannelsStripState();
}

class _VideoChannelsStripState extends State<VideoChannelsStrip> {
  List<CommunityAuthor> _channels = const [];
  final _names = <int, PublicUser>{};
  final _following = <int>{}; // mã tác giả đang gọi API theo dõi

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Lấy dư một kênh để vẫn đủ 10 sau khi bỏ chính mình (xem build).
      final all = await context.read<CommunityRepository>().videoChannels(limit: 11);
      if (!mounted) return;
      setState(() => _channels = all);
      final users = await context.read<ProfileRepository>().publicUsers([for (final c in all) c.authorId]);
      if (mounted) setState(() => _names.addAll({for (final u in users) u.id: u}));
    } catch (_) {}
  }

  Future<void> _toggleFollow(CommunityAuthor a) async {
    if (!context.read<AuthController>().isLoggedIn) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    setState(() => _following.add(a.authorId));
    try {
      final s = await context.read<CommunityRepository>().setFollow(a.authorId, !a.following);
      if (!mounted) return;
      setState(() {
        _channels = [
          for (final x in _channels)
            x.authorId == s.authorId ? x.withFollow(following: s.following, followers: s.followers) : x
        ];
      });
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e), title: 'Không cập nhật được theo dõi');
    } finally {
      if (mounted) setState(() => _following.remove(a.authorId));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lọc ở đây (không ở _load) để đăng nhập / đăng xuất cũng loại đúng người xem hiện tại.
    final selfId = context.watch<AuthController>().user?.id;
    final channels = _channels.where((c) => c.authorId != selfId).take(10).toList();
    if (channels.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader('Kênh video đề xuất'),
      SizedBox(
        height: 168,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: channels.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (_, i) => _ChannelCard(
            author: channels[i],
            user: _names[channels[i].authorId],
            busy: _following.contains(channels[i].authorId),
            onFollow: () => _toggleFollow(channels[i]),
          ),
        ),
      ),
      const SizedBox(height: 8),
    ]);
  }
}

class _ChannelCard extends StatelessWidget {
  final CommunityAuthor author;
  final PublicUser? user;
  final bool busy;
  final VoidCallback onFollow;
  const _ChannelCard({required this.author, required this.user, required this.busy, required this.onFollow});

  @override
  Widget build(BuildContext context) {
    final name = (user?.fullName ?? '').isEmpty ? 'Thành viên #${author.authorId}' : user!.fullName;
    final avatar = user?.avatarUrl;
    return SizedBox(
      width: 150,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(children: [
            CircleAvatar(
              radius: 22,
              foregroundImage: (avatar == null || avatar.isEmpty) ? null : NetworkImage(avatar),
              onForegroundImageError: (avatar == null || avatar.isEmpty) ? null : (_, _) {},
              child: Text(name.characters.first.toUpperCase()),
            ),
            const SizedBox(height: 6),
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('${author.videos} video • ${formatCount(author.views)} lượt xem',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: context.textMuted)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: busy
                  ? const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                  : author.following
                      ? OutlinedButton(onPressed: onFollow, child: const Text('Đang theo dõi', maxLines: 1))
                      : FilledButton(onPressed: onFollow, child: const Text('Theo dõi')),
            ),
          ]),
        ),
      ),
    );
  }
}
