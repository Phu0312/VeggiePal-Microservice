import 'package:flutter/material.dart';

import '../../ingredient/presentation/ingredient_tab.dart';
import 'plan_tab.dart';
import '../../recipe/presentation/recipes_tab.dart';

/// TAB 4 - Thực đơn. Ba phần: Thực đơn (BMI, tạo/đổi món/yêu thích) | Công thức | Nguyên liệu (tủ của tôi + danh mục).
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
            IngredientTab(),
          ]),
        ),
      ]),
    );
  }
}
