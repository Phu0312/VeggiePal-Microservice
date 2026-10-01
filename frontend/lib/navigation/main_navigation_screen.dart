import 'package:flutter/material.dart';

import '../core/widgets/common_widgets.dart';
import '../core/widgets/header_actions.dart';
import '../features/ai_nutrition/presentation/chatbot_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/menu_planner/presentation/menu_planner_screen.dart';
import '../features/places/presentation/places_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import 'app_bottom_bar.dart';

/// Khung chính của app người dùng.
/// Widget tree: Scaffold
///   ├─ AppBar  (logo | chuông thông báo, đổi sáng/tối, avatar)
///   ├─ body    FadeTransition(IndexedStack[5 tab])  -> giữ state từng tab
///   ├─ FAB     nút tròn Trợ lý AI nổi ở giữa
///   └─ AppBottomBar (Trang chủ, Quán chay, [AI], Thực đơn, Hồ sơ)
/// Tài khoản Admin không dùng khung này mà vào app quản trị riêng (xem main.dart).
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
    // Ẩn nút AI khi bàn phím mở (nếu không nó sẽ nổi lên trên bàn phím).
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        centerTitle: false,
        title: const AppLogo(size: 44),
        actions: [
          const NotificationBell(),
          const ThemeToggleButton(),
          HeaderAvatarButton(onOpenProfile: () => _select(4)),
        ],
      ),
      body: FadeTransition(
        opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut),
        child: IndexedStack(index: _index, children: const [
          HomeScreen(),
          PlacesScreen(),
          ChatbotScreen(),
          MenuPlannerScreen(),
          ProfileScreen(),
        ]),
      ),
      floatingActionButtonLocation: const AiFabLocation(),
      floatingActionButton: keyboardOpen ? null : AiFab(onPressed: () => _select(centerIndex)),
      bottomNavigationBar: AppBottomBar(index: _index, onSelect: _select),
    );
  }
}
