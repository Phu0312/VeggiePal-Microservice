import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/data/auth_models.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/health_sync.dart';
import '../data/menu_models.dart';
import '../data/menu_repository.dart';
import 'recipe_detail_screen.dart';

/// Phần "Thực đơn" của tab Thực đơn: BMI + tạo/lưu thực đơn tuần + đổi món.
/// Widget tree: ListView
///   ├─ _HealthCard   (nhập chiều cao/cân nặng -> BMI + calo khuyến nghị)
///   ├─ _PlanOptions  (mục tiêu + nguyên liệu sẵn có + nút tạo)
///   └─ _WeekGrid     (bảng Thứ 2 -> Chủ nhật x Sáng/Trưa/Tối) + nút Lưu / Thực đơn của tôi
class PlanTab extends StatefulWidget {
  const PlanTab({super.key});

  @override
  State<PlanTab> createState() => _PlanTabState();
}

class _PlanTabState extends State<PlanTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _ingredient = TextEditingController();
  final _ingredients = <String>[];
  String _goal = 'MAINTENANCE';
  HealthInfo? _health;
  WeekPlan? _plan;
  bool _busy = false;
  UserRole? _lastRole;
  int? _lastHealthVersion;

  static String _num(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : '$v';

  /// Nạp lại chỉ số mới nhất từ server khi đổi tài khoản (đăng nhập/đăng xuất)
  /// hoặc khi Hồ sơ > Lịch sử sức khỏe vừa thay đổi.
  void _syncHealth(UserRole role, int healthVersion) {
    if (_lastRole == role && _lastHealthVersion == healthVersion) return;
    final loggedOut = role == UserRole.guest;
    _lastRole = role;
    _lastHealthVersion = healthVersion;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (loggedOut) {
        // Xoá dữ liệu của tài khoản trước để không lộ sang người dùng kế tiếp.
        setState(() {
          _health = null;
          _plan = null;
          _height.clear();
          _weight.clear();
        });
        return;
      }
      try {
        final h = await context.read<MenuRepository>().latestHealth();
        if (!mounted) return;
        setState(() {
          _health = h;
          if (h != null) {
            _height.text = _num(h.heightCm);
            _weight.text = _num(h.weightKg);
          }
        });
      } catch (e) {
        if (mounted) showErrorDialog(context, errorMessage(e), title: 'Không tải được chỉ số sức khỏe');
      }
    });
  }

  Future<void> _run(Future<void> Function() job) async {
    setState(() => _busy = true);
    try {
      await job();
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _calcBmi() => _run(() async {
        final h = double.tryParse(_height.text), w = double.tryParse(_weight.text);
        if (h == null || w == null || h < 50 || w < 10) {
          showSnack(context, 'Chiều cao/cân nặng không hợp lệ');
          return;
        }
        final info = await context.read<MenuRepository>().saveHealth(h, w);
        if (mounted) setState(() => _health = info);
      });

  Future<void> _generate() => _run(() async {
        final plan = await context
            .read<MenuRepository>()
            .generate(_goal, _ingredients);
        if (mounted) setState(() => _plan = plan);
      });

  Future<void> _save() => _run(() async {
        final saved = await context.read<MenuRepository>().save(_plan!);
        if (!mounted) return;
        setState(() => _plan = saved); // có id -> đổi món được
        showSnack(context, 'Đã lưu thực đơn vào tài khoản');
      });

  Future<void> _replaceMeal(int day, String mealType) => _run(() async {
        final updated =
            await context.read<MenuRepository>().replaceMeal(_plan!.planId!, day, mealType);
        if (!mounted) return;
        setState(() => _plan = updated);
        showSnack(context,
            'Đã đổi ${mealTypeLabel(mealType).toLowerCase()} ${AppStrings.weekDays[(day - 1).clamp(0, 6)]}');
      });

  void _openMeal(DayPlan day, Meal meal) {
    final plan = _plan!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _MealSheet(
        dayLabel: AppStrings.weekDays[(day.day - 1).clamp(0, 6)],
        meal: meal,
        canReplace: plan.planId != null,
        onReplace: () {
          Navigator.pop(ctx);
          _replaceMeal(day.day, meal.mealType);
        },
        onOpenRecipe: meal.recipeId == null
            ? null
            : () {
                Navigator.pop(ctx);
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => RecipeDetailScreen(recipeId: meal.recipeId!)));
              },
      ),
    );
  }

  Future<void> _openSaved() => _run(() async {
    final repo = context.read<MenuRepository>();
    final list = await repo.savedPlans();
    if (!mounted) return;
    final picked = await showModalBottomSheet<SavedPlanInfo>(
      context: context,
      showDragHandle: true,
      builder: (_) => ListView(
        shrinkWrap: true,
        children: [
          const ListTile(title: Text('Thực đơn của tôi', style: TextStyle(fontWeight: FontWeight.w700))),
          if (list.isEmpty) const ListTile(title: Text('Chưa có thực đơn nào được lưu')),
          for (final p in list)
            ListTile(
              leading: Icon(Icons.calendar_month, color: context.cs.primary),
              title: Text('Thực đơn ${p.goal}'),
              subtitle: Text(p.createdAt),
              onTap: () => Navigator.pop(context, p),
            ),
        ],
      ),
    );
    if (picked == null) return;
    final detail = await repo.planDetail(picked.id);
    if (mounted) setState(() => _plan = detail);
  });

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final auth = context.watch<AuthController>();
    _syncHealth(auth.role, context.watch<HealthSync>().version);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _healthCard(),
        const SizedBox(height: 16),
        _options(),
        if (_plan != null) ...[
          const SectionHeader('Thực đơn tuần của bạn'),
          _WeekGrid(_plan!, onMealTap: _openMeal),
          const SizedBox(height: 8),
          if (_plan!.allergenExclusions.isNotEmpty)
            Text('Đã loại trừ nguyên liệu dị ứng: ${_plan!.allergenExclusions.join(', ')}',
                style: TextStyle(fontSize: 12, color: context.textMuted)),
          Text(
              _plan!.planId == null
                  ? 'Bấm vào một món để xem chi tiết. Lưu thực đơn để có thể đổi món.'
                  : 'Bấm vào một món để xem chi tiết hoặc đổi sang món khác.',
              style: TextStyle(fontSize: 12, color: context.textMuted)),
          const SizedBox(height: 12),
          if (auth.isLoggedIn)
            Row(children: [
              Expanded(
                  child: FilledButton.icon(
                      onPressed: (_busy || _plan!.planId != null) ? null : _save,
                      icon: Icon(_plan!.planId != null ? LucideIcons.check : LucideIcons.save),
                      label: Text(_plan!.planId != null ? 'Đã lưu' : 'Lưu thực đơn'))),
              const SizedBox(width: 12),
              Expanded(
                  child: OutlinedButton.icon(
                      onPressed: _openSaved,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Của tôi'))),
            ])
          else
            Text('Đăng nhập để lưu và quản lý thực đơn cá nhân.',
                style: TextStyle(color: context.textMuted)),
        ] else if (auth.isLoggedIn)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: OutlinedButton.icon(
                onPressed: _openSaved,
                icon: const Icon(Icons.folder_open),
                label: const Text('Thực đơn của tôi')),
          ),
      ],
    );
  }

  Widget _healthCard() {
    final h = _health;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Chỉ số cá nhân',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: _height,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Chiều cao (cm)',
                        hintText: 'Nhập chiều cao',
                        prefixIcon: Icon(LucideIcons.ruler)))),
            const SizedBox(width: 12),
            Expanded(
                child: TextField(
                    controller: _weight,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Cân nặng (kg)',
                        hintText: 'Nhập cân nặng',
                        prefixIcon: Icon(LucideIcons.weight)))),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: _busy ? null : _calcBmi, child: const Text('Tính BMI')),
          ),
          if (h != null) ...[
            const Divider(height: 28),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _stat('BMI', h.bmi.toStringAsFixed(1), h.category),
              _stat('Calo khuyến nghị', '${h.recommendedCalories}', 'kcal/ngày'),
            ]),
          ],
        ]),
      ),
    );
  }

  Widget _stat(String label, String value, String sub) => Column(children: [
        Text(label, style: TextStyle(color: context.textMuted, fontSize: 12)),
        Text(value,
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: context.cs.primary)),
        Text(sub, style: const TextStyle(fontSize: 12)),
      ]);

  Widget _options() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Tạo thực đơn tuần',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          FullWidthSegmented<String>(
            options: const [
              SegmentOption('WEIGHT_LOSS', 'Giảm cân'),
              SegmentOption('MAINTENANCE', 'Giữ cân'),
              SegmentOption('MUSCLE_GAIN', 'Tăng cơ'),
            ],
            selected: _goal,
            onChanged: (v) => setState(() => _goal = v),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: _ingredient,
                    decoration: const InputDecoration(
                        labelText: 'Nguyên liệu bạn có',
                        hintText: 'Ví dụ: nấm, đậu hũ...',
                        prefixIcon: Icon(LucideIcons.leaf)),
                    onSubmitted: (_) => _addIngredient())),
            IconButton(onPressed: _addIngredient, icon: Icon(Icons.add_circle, color: context.cs.primary)),
          ]),
          Wrap(spacing: 8, children: [
            for (final i in _ingredients)
              InputChip(label: Text(i), onDeleted: () => setState(() => _ingredients.remove(i))),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _busy ? null : _generate,
              icon: _busy
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome),
              label: const Text('Tạo thực đơn'),
            ),
          ),
        ]),
      ),
    );
  }

  void _addIngredient() {
    final t = _ingredient.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _ingredients.add(t);
      _ingredient.clear();
    });
  }
}

