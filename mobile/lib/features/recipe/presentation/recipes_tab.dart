import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/common_widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/login_screen.dart';
import '../data/recipe_models.dart';
import '../data/recipe_repository.dart';
import 'my_recipes_screen.dart';
import 'recipe_detail_screen.dart';
import 'recipe_form_screen.dart';
import 'recipe_widgets.dart';

/// Phần "Công thức" của tab Thực đơn: công thức đã đăng (công khai) với tìm kiếm theo từ khoá và phân trang.
/// API: GET /recipes?keyword=&page=&size= (mới nhất) hoặc GET /recipes/popular (phổ biến, không có từ khoá). Thành viên có thêm lối vào "Của tôi" và "Tạo công thức".
class RecipesTab extends StatefulWidget {
  const RecipesTab({super.key});

  @override
  State<RecipesTab> createState() => _RecipesTabState();
}

class _RecipesTabState extends State<RecipesTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _search = TextEditingController();
  final _list = GlobalKey<PagedRecipesState>();
  String _keyword = '';
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
        child: Row(children: [
          ChoiceChip(label: const Text('Mới nhất'), selected: !_popular, onSelected: (_) => _setPopular(false)),
          const SizedBox(width: 8),
          ChoiceChip(
              label: const Text('Phổ biến'),
              selected: _popular,
              onSelected: _keyword.isNotEmpty ? null : (_) => _setPopular(true)),
        ]),
      ),
      Expanded(
        child: PagedRecipes(
          key: _list,
          load: (page) => _popular && _keyword.isEmpty
              ? repo.popular(page: page)
              : repo.published(keyword: _keyword, page: page),
          onTap: _open,
          emptyText: _keyword.isEmpty
              ? 'Chưa có công thức nào được đăng.'
              : 'Không tìm thấy công thức nào cho "$_keyword".',
        ),
      ),
    ]);
  }
}
