import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/header_actions.dart';
import '../../../core/utils/format.dart';
import '../../profile/data/profile_models.dart';
import '../../profile/data/profile_repository.dart';
import '../data/admin_repository.dart';

/// App quản trị riêng cho tài khoản Admin (thay hoàn toàn app người dùng, xem main.dart).
/// Widget tree: Scaffold -> DefaultTabController(TabBar 4 tab)
///   Thành viên | Kiểm duyệt | Danh mục | AI
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 64,
          centerTitle: false,
          title: const AppLogo(size: 44),
          actions: const [ThemeToggleButton(), AdminAccountBar()],
          bottom: const TabBar(tabs: [
            Tab(text: 'Thành viên'),
            Tab(text: 'Kiểm duyệt'),
            Tab(text: 'Danh mục'),
            Tab(text: 'AI'),
          ]),
        ),
        body: const TabBarView(children: [
          _UsersTab(),
          _ModerationTab(),
          _CategoryTab(),
          _AiTab(),
        ]),
      ),
    );
  }
}

/// Chạy tác vụ admin, hiển thị popup lỗi (không kết nối được backend, 403...) nếu có.
Future<void> _guard(BuildContext c, Future<void> Function() job) async {
  try {
    await job();
  } catch (e) {
    if (c.mounted) await showErrorDialog(c, errorMessage(e));
  }
}

class _UsersTab extends StatefulWidget {
  const _UsersTab();
  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  List<AdminUser> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load([String? kw]) async {
    setState(() => _loading = true);
    await _guard(context, () async {
      final r = await context.read<AdminRepository>().users(keyword: kw);
      if (mounted) setState(() => _users = r);
    });
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggle(AdminUser u) async {
    final next = u.status == 'BLOCKED' ? 'ACTIVE' : 'BLOCKED';
    await _guard(context, () async {
      await context.read<AdminRepository>().setUserStatus(u.id, next);
      if (!mounted) return;
      setState(() => _users = [for (final x in _users) x.id == u.id ? x.copyWith(status: next) : x]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      VegSearchBar(hint: 'Tìm thành viên theo tên/email', onSubmitted: _load),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _users.length,
                itemBuilder: (_, i) {
                  final u = _users[i];
                  final blocked = u.status == 'BLOCKED';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                          backgroundColor: AppColors.accent,
                          child: Text(u.fullName.isEmpty ? '?' : u.fullName[0])),
                      title: Text(u.fullName),
                      subtitle: Text('${u.email}\n${u.role} • ${u.status}'),
                      isThreeLine: true,
                      onTap: () => _showUserDetail(context, u),
                      trailing: u.role == 'ADMIN'
                          ? null
                          : TextButton(
                              onPressed: () => _toggle(u),
                              child: Text(blocked ? 'Mở khóa' : 'Khóa',
                                  style: TextStyle(color: blocked ? context.cs.primary : Colors.red)),
                            ),
                    ),
                  );
                },
              ),
      ),
    ]);
  }
}

void _showUserDetail(BuildContext context, AdminUser u) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _UserDetailSheet(u),
    );

/// Chi tiết thành viên: GET /admin/users/{id} + dị ứng công khai GET /nutrition/allergies/user/{id}.
class _UserDetailSheet extends StatefulWidget {
  final AdminUser user;
  const _UserDetailSheet(this.user);

  @override
  State<_UserDetailSheet> createState() => _UserDetailSheetState();
}

class _UserDetailSheetState extends State<_UserDetailSheet> {
  UserProfile? _profile;
  List<String> _allergies = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final id = widget.user.id;
      final r = await Future.wait([
        context.read<AdminRepository>().userDetail(id),
        context.read<ProfileRepository>().allergenCodesOfUser(id),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = r[0] as UserProfile;
        _allergies = r[1] as List<String>;
      });
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e), title: 'Không tải được chi tiết thành viên');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 120, child: Text(label, style: TextStyle(color: context.textMuted))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final p = _profile;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: _loading
            ? const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()))
            : p == null
                ? SizedBox(height: 160, child: RetryView(onRetry: _load))
                : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.fullName.isEmpty ? p.email : p.fullName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    _row('Email', p.email),
                    _row('Số điện thoại', (p.phone ?? '').isEmpty ? 'Chưa cập nhật' : p.phone!),
                    _row('Ngày sinh', p.dateOfBirth == null ? 'Chưa cập nhật' : fmtDate(p.dateOfBirth!)),
                    _row('Vai trò', p.role),
                    _row('Trạng thái', p.status),
                    _row('Xác thực email', p.emailVerified ? 'Đã xác thực' : 'Chưa xác thực'),
                    _row('Ngày tạo', p.createdAt == null ? '-' : fmtDate(p.createdAt!)),
                    _row('Dị ứng', _allergies.isEmpty ? 'Không có' : _allergies.join(', ')),
                  ]),
      ),
    );
  }
}