/// Bảng 7 ngày x 3 bữa; cuộn ngang được trên màn hình hẹp.
class _WeekGrid extends StatelessWidget {
  final WeekPlan plan;
  final void Function(DayPlan day, Meal meal)? onMealTap;
  const _WeekGrid(this.plan, {this.onMealTap});

  @override
  Widget build(BuildContext context) {
    const types = ['BREAKFAST', 'LUNCH', 'DINNER'];
    const heads = ['Ngày', 'Sáng', 'Trưa', 'Tối', 'Kcal'];
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          defaultColumnWidth: const FixedColumnWidth(150),
          columnWidths: const {0: FixedColumnWidth(72), 4: FixedColumnWidth(64)},
          border: TableBorder.symmetric(inside: BorderSide(color: Theme.of(context).dividerColor)),
          children: [
            TableRow(
              decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.3)),
              children: [for (final h in heads) _cell(h, bold: true)],
            ),
            for (final d in plan.days)
              TableRow(children: [
                _cell(AppStrings.weekDays[(d.day - 1).clamp(0, 6)], bold: true),
                for (final t in types)
                  _cell(d.meal(t)?.name ?? '-',
                      onTap: d.meal(t) == null || onMealTap == null
                          ? null
                          : () => onMealTap!(d, d.meal(t)!)),
                _cell('${d.totalCalories}'),
              ]),
          ],
        ),
      ),
    );
  }

  Widget _cell(String text, {bool bold = false, VoidCallback? onTap}) {
    final child = Padding(
      padding: const EdgeInsets.all(10),
      child: Text(text,
          style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
    );
    return onTap == null ? child : InkWell(onTap: onTap, child: child);
  }
}

