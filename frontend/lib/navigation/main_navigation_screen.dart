import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/widgets/common_widgets.dart';
import '../features/admin/presentation/admin_dashboard_screen.dart';
import '../features/ai_nutrition/presentation/chatbot_screen.dart';
import '../features/auth/data/auth_models.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/menu_planner/presentation/menu_planner_screen.dart';
import '../features/places/presentation/places_screen.dart';

/// Khung chính: AppBar (Role Switcher) + 4 tab + NavigationBar Material 3.
/// Widget tree: Scaffold
///   ├─ AppBar  (logo, nút Admin, Role Switcher)
///   ├─ body    FadeTransition(IndexedStack[4 tab])  -> giữ state từng tab, chuyển tab mờ dần mượt
///   └─ NavigationBar
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  late final AnimationController _fade =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 250), value: 1);

  static const _titles = ['VeggiePal', 'Quán chay', 'Thực đơn & BMI', 'Trợ lý AI'];

  void _select(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    _fade.forward(from: 0); // phát hiệu ứng fade mỗi lần đổi tab
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Row(children: [
          const AppLogo(size: 56),
          // Tab Trang chủ chỉ hiện logo; các tab khác hiện tên tab.
          if (_index != 0) ...[
            const SizedBox(width: 10),
            Text(_titles[_index], style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ]),
        actions: [
          if (auth.isAdmin)
            IconButton(
              tooltip: 'Bảng quản trị',
              icon: const Icon(Icons.admin_panel_settings, color: AppColors.primary),
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const AdminDashboardScreen())),
            ),
          _RoleSwitcher(auth),
        ],
      ),
      body: FadeTransition(
        opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut),
        child: IndexedStack(index: _index, children: const [
          HomeScreen(),
          PlacesScreen(),
          MenuPlannerScreen(),
          ChatbotScreen(),
        ]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Trang chủ'),
          NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Quán chay'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Thực đơn'),
          NavigationDestination(icon: Icon(Icons.smart_toy_outlined), selectedIcon: Icon(Icons.smart_toy), label: 'Trợ lý AI'),
        ],
      ),
    );
  }
}

/// Role Switcher (Khách / Thành viên / Admin) để test nhanh giao diện phân quyền,
/// kèm lối vào đăng nhập thật bằng tài khoản backend.
class _RoleSwitcher extends StatelessWidget {
  final AuthController auth;
  const _RoleSwitcher(this.auth);

  static const _labels = {
    UserRole.guest: 'Khách',
    UserRole.user: 'Thành viên',
    UserRole.admin: 'Admin',
  };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Object>(
      tooltip: 'Đổi vai trò',
      onSelected: (v) {
        if (v is UserRole) {
          auth.switchRole(v);
        } else {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
        }
      },
      itemBuilder: (_) => [
        for (final r in UserRole.values)
          CheckedPopupMenuItem<Object>(
              value: r, checked: r == auth.role, child: Text(_labels[r]!)),
        const PopupMenuDivider(),
        const PopupMenuItem<Object>(value: 'login', child: Text('Đăng nhập tài khoản...')),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Chip(
          avatar: const Icon(Icons.person, size: 18),
          label: Text(_labels[auth.role]!),
        ),
      ),
    );
  }
}