class _ModerationTab extends StatefulWidget {
  const _ModerationTab();
  @override
  State<_ModerationTab> createState() => _ModerationTabState();
}

class _ModerationTabState extends State<_ModerationTab> {
  List<ModerationItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _guard(context, () async {
      final r = await context.read<AdminRepository>().moderationQueue();
      if (mounted) setState(() => _items = r);
    });
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _review(ModerationItem it, bool approve) => _guard(context, () async {
        await context
            .read<AdminRepository>()
            .review(it.id, approve, approve ? 'Nội dung phù hợp' : 'Vi phạm quy định cộng đồng');
        if (mounted) setState(() => _items = _items.where((x) => x.id != it.id).toList());
      });

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty) return const Center(child: Text('Không có nội dung nào cần duyệt 🎉'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      itemBuilder: (_, i) {
        final it = _items[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Chip(label: Text('${it.targetType} #${it.targetId}')),
                const SizedBox(width: 8),
                if (it.keywords.isNotEmpty)
                  Expanded(
                      child: Text('Từ khóa: ${it.keywords}',
                          style: const TextStyle(color: Colors.red, fontSize: 12))),
              ]),
              Text(it.snippet),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                OutlinedButton(onPressed: () => _review(it, false), child: const Text('Từ chối')),
                const SizedBox(width: 8),
                FilledButton(onPressed: () => _review(it, true), child: const Text('Duyệt')),
              ]),
            ]),
          ),
        );
      },
    );
  }
}

class _CategoryTab extends StatefulWidget {
  const _CategoryTab();
  @override
  State<_CategoryTab> createState() => _CategoryTabState();
}

class _CategoryTabState extends State<_CategoryTab> {
  final _name = TextEditingController();
  String _type = 'RECIPE_TYPE';

  Future<void> _create() async {
    if (_name.text.trim().isEmpty) return;
    await _guard(context, () async {
      await context.read<AdminRepository>().createCategory(_name.text.trim(), _type);
      if (!mounted) return;
      showSnack(context, 'Đã tạo danh mục "${_name.text.trim()}"');
      _name.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Tạo danh mục món ăn mới', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      const SizedBox(height: 12),
      TextField(
          controller: _name,
          decoration: const InputDecoration(
              labelText: 'Tên danh mục', hintText: 'Nhập tên danh mục', prefixIcon: Icon(LucideIcons.tag))),
      const SizedBox(height: 12),
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'RECIPE_TYPE', label: Text('Loại công thức')),
          ButtonSegment(value: 'FOOD_TYPE', label: Text('Loại thực phẩm')),
        ],
        selected: {_type},
        onSelectionChanged: (s) => setState(() => _type = s.first),
      ),
      const SizedBox(height: 16),
      FilledButton.icon(onPressed: _create, icon: const Icon(Icons.add), label: const Text('Tạo danh mục')),
    ]);
  }
}

class _AiTab extends StatefulWidget {
  const _AiTab();
  @override
  State<_AiTab> createState() => _AiTabState();
}

class _AiTabState extends State<_AiTab> {
  static const _labels = {
    'totalRequests': 'Tổng yêu cầu',
    'successCount': 'Thành công',
    'failureCount': 'Thất bại',
    'chatRequests': 'Chat',
    'mealPlanRequests': 'Thực đơn',
    'moderationRequests': 'Kiểm duyệt',
    'videoSummaryRequests': 'Tóm tắt video',
  };

  Map<String, dynamic>? _metrics;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await _guard(context, () async {
      final r = await context.read<AdminRepository>().aiMetrics();
      if (mounted) setState(() => _metrics = r);
    });
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final m = _metrics;
    if (m == null) {
      return Center(
          child: OutlinedButton.icon(
              onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Thử lại')));
    }
    return GridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        for (final e in _labels.entries)
          Card(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('${m[e.key] ?? 0}',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: context.cs.primary)),
              Text(e.value),
            ]),
          ),
      ],
    );
  }
}
