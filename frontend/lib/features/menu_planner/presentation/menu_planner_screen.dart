import 'package:flutter/material.dart';

import 'pantry_tab.dart';
import 'plan_tab.dart';
import 'recipes_tab.dart';

/// TAB 4 - Thực đơn. Ba phần: Thực đơn (BMI, tạo/lưu/đổi món) | Công thức | Nguyên liệu của tôi.
class MenuPlannerScreen extends StatelessWidget {
  const MenuPlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 3,
      child: Column(children: [
        TabBar(tabs: [
          Tab(text: 'Thực đơn'),
          Tab(text: 'Công thức'),
          Tab(text: 'Nguyên liệu'),
        ]),
        Expanded(
          child: TabBarView(children: [
            PlanTab(),
            RecipesTab(),
            PantryTab(),
          ]),
        ),
      ]),
    );
  }
}
