import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/common_widgets.dart';
import '../data/admin_repository.dart';

/// Ban quản trị. Widget tree: Scaffold -> DefaultTabController(TabBar 4 tab)
///   Thành viên | Kiểm duyệt | Danh mục | AI
/// Chỉ mở được khi role == Admin (nút vào nằm ở Top Bar của MainNavigationScreen).
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản trị VeggiePal'),
          bottom: const TabBar(isScrollable: true, tabs: [
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

/// Chạy tác vụ admin, hiển thị lỗi nghiệp vụ (vd 403) nếu có.
Future<void> _guard(BuildContext c, Future<void> Function() job) async {
  try {
    await job();
  } on ApiException catch (e) {
    if (c.mounted) showSnack(c, e.message);
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
                      trailing: u.role == 'ADMIN'
                          ? null
                          : TextButton(
                              onPressed: () => _toggle(u),
                              child: Text(blocked ? 'Mở khóa' : 'Khóa',
                                  style: TextStyle(color: blocked ? AppColors.primary : Colors.red)),
                            ),
                    ),
                  );
                },
              ),
      ),
    ]);
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
      TextField(controller: _name, decoration: const InputDecoration(labelText: 'Tên danh mục')),
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

class _AiTab extends StatelessWidget {
  const _AiTab();

  static const _labels = {
    'totalRequests': 'Tổng yêu cầu',
    'successCount': 'Thành công',
    'failureCount': 'Thất bại',
    'chatRequests': 'Chat',
    'mealPlanRequests': 'Thực đơn',
    'moderationRequests': 'Kiểm duyệt',
    'videoSummaryRequests': 'Tóm tắt video',
  };

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: context.read<AdminRepository>().aiMetrics(),
      builder: (_, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
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
                  Text('${snap.data![e.key] ?? 0}',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  Text(e.value),
                ]),
              ),
          ],
        );
      },
    );
  }
}
