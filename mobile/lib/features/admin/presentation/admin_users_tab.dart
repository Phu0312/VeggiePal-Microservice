import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/paged_list_view.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/admin_models.dart';
import '../data/admin_repository.dart';

enum _UserAction { block, activate, makeAdmin, makeUser }

/// Quản lý tài khoản (admin): tìm theo email / họ tên, lọc theo vai trò và trạng thái, khóa / mở khóa tài khoản,
/// cấp hoặc gỡ quyền quản trị. Dữ liệu từ identity-service `/admin/users`; danh sách đã có đủ thông tin nên
/// không cần gọi thêm endpoint chi tiết. Admin không thể tự khóa hay tự hạ quyền chính mình (BE trả lỗi 1022),
/// nên với tài khoản của chính mình màn hình không đưa ra các thao tác đó.
class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _search = TextEditingController();
  final _list = GlobalKey<PagedListViewState<AdminUser>>();
  String _keyword = '';
  String? _role;
  String? _status;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reload() => _list.currentState?.reload();

  Future<void> _open(AdminUser u) async {
    final selfId = context.read<AuthController>().user?.id;
    final action = await showModalBottomSheet<_UserAction>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _UserSheet(user: u, isSelf: u.id == selfId),
    );
    if (action != null && mounted) await _perform(u, action);
  }

  /// Hỏi xác nhận rồi gọi BE. Thành công thì cập nhật đúng dòng đó trong danh sách.
  Future<void> _perform(AdminUser u, _UserAction action) async {
    final (title, message, confirm) = switch (action) {
      _UserAction.block => (
        'Khóa tài khoản',
        'Khóa "${u.displayName}"? Người này không đăng nhập lại được và các phiên làm mới bị thu hồi; '
            'phiên đang mở hết hiệu lực khi token hết hạn (tối đa 24 giờ).',
        'Khóa',
      ),
      _UserAction.activate => (
        u.isBlocked ? 'Mở khóa tài khoản' : 'Kích hoạt tài khoản',
        '${u.isBlocked ? 'Mở khóa' : 'Kích hoạt'} "${u.displayName}" để người này đăng nhập được trở lại?',
        u.isBlocked ? 'Mở khóa' : 'Kích hoạt',
      ),
      _UserAction.makeAdmin => (
        'Cấp quyền quản trị',
        'Cấp quyền quản trị cho "${u.displayName}"? Người này sẽ dùng được mọi chức năng quản trị.',
        'Cấp quyền',
      ),
      _UserAction.makeUser => (
        'Gỡ quyền quản trị',
        'Gỡ quyền quản trị của "${u.displayName}"? Người này trở lại là thành viên thường.',
        'Gỡ quyền',
      ),
    };
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(confirm)),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final repo = context.read<AdminRepository>();
    try {
      final updated = await switch (action) {
        _UserAction.block => repo.setUserStatus(u.id, 'BLOCKED'),
        _UserAction.activate => repo.setUserStatus(u.id, 'ACTIVE'),
        _UserAction.makeAdmin => repo.setUserRole(u.id, 'ADMIN'),
        _UserAction.makeUser => repo.setUserRole(u.id, 'USER'),
      };
      if (!mounted) return;
      _list.currentState?.replaceWhere((x) => x.id == updated.id, updated);
      showSnack(context, '$title: đã cập nhật "${updated.displayName}"');
    } catch (e) {
      if (!mounted) return;
      // 1020 / 1023: tài khoản đã được admin khác đổi sang đúng trạng thái này. Tải lại để thấy dữ liệu mới nhất.
      if (e is ApiException && (e.code == 1020 || e.code == 1023)) _reload();
      await showErrorDialog(context, errorMessage(e), title: 'Không cập nhật được tài khoản');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final repo = context.read<AdminRepository>();
    return Column(
      children: [
        VegSearchBar(
          controller: _search,
          hint: 'Tìm theo email hoặc họ tên...',
          onSubmitted: (v) {
            _keyword = v.trim();
            _reload();
          },
        ),
        FilterRow(children: [
          FilterDropdown<String?>(
            options: const {null: 'Mọi vai trò', 'USER': 'Thành viên', 'ADMIN': 'Quản trị viên'},
            selected: _role,
            onChanged: (v) {
              setState(() => _role = v);
              _reload();
            },
          ),
          FilterDropdown<String?>(
            options: {
              null: 'Mọi trạng thái',
              'ACTIVE': userStatusLabels['ACTIVE']!,
              'BLOCKED': userStatusLabels['BLOCKED']!,
              'PENDING': userStatusLabels['PENDING']!,
              'INACTIVE': userStatusLabels['INACTIVE']!,
            },
            selected: _status,
            onChanged: (v) {
              setState(() => _status = v);
              _reload();
            },
          ),
        ]),
        Expanded(
          child: PagedListView<AdminUser>(
            key: _list,
            errorTitle: 'Không tải được danh sách tài khoản',
            load: (page) => repo.users(keyword: _keyword, role: _role, status: _status, page: page),
            emptyText: 'Không có tài khoản phù hợp.',
            itemBuilder: (context, u) => Card(
              child: ListTile(
                onTap: () => _open(u),
                leading: _Avatar(u),
                title: Text(
                  u.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u.email, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (u.isAdmin) _Badge(u.roleLabel, context.cs.tertiary),
                        _Badge(u.statusLabel, _statusColor(context, u.status)),
                        if (!u.emailVerified) _Badge('Chưa xác minh email', context.textMuted),
                      ],
                    ),
                  ],
                ),
                isThreeLine: true,
                trailing: const Icon(LucideIcons.chevronRight, size: 18),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Color _statusColor(BuildContext context, String status) => switch (status) {
  'ACTIVE' => context.cs.primary,
  'BLOCKED' => context.cs.error,
  _ => Colors.deepOrange,
};

class _Avatar extends StatelessWidget {
  final AdminUser user;
  final double radius;
  const _Avatar(this.user, {this.radius = 20});

  @override
  Widget build(BuildContext context) {
    final url = user.avatarUrl;
    return CircleAvatar(
      radius: radius,
      foregroundImage: (url == null || url.isEmpty) ? null : NetworkImage(url),
      onForegroundImageError: (url == null || url.isEmpty) ? null : (_, _) {},
      child: Text(user.displayName[0].toUpperCase()),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
    child: Text(
      label,
      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color),
    ),
  );
}

/// Chi tiết một tài khoản và các thao tác có thể làm; đóng sheet và trả về thao tác đã chọn.
class _UserSheet extends StatelessWidget {
  final AdminUser user;
  final bool isSelf;
  const _UserSheet({required this.user, required this.isSelf});

  Widget _row(BuildContext context, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: TextStyle(color: context.textMuted)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final u = user;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Avatar(u, radius: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    u.displayName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _row(context, 'Mã tài khoản', '#${u.id}'),
            _row(context, 'Email', u.email),
            _row(context, 'Số điện thoại', (u.phone ?? '').isEmpty ? 'Chưa cập nhật' : u.phone!),
            _row(context, 'Vai trò', u.roleLabel),
            _row(context, 'Trạng thái', u.statusLabel),
            _row(context, 'Xác minh email', u.emailVerified ? 'Đã xác minh' : 'Chưa xác minh'),
            _row(context, 'Ngày tạo', u.createdAt == null ? '-' : fmtDateTime(u.createdAt!)),
            const SizedBox(height: 12),
            if (isSelf)
              Text(
                'Đây là tài khoản của bạn. Quản trị viên không thể tự khóa hoặc tự hạ quyền chính mình.',
                style: TextStyle(color: context.textMuted),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  if (u.status != 'ACTIVE')
                    FilledButton.icon(
                      onPressed: () => Navigator.pop(context, _UserAction.activate),
                      icon: const Icon(LucideIcons.lockOpen),
                      label: Text(u.isBlocked ? 'Mở khóa tài khoản' : 'Kích hoạt tài khoản'),
                    ),
                  if (!u.isBlocked)
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context, _UserAction.block),
                      style: OutlinedButton.styleFrom(foregroundColor: context.cs.error),
                      icon: const Icon(LucideIcons.lock),
                      label: const Text('Khóa tài khoản'),
                    ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.pop(context, u.isAdmin ? _UserAction.makeUser : _UserAction.makeAdmin),
                    icon: Icon(u.isAdmin ? LucideIcons.userMinus : LucideIcons.shieldCheck),
                    label: Text(u.isAdmin ? 'Gỡ quyền quản trị' : 'Cấp quyền quản trị'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
