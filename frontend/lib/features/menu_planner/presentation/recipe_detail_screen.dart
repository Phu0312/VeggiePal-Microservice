import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/common_widgets.dart';
import '../data/meal_models.dart';
import '../data/meal_repository.dart';
import '../data/menu_models.dart';

/// Chi tiết một công thức: GET /nutrition/recipes/{id}.
class RecipeDetailScreen extends StatefulWidget {
  final int recipeId;
  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  RecipeItem? _recipe;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await context.read<MealRepository>().recipe(widget.recipeId);
      if (mounted) setState(() => _recipe = r);
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e), title: 'Không tải được công thức');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _macro(String label, String value) => Expanded(
        child: Column(children: [
          Text(value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: context.cs.primary)),
          Text(label, style: TextStyle(fontSize: 12, color: context.textMuted)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final r = _recipe;
    return Scaffold(
      appBar: AppBar(title: const Text('Công thức')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : r == null
              ? RetryView(onRetry: _load)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(mealTypeLabel(r.mealType),
                        style: TextStyle(
                            color: context.cs.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(r.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(children: [
                          _macro('kcal', r.calories.toStringAsFixed(0)),
                          _macro('Đạm (g)', r.protein.toStringAsFixed(1)),
                          _macro('Carb (g)', r.carbs.toStringAsFixed(1)),
                          _macro('Béo (g)', r.fat.toStringAsFixed(1)),
                        ]),
                      ),
                    ),
                    const SectionHeader('Nguyên liệu'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        for (final i in r.ingredientList)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Icon(LucideIcons.leaf, size: 16, color: context.cs.primary),
                              const SizedBox(width: 8),
                              Expanded(child: Text(i)),
                            ]),
                          ),
                      ]),
                    ),
                    if ((r.instructions ?? '').trim().isNotEmpty) ...[
                      const SectionHeader('Cách làm'),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(r.instructions!, style: const TextStyle(height: 1.5, fontSize: 15)),
                      ),
                    ],
                    if (r.allergenCodes.isNotEmpty) ...[
                      const SectionHeader('Có thể gây dị ứng'),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Wrap(spacing: 8, runSpacing: 4, children: [
                          for (final c in r.allergenCodes)
                            Chip(
                              label: Text(c),
                              avatar: Icon(LucideIcons.triangleAlert, size: 16, color: context.cs.error),
                            ),
                        ]),
                      ),
                    ],
                  ],
                ),
    );
  }
}
