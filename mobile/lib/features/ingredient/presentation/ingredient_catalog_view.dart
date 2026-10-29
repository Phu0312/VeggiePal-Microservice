import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/login_screen.dart';
import '../data/ingredient_models.dart';
import '../data/ingredient_repository.dart';
import '../data/pantry_controller.dart';

/// Danh mục nguyên liệu chung (GET /ingredients, công khai): tìm theo tên, lọc thuần chay / dễ gây dị ứng,
/// phân trang. Bấm một nguyên liệu để xem dinh dưỡng trên 100g và thêm vào tủ của tôi.
class IngredientCatalogView extends StatefulWidget {
  const IngredientCatalogView({super.key});

  @override
  State<IngredientCatalogView> createState() => _IngredientCatalogViewState();
}

class _IngredientCatalogViewState extends State<IngredientCatalogView> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  final _items = <Ingredient>[];
  IngredientFilter _filter = IngredientFilter.all;
  String _keyword = '';
  int _page = 0;
  int _total = 0;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  bool _failed = false;
  int _generation = 0; // bỏ kết quả của lần tải cũ khi đã bắt đầu lần tải mới

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.hasClients && _scroll.position.extentAfter < 300) _loadMore();
    });
    _reload();
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final gen = ++_generation;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final p = await context
          .read<IngredientRepository>()
          .page(keyword: _keyword, filter: _filter, page: 0);
      if (!mounted || gen != _generation) return;
      setState(() {
        _items
          ..clear()
          ..addAll(p.items);
        _page = p.page;
        _total = p.totalElements;
        _hasMore = p.hasMore;
      });
    } catch (e) {
      if (!mounted || gen != _generation) return;
      setState(() => _failed = true);
      showErrorDialog(context, errorMessage(e), title: 'Không tải được nguyên liệu');
    } finally {
      if (mounted && gen == _generation) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    final gen = _generation;
    setState(() => _loadingMore = true);
    try {
      final p = await context
          .read<IngredientRepository>()
          .page(keyword: _keyword, filter: _filter, page: _page + 1);
      if (!mounted || gen != _generation) return;
      setState(() {
        _items.addAll(p.items);
        _page = p.page;
        _hasMore = p.hasMore;
      });
    } catch (e) {
      if (mounted && gen == _generation) showSnack(context, errorMessage(e));
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _submit(String text) {
    _keyword = text.trim();
    _reload();
  }

  void _addToPantry(Ingredient g) {
    if (!context.read<AuthController>().isLoggedIn) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    final added = context.read<PantryController>().add(PantryItem(name: g.name));
    showSnack(context, added ? 'Đã thêm "${g.name}" vào tủ của bạn' : '"${g.name}" đã có trong tủ');
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      VegSearchBar(controller: _search, hint: 'Tìm nguyên liệu...', onSubmitted: _submit),
      SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          children: [
            for (final f in IngredientFilter.values) ...[
              ChoiceChip(
                label: Text(f.label),
                selected: _filter == f,
                onSelected: (_) {
                  if (_filter == f) return;
                  setState(() => _filter = f);
                  _reload();
                },
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _failed
                ? RetryView(onRetry: _reload)
                : RefreshIndicator(
                    onRefresh: _reload,
                    child: _items.isEmpty
                        ? ListView(children: [
                            Padding(
                              padding: const EdgeInsets.all(48),
                              child: Center(
                                  child: Text('Không tìm thấy nguyên liệu phù hợp.',
                                      style: TextStyle(color: context.textMuted))),
                            ),
                          ])
                        : ListView.separated(
                            controller: _scroll,
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: _items.length + 1 + (_loadingMore ? 1 : 0),
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              if (i == 0) {
                                return Text('$_total nguyên liệu',
                                    style: TextStyle(fontSize: 12.5, color: context.textMuted));
                              }
                              if (i > _items.length) {
                                return const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Center(child: CircularProgressIndicator()));
                              }
                              final g = _items[i - 1];
                              return _IngredientCard(
                                g,
                                onTap: () => showIngredientSheet(context, g, onAddToPantry: () => _addToPantry(g)),
                              );
                            },
                          ),
                  ),
      ),
    ]);
  }
}

class _IngredientCard extends StatelessWidget {
  final Ingredient g;
  final VoidCallback onTap;
  const _IngredientCard(this.g, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            VegImage(g.imageUrl, width: 56, height: 56, radius: BorderRadius.circular(12)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(g.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                Text('${g.calories.round()} kcal • ${g.protein.toStringAsFixed(1)}g đạm / 100g',
                    style: TextStyle(fontSize: 12.5, color: context.textMuted)),
                if (g.hasDescription)
                  Text(g.description!.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: context.textMuted)),
              ]),
            ),
            if (g.allergen)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(LucideIcons.triangleAlert, size: 16, color: Colors.deepOrange),
              ),
            if (g.vegan)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(LucideIcons.leaf, size: 16, color: context.cs.primary),
              ),
          ]),
        ),
      ),
    );
  }
}

/// Chi tiết một nguyên liệu: ảnh, mô tả, cờ thuần chay / dị ứng và dinh dưỡng trên 100g.
Future<void> showIngredientSheet(BuildContext context, Ingredient g,
    {required VoidCallback onAddToPantry}) {
  Widget macro(String label, String value) => Expanded(
        child: Column(children: [
          Text(value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.cs.primary)),
          Text(label, style: TextStyle(fontSize: 11.5, color: context.textMuted)),
        ]),
      );

  Widget chip(IconData icon, String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: color)),
        ]),
      );

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(g.name, style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 6, children: [
            if (g.vegan) chip(LucideIcons.leaf, 'Thuần chay', ctx.cs.primary),
            if (g.allergen) chip(LucideIcons.triangleAlert, 'Dễ gây dị ứng', Colors.deepOrange),
          ]),
          if (g.imageUrl != null && g.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            VegImage(g.imageUrl, width: double.infinity, height: 160, radius: BorderRadius.circular(16)),
          ],
          if (g.hasDescription) ...[
            const SizedBox(height: 12),
            Text(g.description!.trim(), style: const TextStyle(height: 1.4)),
          ],
          const SizedBox(height: 16),
          Text('Dinh dưỡng trên 100g', style: TextStyle(fontSize: 12.5, color: ctx.textMuted)),
          const SizedBox(height: 6),
          Row(children: [
            macro('kcal', '${g.calories.round()}'),
            macro('Đạm (g)', g.protein.toStringAsFixed(1)),
            macro('Tinh bột (g)', g.carbs.toStringAsFixed(1)),
            macro('Béo (g)', g.fat.toStringAsFixed(1)),
            if (g.fiber != null) macro('Xơ (g)', g.fiber!.toStringAsFixed(1)),
          ]),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                onAddToPantry();
              },
              icon: const Icon(LucideIcons.refrigerator),
              label: const Text('Thêm vào tủ của tôi'),
            ),
          ),
        ]),
      ),
    ),
  );
}
