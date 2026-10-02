import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/header_actions.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/login_screen.dart';
import '../../blog/presentation/my_blogs_screen.dart';
import 'allergies_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'health_history_screen.dart';

/// TAB 5 - Hồ sơ. Khách: lời mời đăng nhập. Thành viên: thẻ tài khoản + các mục quản lý cá nhân.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.user;

    if (user == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(LucideIcons.circleUser, size: 72, color: context.textMuted),
            const SizedBox(height: 16),
            Text('Bạn chưa đăng nhập',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Đăng nhập để lưu thực đơn, đăng bài viết và nhận thông báo.',
                textAlign: TextAlign.center, style: TextStyle(color: context.textMuted)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _open(context, const LoginScreen()),
              icon: const Icon(LucideIcons.logIn),
              label: const Text('Đăng nhập / Đăng ký'),
            ),
          ]),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _open(context, const EditProfileScreen()),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                UserAvatar(user, radius: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(user.fullName.isEmpty ? user.email : user.fullName,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(user.email, style: TextStyle(color: context.textMuted)),
                  ]),
                ),
                Icon(LucideIcons.pencil, size: 20, color: context.textMuted),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(children: [
            _MenuTile(LucideIcons.userPen, 'Thông tin cá nhân', 'Họ tên, số điện thoại, ngày sinh, ảnh đại diện',
                () => _open(context, const EditProfileScreen())),
            const Divider(height: 1),
            _MenuTile(LucideIcons.fileText, 'Bài viết của tôi', 'Viết bài, sửa, gửi duyệt, xem trạng thái',
                () => _open(context, const MyBlogsScreen())),
            const Divider(height: 1),
            _MenuTile(LucideIcons.keyRound, 'Đổi mật khẩu', null,
                () => _open(context, const ChangePasswordScreen())),
            const Divider(height: 1),
            _MenuTile(LucideIcons.shieldAlert, 'Dị ứng thực phẩm', 'Nguyên liệu cần tránh trong thực đơn',
                () => _open(context, const AllergiesScreen())),
            const Divider(height: 1),
            _MenuTile(LucideIcons.activity, 'Lịch sử sức khỏe', 'Chiều cao, cân nặng, BMI',
                () => _open(context, const HealthHistoryScreen())),
          ]),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => confirmLogout(context),
          icon: const Icon(LucideIcons.logOut),
          label: const Text('Đăng xuất'),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  const _MenuTile(this.icon, this.title, this.subtitle, this.onTap);

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: context.cs.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: Icon(LucideIcons.chevronRight, size: 20, color: context.textMuted),
        onTap: onTap,
      );
}
