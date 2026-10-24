import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../features/auth/data/auth_models.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/notifications/notification_controller.dart';
import '../constants/app_colors.dart';
import '../theme/theme_controller.dart';

/// Nút đổi chế độ sáng/tối (icon mặt trăng ở chế độ sáng, mặt trời ở chế độ tối).
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    return IconButton(
      tooltip: theme.isDark ? 'Chuyển sang giao diện sáng' : 'Chuyển sang giao diện tối',
      onPressed: theme.toggle,
      icon: Icon(theme.isDark ? LucideIcons.sun : LucideIcons.moon),
    );
  }
}

/// Avatar người dùng: ảnh nếu có, ngược lại là chữ cái đầu (khách: icon người).
class UserAvatar extends StatelessWidget {
  final AuthUser? user;
  final double radius;
  const UserAvatar(this.user, {super.key, this.radius = 18});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final url = user?.avatarUrl;
    final fallback = user == null
        ? Icon(LucideIcons.user, size: radius, color: cs.onPrimaryContainer)
        : Text(user!.initial,
            style: TextStyle(
                fontSize: radius * 0.9,
                fontWeight: FontWeight.w700,
                color: cs.onPrimaryContainer));
    return CircleAvatar(
      radius: radius,
      backgroundColor: cs.primaryContainer,
      child: (url == null || url.isEmpty)
          ? fallback
          : ClipOval(
              child: Image.network(url,
                  width: radius * 2,
                  height: radius * 2,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Center(child: fallback)),
            ),
    );
  }
}

/// Avatar ở header của app người dùng: khách bấm vào để đăng nhập, thành viên bấm để mở tab Hồ sơ.
class HeaderAvatarButton extends StatelessWidget {
  final VoidCallback onOpenProfile;
  const HeaderAvatarButton({super.key, required this.onOpenProfile});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 12),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: auth.isLoggedIn
            ? onOpenProfile
            : () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const LoginScreen())),
        child: UserAvatar(auth.user),
      ),
    );
  }
}

/// Hỏi xác nhận rồi đăng xuất, sau đó báo "Đã đăng xuất". Dùng chung cho app người dùng và app admin.
Future<void> confirmLogout(BuildContext context) async {
  final auth = context.read<AuthController>();
  // Lấy messenger của MaterialApp trước khi đăng xuất vì màn hình hiện tại có thể bị thay (admin -> app khách).
  final messenger = ScaffoldMessenger.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Đăng xuất'),
      content: const Text('Bạn có chắc muốn đăng xuất khỏi tài khoản này?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Đăng xuất')),
      ],
    ),
  );
  if (ok != true) return;
  auth.logout();
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(content: Text('Đã đăng xuất thành công')));
}

/// Cụm tài khoản ở header của app quản trị: chữ "Admin", avatar và nút đăng xuất.
class AdminAccountBar extends StatelessWidget {
  const AdminAccountBar({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text('Admin', style: TextStyle(fontWeight: FontWeight.w700, color: context.cs.onSurface)),
      const SizedBox(width: 8),
      UserAvatar(auth.user),
      IconButton(
        tooltip: 'Đăng xuất',
        onPressed: () => confirmLogout(context),
        icon: const Icon(LucideIcons.logOut, size: 22),
      ),
      const SizedBox(width: 4),
    ]);
  }
}

/// Chuông thông báo: huy hiệu số chưa đọc, bấm mở popup danh sách thông báo.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationController>().unread;
    final isLoggedIn = context.watch<AuthController>().isLoggedIn;
    return IconButton(
      tooltip: 'Thông báo',
      onPressed: () => showNotificationsDialog(context, isLoggedIn: isLoggedIn),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 9 ? '9+' : '$unread'),
        child: const Icon(LucideIcons.bell),
      ),
    );
  }
}

Future<void> showNotificationsDialog(BuildContext context, {required bool isLoggedIn}) async {
  final ctrl = context.read<NotificationController>();
  await showDialog<void>(
    context: context,
    builder: (_) => isLoggedIn ? const _NotificationsDialog() : const _GuestNotificationsDialog(),
  );
  // Đóng popup = đã xem hết thông báo.
  if (isLoggedIn) ctrl.markAllRead();
}

class _GuestNotificationsDialog extends StatelessWidget {
  const _GuestNotificationsDialog();

  @override
  Widget build(BuildContext context) => AlertDialog(
        icon: Icon(LucideIcons.bell, color: context.cs.primary, size: 32),
        title: const Text('Thông báo'),
        content: const Text('Đăng nhập để nhận thông báo về bài viết của bạn.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            child: const Text('Đăng nhập'),
          ),
        ],
      );
}

class _NotificationsDialog extends StatefulWidget {
  const _NotificationsDialog();

  @override
  State<_NotificationsDialog> createState() => _NotificationsDialogState();
}

class _NotificationsDialogState extends State<_NotificationsDialog> {
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final ctrl = context.read<NotificationController>();
    final err = await ctrl.refresh();
    if (!mounted) return;
    setState(() {
      _error = err;
      _loading = false;
    });
  }

  static String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Vừa xong';
    if (d.inHours < 1) return '${d.inMinutes} phút trước';
    if (d.inDays < 1) return '${d.inHours} giờ trước';
    return '${d.inDays} ngày trước';
  }

  @override
  Widget build(BuildContext context) {
    final items = context.watch<NotificationController>().items;
    final cs = context.cs;
    return AlertDialog(
      title: Row(children: [
        const Expanded(child: Text('Thông báo')),
        IconButton(
            tooltip: 'Làm mới',
            onPressed: _loading ? null : _refresh,
            icon: const Icon(LucideIcons.refreshCw, size: 20)),
      ]),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_error!, style: TextStyle(color: cs.error)),
            ),
          if (items.isEmpty && !_loading && _error == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text('Chưa có thông báo nào', style: TextStyle(color: context.textMuted)),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final n = items[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                        n.read ? LucideIcons.bell : LucideIcons.bellRing,
                        color: n.read ? context.textMuted : cs.primary),
                    title: Text(n.body,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: n.read ? FontWeight.w400 : FontWeight.w700)),
                    subtitle: Text(_ago(n.createdAt)),
                  );
                },
              ),
            ),
        ]),
      ),
      actions: [
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
      ],
    );
  }
}
