import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/common_widgets.dart';
import '../data/recipe_models.dart';
import '../data/recipe_repository.dart';
import 'recipe_detail_screen.dart';
import 'recipe_form_screen.dart';
import 'recipe_widgets.dart';

/// Công thức của tôi (GET /recipes/me): bản nháp, đã đăng, đang ẩn. Bấm vào để xem, sửa, đăng hoặc xoá.
class MyRecipesScreen extends StatefulWidget {
  const MyRecipesScreen({super.key});

  @override
  State<MyRecipesScreen> createState() => _MyRecipesScreenState();
}

class _MyRecipesScreenState extends State<MyRecipesScreen> {
  final _list = GlobalKey<PagedRecipesState>();

  Future<void> _create() async {
    final saved = await Navigator.of(context)
        .push<Recipe>(MaterialPageRoute(builder: (_) => const RecipeFormScreen()));
    if (saved != null && mounted) {
      showSnack(context, 'Đã lưu công thức');
      _list.currentState?.reload();
    }
  }

  Future<void> _open(Recipe r) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipeId: r.id, initial: r)));
    if (mounted) _list.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<RecipeRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Công thức của tôi')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'my-recipes-add',
        onPressed: _create,
        icon: const Icon(LucideIcons.plus),
        label: const Text('Tạo công thức'),
      ),
      body: PagedRecipes(
        key: _list,
        load: (page) => repo.mine(page: page),
        onTap: _open,
        showStatus: true,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        emptyText: 'Bạn chưa có công thức nào.\nBấm "Tạo công thức" để bắt đầu.',
      ),
    );
  }
}
