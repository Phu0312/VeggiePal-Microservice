import 'package:flutter/material.dart';

import 'recipes_tab.dart';

/// Danh sách công thức đã đăng ở một màn riêng (mở từ Trang chủ), dùng lại nội dung của tab Công thức.
class RecipesScreen extends StatelessWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Công thức món chay')),
        body: const RecipesTab(),
      );
}
