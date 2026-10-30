import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/header_actions.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/presentation/verify_email_screen.dart';
import '../../menu_planner/data/health_sync.dart';
import '../../menu_planner/data/menu_models.dart';
import '../../nutrition/presentation/diary_screen.dart';
import '../../blog/presentation/my_blogs_screen.dart';
import '../../payment/data/subscription_controller.dart';
import '../../payment/data/payment_models.dart';
import '../../payment/presentation/payment_history_screen.dart';
import '../../payment/presentation/pricing_screen.dart';
import '../../recipe/presentation/my_recipes_screen.dart';
import '../../video/presentation/my_videos_screen.dart';
import '../../video/presentation/video_jobs_screen.dart';
import '../data/profile_overview.dart';
import 'allergies_screen.dart';
import 'badges_screen.dart';
import 'favorites_screen.dart';
import 'bmi_tracker_card.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'health_history_screen.dart';

/// TAB 5 - Hồ sơ. Khách: lời mời đăng nhập. Thành viên:
///   ├─ thẻ tài khoản (ảnh, tên, gói thành viên) + số liệu: bài viết, công thức, video, BMI mới nhất
///   ├─ nhắc bổ sung ngày sinh / giới tính / mức vận động nếu thiếu (backend cần để tính calo của thực đơn)
///   ├─ biểu đồ theo dõi BMI / cân nặng
///   └─ các mục quản lý cá nhân
/// Số liệu do [ProfileOverview] tải (kéo để làm mới; tự tải lại khi chỉ số sức khỏe đổi hoặc khi quay về từ màn con).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int? _lastHealthVersion;

  /// "Gói Plus, đến 28/11/2026" hoặc gợi ý nâng cấp khi đang dùng gói FREE.
  String _planSubtitle(BuildContext context) {
    final s = context.watch<SubscriptionController>().subscription;
    if (s == null) return 'Xem và nâng cấp gói';
    if (!s.isPaid) return '${planName(s.planCode)} • nâng cấp để có thêm lượt sử dụng';
    final until = s.expiresAt;
    return until == null ? planName(s.planCode) : '${planName(s.planCode)} • đến ${fmtDate(until)}';
  }

  /// Mở một màn con; khi quay về thì tải lại số liệu (người dùng có thể vừa thêm bài viết, sửa hồ sơ...).
  Future<void> _open(BuildContext context, Widget page) async {
    final overview = context.read<ProfileOverview>();
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    overview.refresh();
  }

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

    final overview = context.watch<ProfileOverview>();
    // Tải lần đầu, và tải lại khi chỉ số sức khỏe bị đổi ở nơi khác (Lịch sử sức khỏe).
    final healthVersion = context.watch<HealthSync>().version;
    if (_lastHealthVersion != healthVersion) {
      final first = _lastHealthVersion == null;
      _lastHealthVersion = healthVersion;
      if (!first) WidgetsBinding.instance.addPostFrameCallback((_) => overview.refresh());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => overview.ensureLoaded());

    final sub = context.watch<SubscriptionController>().subscription;
    final issue = overview.calorieIssue;
    final latest = overview.latestHealth;
    String count(int? n) => n?.toString() ?? '-';

    return RefreshIndicator(
      onRefresh: overview.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _open(context, const EditProfileScreen()),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  Row(children: [
                    UserAvatar(user, radius: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(user.fullName.isEmpty ? user.email : user.fullName,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(user.email, style: TextStyle(color: context.textMuted)),
                        const SizedBox(height: 6),
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _open(context, const PricingScreen()),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(LucideIcons.crown, size: 15, color: AppColors.star),
                            const SizedBox(width: 4),
                            Text(
                                sub == null
                                    ? 'Xem gói thành viên'
                                    : 'Gói ${sub.planCode}'
                                        '${sub.expiresAt == null ? '' : ' • đến ${fmtDate(sub.expiresAt!)}'}',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                          ]),
                        ),
                      ]),
                    ),
                    Icon(LucideIcons.pencil, size: 20, color: context.textMuted),
                  ]),
                  const Divider(height: 28),
                  Row(children: [
                    _Stat(count(overview.blogs), 'Bài viết'),
                    _Stat(count(overview.recipes), 'Công thức'),
                    _Stat(count(overview.videos), 'Video'),
                    _Stat(latest == null ? '-' : latest.bmi.toStringAsFixed(1),
                        latest == null ? 'BMI' : 'BMI • ${HealthInfo(latest.heightCm, latest.weightKg, latest.bmi).category}'),
                  ]),
                ]),
              ),
            ),
          ),
          if (overview.error != null && overview.loaded)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(children: [
                Icon(LucideIcons.wifiOff, size: 16, color: context.cs.error),
                const SizedBox(width: 8),
                Expanded(
                    child: Text('Chưa tải đủ số liệu: ${overview.error}',
                        style: TextStyle(fontSize: 12.5, color: context.cs.error))),
                TextButton(onPressed: overview.refresh, child: const Text('Thử lại')),
              ]),
            ),
          if (issue != null && issue.hasIssue) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.deepOrange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                const Icon(LucideIcons.triangleAlert, size: 18, color: Colors.deepOrange),
                const SizedBox(width: 10),
                Expanded(child: Text(issue.message, style: const TextStyle(fontSize: 13))),
                if (!issue.underage)
                  TextButton(
                      onPressed: () => _open(context, EditProfileScreen(highlightFields: issue.missing.toSet())),
                      child: const Text('Bổ sung')),
              ]),
            ),
          ],
          if (!user.emailVerified) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.deepOrange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                const Icon(LucideIcons.mailWarning, size: 18, color: Colors.deepOrange),
                const SizedBox(width: 10),
                const Expanded(
                    child: Text('Email chưa được xác minh. Xác minh để bảo vệ tài khoản và nhận lại mật khẩu khi quên.',
                        style: TextStyle(fontSize: 13))),
                TextButton(
                    onPressed: () => _open(context, const VerifyEmailScreen(sendOnOpen: true)),
                    child: const Text('Xác minh')),
              ]),
            ),
          ],
          const SizedBox(height: 12),
          BmiTrackerCard(
            recordsNewestFirst: overview.health,
            onOpenHistory: () => _open(context, const HealthHistoryScreen()),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(children: [
              _MenuTile(LucideIcons.userPen, 'Thông tin cá nhân',
                  'Họ tên, số điện thoại, ngày sinh, giới tính, mức vận động, ảnh đại diện',
                  () => _open(context, const EditProfileScreen())),
              const Divider(height: 1),
              _MenuTile(LucideIcons.notebookPen, 'Nhật ký dinh dưỡng', 'Món đã ăn, nước uống và vận động theo ngày',
                  () => _open(context, const DiaryScreen())),
              const Divider(height: 1),
              _MenuTile(LucideIcons.bookmark, 'Yêu thích', 'Công thức, bài viết và video đã lưu',
                  () => _open(context, const FavoritesScreen())),
              const Divider(height: 1),
              _MenuTile(LucideIcons.trophy, 'Huy hiệu xanh', 'Thành tích sống xanh của bạn',
                  () => _open(context, const BadgesScreen())),
              const Divider(height: 1),
              _MenuTile(LucideIcons.fileText, 'Bài viết của tôi', 'Viết bài, sửa, gửi duyệt, xem trạng thái',
                  () => _open(context, const MyBlogsScreen())),
              const Divider(height: 1),
              _MenuTile(LucideIcons.chefHat, 'Công thức của tôi', 'Tạo, sửa, đăng công thức món chay',
                  () => _open(context, const MyRecipesScreen())),
              const Divider(height: 1),
              _MenuTile(LucideIcons.video, 'Video của tôi', 'Đăng video, sửa, gửi duyệt, xem trạng thái',
                  () => _open(context, const MyVideosScreen())),
              const Divider(height: 1),
              _MenuTile(LucideIcons.sparkles, 'Bóc tách công thức từ video',
                  'AI lấy nguyên liệu và các bước từ video nấu ăn', () => _open(context, const VideoJobsScreen())),
              const Divider(height: 1),
              _MenuTile(LucideIcons.crown, 'Gói thành viên', _planSubtitle(context),
                  () => _open(context, const PricingScreen())),
              const Divider(height: 1),
              _MenuTile(LucideIcons.receipt, 'Lịch sử thanh toán', 'Các đơn đã mua và đang chờ thanh toán',
                  () => _open(context, const PaymentHistoryScreen())),
              const Divider(height: 1),
              _MenuTile(LucideIcons.keyRound, 'Đổi mật khẩu', null,
                  () => _open(context, const ChangePasswordScreen())),
              const Divider(height: 1),
              _MenuTile(
                  LucideIcons.shieldAlert,
                  'Dị ứng thực phẩm',
                  overview.allergies == null
                      ? 'Nguyên liệu cần tránh trong thực đơn'
                      : overview.allergies == 0
                          ? 'Chưa chọn chất nào • thực đơn không loại trừ nguyên liệu'
                          : 'Đang tránh ${overview.allergies} chất trong thực đơn',
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
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat(this.value, this.label);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: context.cs.primary)),
          Text(label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(fontSize: 11.5, color: context.textMuted)),
        ]),
      );
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
