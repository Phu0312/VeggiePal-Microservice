import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../blog/data/blog_models.dart';
import '../data/recipe_models.dart';

Color recipeStatusColor(BuildContext context, String status) => switch (status) {
      'PUBLISHED' => Colors.green,
      'DRAFT' => Colors.orange,
      'HIDDEN' || 'ARCHIVED' => context.cs.error,
      _ => context.textMuted,
    };

/// Nhãn trạng thái công thức (Bản nháp / Đã đăng / Đang ẩn / Đã xoá).
class RecipeStatusBadge extends StatelessWidget {
  final String status;
  const RecipeStatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = recipeStatusColor(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
      child: Text(recipeStatusLabel(status),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

/// Thẻ công thức trong danh sách: ảnh, tên, thời gian / khẩu phần / kcal và cảnh báo nguyên liệu dễ dị ứng.
class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;
  final bool showStatus;
  const RecipeCard({super.key, required this.recipe, required this.onTap, this.showStatus = false});

  @override
  Widget build(BuildContext context) {
    final n = recipe.nutrition;
    final allergens = recipe.allergenNames;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            VegImage(recipe.imageUrl, width: 88, height: 88, radius: BorderRadius.circular(12)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (showStatus && recipe.status != 'PUBLISHED') ...[
                  RecipeStatusBadge(recipe.status),
                  const SizedBox(height: 4),
                ],
                Text(recipe.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  [
                    if (recipe.totalMinutes != null && recipe.totalMinutes! > 0)
                      '${recipe.totalMinutes} phút',
                    '${recipe.servings} khẩu phần',
                    if (n != null) '${n.kcal} kcal/khẩu phần',
                    if (recipe.likeCount > 0) '${recipe.likeCount} lượt thích',
                  ].join('  •  '),
                  style: TextStyle(fontSize: 12.5, color: context.textMuted),
                ),
                if (allergens.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  const Row(children: [
                    Icon(LucideIcons.triangleAlert, size: 14, color: Colors.deepOrange),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text('Có nguyên liệu dễ gây dị ứng',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: Colors.deepOrange)),
                    ),
                  ]),
                ],
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Danh sách công thức phân trang: kéo xuống cuối thì tải thêm, kéo từ trên xuống để tải lại.
/// Dùng chung cho danh sách công khai và "công thức của tôi"; gọi `reload()` qua GlobalKey khi bộ lọc đổi.
class PagedRecipes extends StatefulWidget {
  final Future<PageData<Recipe>> Function(int page) load;
  final void Function(Recipe recipe) onTap;
  final bool showStatus;
  final String emptyText;
  final EdgeInsets padding;

  const PagedRecipes({
    super.key,
    required this.load,
    required this.onTap,
    required this.emptyText,
    this.showStatus = false,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 24),
  });

  @override
  State<PagedRecipes> createState() => PagedRecipesState();
}

class PagedRecipesState extends State<PagedRecipes> {
  final _scroll = ScrollController();
  final _items = <Recipe>[];
  int _page = 0;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  bool _failed = false;
  int _generation = 0; // bỏ kết quả của lần tải cũ khi đã bắt đầu lần tải mới

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    reload();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.hasClients && _scroll.position.extentAfter < 300) _loadMore();
  }

  Future<void> reload() async {
    final gen = ++_generation;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final p = await widget.load(0);
      if (!mounted || gen != _generation) return;
      setState(() {
        _items
          ..clear()
          ..addAll(p.items);
        _page = p.page;
        _hasMore = p.hasMore;
      });
    } catch (e) {
      if (!mounted || gen != _generation) return;
      setState(() => _failed = true);
      showErrorDialog(context, errorMessage(e), title: 'Không tải được công thức');
    } finally {
      if (mounted && gen == _generation) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    final gen = _generation;
    setState(() => _loadingMore = true);
    try {
      final p = await widget.load(_page + 1);
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_failed) return RetryView(onRetry: reload);
    return RefreshIndicator(
      onRefresh: reload,
      child: _items.isEmpty
          ? ListView(children: [
              Padding(
                padding: const EdgeInsets.all(48),
                child: Center(
                    child: Text(widget.emptyText,
                        textAlign: TextAlign.center, style: TextStyle(color: context.textMuted))),
              ),
            ])
          : ListView.separated(
              controller: _scroll,
              padding: widget.padding,
              itemCount: _items.length + (_loadingMore ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                if (i == _items.length) {
                  return const Padding(
                      padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator()));
                }
                return RecipeCard(
                    recipe: _items[i], showStatus: widget.showStatus, onTap: () => widget.onTap(_items[i]));
              },
            ),
    );
  }
}
