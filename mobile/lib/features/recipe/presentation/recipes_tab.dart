import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/common_widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../blog/data/blog_models.dart' show PageData;
import '../../auth/presentation/login_screen.dart';
import '../data/recipe_models.dart';
import '../data/recipe_repository.dart';
import 'my_recipes_screen.dart';
import 'recipe_detail_screen.dart';
import 'recipe_form_screen.dart';
import 'recipe_widgets.dart';

/// Phần "Công thức" của tab Thực đơn: công thức đã đăng (công khai) với tìm kiếm theo từ khoá và phân trang.
/// API: GET /recipes?keyword=&page=&size= (mới nhất) hoặc GET /recipes/popular (phổ biến, không có từ khoá). Chip "Không dị ứng" lọc ở máy: bỏ công thức có nguyên liệu bị đánh dấu dễ gây dị ứng. Thành viên có thêm lối vào "Của tôi" và "Tạo công thức".
class RecipesTab extends StatefulWidget {
  /// `true`: hiện công thức thành lưới 2 cột (tab "Công thức" ở Trang chủ); mặc định là danh sách một cột.
  final bool grid;
  const RecipesTab({super.key, this.grid = false});

  @override
  State<RecipesTab> createState() => _RecipesTabState();
}

class _RecipesTabState extends State<RecipesTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _search = TextEditingController();
  final _list = GlobalKey<PagedRecipesState>();
  String _keyword = '';
  bool _noAllergen = false; // chỉ giữ công thức không có nguyên liệu dễ gây dị ứng (lọc ở máy, BE chưa có tham số này)
  bool _popular = false; // true: GET /recipes/popular (nhiều lượt thích nhất), chỉ khi không tìm theo từ khoá

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _submit(String text) {
    _keyword = text.trim();
    // /recipes/popular không hỗ trợ từ khoá nên tìm kiếm luôn sắp theo mới nhất.
    if (_keyword.isNotEmpty) _popular = false;
    setState(() {});
    _list.currentState?.reload();
  }

  void _setNoAllergen(bool value) {
    setState(() => _noAllergen = value);
    _list.currentState?.reload();
  }

  Future<PageData<Recipe>> _fetch(RecipeRepository repo, int page) =>
      _popular && _keyword.isEmpty ? repo.popular(page: page) : repo.published(keyword: _keyword, page: page);

  /// Tải một trang; khi đang lọc "không dị ứng" thì bỏ công thức có nguyên liệu dễ gây dị ứng và đọc tiếp các trang sau
  /// cho tới khi đủ vài món (hoặc hết), để danh sách không bị trống rồi không cuộn để tải thêm được.
  Future<PageData<Recipe>> _load(RecipeRepository repo, int page) async {
    var p = await _fetch(repo, page);
    if (!_noAllergen) return p;
    final items = [...p.items.where((r) => r.allergenNames.isEmpty)];
    for (var extra = 0; items.length < _minFiltered && p.hasMore && extra < _maxExtraPages; extra++) {
      p = await _fetch(repo, p.page + 1);
      items.addAll(p.items.where((r) => r.allergenNames.isEmpty));
    }
    return PageData(items, p.page, p.totalPages, p.totalElements);
  }

  static const _minFiltered = 6;
  static const _maxExtraPages = 4;

  void _setPopular(bool value) {
    if (_popular == value) return;
    setState(() => _popular = value);
    _list.currentState?.reload();
  }

  /// Chức năng của thành viên: khách được đưa tới màn đăng nhập.
  bool _requireLogin() {
    if (context.read<AuthController>().isLoggedIn) return true;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
    return false;
  }

  Future<void> _create() async {
    if (!_requireLogin()) return;
    final saved = await Navigator.of(context)
        .push<Recipe>(MaterialPageRoute(builder: (_) => const RecipeFormScreen()));
    if (saved != null && mounted) {
      showSnack(context, 'Đã lưu công thức vào mục "Của tôi"');
      _list.currentState?.reload();
    }
  }

  Future<void> _openMine() async {
    if (!_requireLogin()) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyRecipesScreen()));
    // Công thức vừa đăng ở "Của tôi" phải xuất hiện ở đây.
    if (mounted) _list.currentState?.reload();
  }

  Future<void> _open(Recipe r) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipeId: r.id, initial: r)));
    if (mounted) _list.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final repo = context.read<RecipeRepository>();
    return Column(children: [
      VegSearchBar(controller: _search, hint: 'Tìm công thức, nguyên liệu...', onSubmitted: _submit),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        child: Row(children: [
          Expanded(
              child: OutlinedButton.icon(
                  onPressed: _openMine,
                  icon: const Icon(LucideIcons.bookMarked),
                  label: const Text('Của tôi'))),
          const SizedBox(width: 12),
          Expanded(
              child: FilledButton.icon(
                  onPressed: _create,
                  icon: const Icon(LucideIcons.plus),
                  label: const Text('Tạo công thức'))),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Wrap(spacing: 8, runSpacing: 4, children: [
          ChoiceChip(label: const Text('Mới nhất'), selected: !_popular, onSelected: (_) => _setPopular(false)),
          ChoiceChip(
              label: const Text('Phổ biến'),
              selected: _popular,
              onSelected: _keyword.isNotEmpty ? null : (_) => _setPopular(true)),
          FilterChip(
              avatar: const Icon(LucideIcons.shieldCheck, size: 16),
              label: const Text('Không dị ứng'),
              selected: _noAllergen,
              onSelected: _setNoAllergen),
        ]),
      ),
      Expanded(
        child: PagedRecipes(
          key: _list,
          load: (page) => _load(repo, page),
          onTap: _open,
          grid: widget.grid,
          padding: widget.grid ? const EdgeInsets.fromLTRB(16, 8, 16, 100) : const EdgeInsets.fromLTRB(16, 8, 16, 24),
          emptyText: _keyword.isEmpty
              ? 'Chưa có công thức nào được đăng.'
              : 'Không tìm thấy công thức nào cho "$_keyword".',
        ),
      ),
    ]);
  }
}