/// Chi tiết một bữa ăn trong thực đơn: dinh dưỡng, nguyên liệu, mở công thức, đổi món.
class _MealSheet extends StatelessWidget {
  final String dayLabel;
  final Meal meal;
  final bool canReplace;
  final VoidCallback onReplace;
  final VoidCallback? onOpenRecipe;
  const _MealSheet({
    required this.dayLabel,
    required this.meal,
    required this.canReplace,
    required this.onReplace,
    required this.onOpenRecipe,
  });

  Widget _macro(BuildContext context, String label, String value) => Expanded(
        child: Column(children: [
          Text(value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.cs.primary)),
          Text(label, style: TextStyle(fontSize: 12, color: context.textMuted)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${mealTypeLabel(meal.mealType)} • $dayLabel',
              style: TextStyle(fontSize: 12, color: context.cs.primary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(meal.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Row(children: [
            _macro(context, 'kcal', '${meal.calories}'),
            _macro(context, 'Đạm (g)', meal.protein.toStringAsFixed(1)),
            _macro(context, 'Carb (g)', meal.carbs.toStringAsFixed(1)),
            _macro(context, 'Béo (g)', meal.fat.toStringAsFixed(1)),
          ]),
          const SizedBox(height: 16),
          const Text('Nguyên liệu', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(meal.ingredients.isEmpty ? 'Chưa có thông tin' : meal.ingredients,
              style: const TextStyle(height: 1.4)),
          const SizedBox(height: 20),
          Row(children: [
            if (onOpenRecipe != null) ...[
              Expanded(
                child: OutlinedButton.icon(
                    onPressed: onOpenRecipe,
                    icon: const Icon(LucideIcons.bookOpen),
                    label: const Text('Xem công thức')),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: FilledButton.icon(
                  onPressed: canReplace ? onReplace : null,
                  icon: const Icon(LucideIcons.refreshCw),
                  label: const Text('Đổi món')),
            ),
          ]),
          if (!canReplace)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Lưu thực đơn trước để có thể đổi món.',
                  style: TextStyle(fontSize: 12, color: context.textMuted)),
            ),
        ]),
      ),
    );
  }
}
