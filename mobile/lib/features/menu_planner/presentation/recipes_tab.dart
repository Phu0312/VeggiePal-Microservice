import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../profile/data/profile_models.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/presentation/allergen_chips.dart';
import '../data/meal_models.dart';
import '../data/meal_repository.dart';
import '../data/menu_models.dart';
import 'recipe_detail_screen.dart';

/// Phần "Công thức": danh sách công thức món chay (công khai) với tìm kiếm, lọc theo bữa ăn
/// và loại trừ NHIỀU nguyên liệu dị ứng cùng lúc. API: GET /nutrition/recipes?keyword=.
/// Tham số excludeAllergen của BE chỉ nhận 1 mã nên việc loại trừ được lọc ở máy theo
/// allergenCodes của từng công thức (chính xác theo mã, không so khớp chuỗi con).
class RecipesTab extends StatefulWidget {
  const RecipesTab({super.key});

  @override
  State<RecipesTab> createState() => _RecipesTabState();
}

class _RecipesTabState extends State<RecipesTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static const _mealFilters = {
    null: 'Tất cả',
    'BREAKFAST': 'Sáng',
    'LUNCH': 'Trưa',
    'DINNER': 'Tối',
  };

  final _search = TextEditingController();
  List<RecipeItem> _all = [];
  List<Allergen> _allergens = [];
  String _keyword = '';
  final _excludedIds = <int>{}; // các chất dị ứng cần loại trừ
  String? _mealType;
  bool _loading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
    _loadAllergens();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final r = await context.read<MealRepository>().recipes(keyword: _keyword);
      if (mounted) setState(() => _all = r);
    } catch (e) {
      if (mounted) {
        setState(() => _loadFailed = true);
        showErrorDialog(context, errorMessage(e), title: 'Không tải được công thức');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadAllergens() async {
    try {
      final a = await context.read<ProfileRepository>().allergens();
      if (mounted) setState(() => _allergens = a);
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e), title: 'Không tải được danh sách dị ứng');
    }
  }

  Future<void> _pickAllergens() async {
    final picked = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AllergenFilterSheet(catalog: _allergens, initial: _excludedIds),
    );
    if (picked == null) return;
    setState(() {
      _excludedIds
        ..clear()
        ..addAll(picked);
    });
  }

  List<RecipeItem> get _visible {
    final excludedCodes = {
      for (final a in _allergens)
        if (_excludedIds.contains(a.id)) a.code,
    };
    return _all.where((r) {
      if (_mealType != null &&
          r.mealType.toUpperCase() != _mealType &&
          r.mealType.toUpperCase() != 'ANY') {
        return false;
      }
      return !r.allergenCodes.any(excludedCodes.contains);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final excluded = _allergens.where((a) => _excludedIds.contains(a.id)).toList();
    final items = _visible;

    return Column(children: [
      VegSearchBar(
        controller: _search,
        hint: 'Tìm công thức, nguyên liệu...',
        onSubmitted: (v) {
          _keyword = v.trim();
          _load();
        },
      ),
      SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          children: [
            for (final e in _mealFilters.entries) ...[
              ChoiceChip(
                label: Text(e.value),
                selected: _mealType == e.key,
                onSelected: (_) => setState(() => _mealType = e.key),
              ),
              const SizedBox(width: 8),
            ],
            ActionChip(
              avatar: const Icon(LucideIcons.shieldAlert, size: 16),
              label: Text(excluded.isEmpty ? 'Loại trừ dị ứng' : 'Loại trừ dị ứng (${excluded.length})'),
              onPressed: _allergens.isEmpty ? null : _pickAllergens,
            ),
            for (final a in excluded) ...[
              const SizedBox(width: 8),
              InputChip(
                label: Text('Không ${a.name}'),
                onDeleted: () => setState(() => _excludedIds.remove(a.id)),
              ),
            ],
          ],
        ),
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadFailed
                ? RetryView(onRetry: _load)
                : items.isEmpty
                    ? Center(
                        child: Text('Không có công thức phù hợp', style: TextStyle(color: context.textMuted)))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _RecipeCard(items[i]),
                        ),
                      ),
      ),
    ]);
  }
}

class _RecipeCard extends StatelessWidget {
  final RecipeItem r;
  const _RecipeCard(this.r);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipeId: r.id))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                  color: context.cs.primaryContainer, borderRadius: BorderRadius.circular(14)),
              child: Icon(LucideIcons.chefHat, color: context.cs.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text('${mealTypeLabel(r.mealType)}  •  ${r.calories.toStringAsFixed(0)} kcal  •  Đạm ${r.protein.toStringAsFixed(0)}g',
                    style: TextStyle(fontSize: 12, color: context.textMuted)),
                const SizedBox(height: 4),
                Text(r.ingredients,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: context.textMuted)),
              ]),
            ),
            Icon(LucideIcons.chevronRight, size: 20, color: context.textMuted),
          ]),
        ),
      ),
    );
  }
}

/// Bảng chọn nhiều chất dị ứng (theo nhóm) để loại khỏi danh sách công thức.
class _AllergenFilterSheet extends StatefulWidget {
  final List<Allergen> catalog;
  final Set<int> initial;
  const _AllergenFilterSheet({required this.catalog, required this.initial});

  @override
  State<_AllergenFilterSheet> createState() => _AllergenFilterSheetState();
}

class _AllergenFilterSheetState extends State<_AllergenFilterSheet> {
  late final Set<int> _selected = {...widget.initial};
  bool _loadingMine = false;

  /// Chọn sẵn các chất dị ứng đã lưu trong hồ sơ của tôi (GET /nutrition/me/allergies).
  Future<void> _useMine() async {
    setState(() => _loadingMine = true);
    try {
      final mine = await context.read<ProfileRepository>().myAllergies();
      if (mounted) setState(() => _selected.addAll(mine.map((a) => a.id)));
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e), title: 'Không tải được dị ứng của bạn');
    } finally {
      if (mounted) setState(() => _loadingMine = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.watch<AuthController>().isLoggedIn;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (_, scroll) => Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 12, 0),
          child: Row(children: [
            const Expanded(
              child: Text('Loại trừ nguyên liệu dị ứng',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            if (loggedIn)
              TextButton.icon(
                onPressed: _loadingMine ? null : _useMine,
                icon: const Icon(LucideIcons.userCheck, size: 18),
                label: const Text('Của tôi'),
              ),
          ]),
        ),
        Expanded(
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            children: [
              AllergenGroupedChips(
                catalog: widget.catalog,
                selected: _selected,
                onChanged: (a, v) => setState(() => v ? _selected.add(a.id) : _selected.remove(a.id)),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _selected.isEmpty ? null : () => setState(_selected.clear),
                  child: const Text('Bỏ chọn hết'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  child: Text('Áp dụng (${_selected.length})'),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
