import 'package:flutter/material.dart';

import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/header_actions.dart';
import 'admin_ai_tab.dart';
import 'admin_ingredients_tab.dart';
import 'admin_payments_tab.dart';
import 'category_manager_tab.dart';
import 'moderation_tab.dart';

/// App quản trị riêng cho tài khoản Admin (thay hoàn toàn app người dùng, xem main.dart).
/// Widget tree: Scaffold -> DefaultTabController(TabBar cuộn ngang 5 tab)
///   Kiểm duyệt | Danh mục | Nguyên liệu | Thanh toán | AI
/// Quản lý thành viên không có ở đây vì identity-service chưa có API quản trị tài khoản.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 64,
          centerTitle: false,
          title: const AppLogo(size: 44),
          actions: const [ThemeToggleButton(), AdminAccountBar()],
          bottom: const TabBar(isScrollable: true, tabAlignment: TabAlignment.start, tabs: [
            Tab(text: 'Kiểm duyệt'),
            Tab(text: 'Danh mục'),
            Tab(text: 'Nguyên liệu'),
            Tab(text: 'Thanh toán'),
            Tab(text: 'AI'),
          ]),
        ),
        body: const TabBarView(children: [
          ModerationTab(),
          CategoryManagerTab(),
          AdminIngredientsTab(),
          AdminPaymentsTab(),
          AdminAiTab(),
        ]),
      ),
    );
  }
}
