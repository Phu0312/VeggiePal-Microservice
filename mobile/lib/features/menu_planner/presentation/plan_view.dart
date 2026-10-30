import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../recipe/data/recipe_models.dart';
import '../../recipe/data/recipe_repository.dart';
import '../data/meal_plan_models.dart';

/// Hiển thị một thực đơn tuần: tiêu đề + yêu thích, mục tiêu, chọn thứ, dinh dưỡng và 3 bữa của ngày đó.
/// Widget tree: Column
///   ├─ _PlanHeader   (tên, mục tiêu, phiên bản, nút yêu thích / quay lại bản hiện tại)
///   ├─ _DayChips     (T2..CN, chấm cam = ngày lỡ mục tiêu calo)
///   └─ _DayCard      (tổng dinh dưỡng + cảnh báo + 3 _MealTile)
class PlanView extends StatelessWidget {
  final MealPlan plan;
  final String selectedDay;
  final ValueChanged<String> onSelectDay;
  final void Function(PlanDay day, PlanMeal meal) onMealTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onLeaveVersion;
  final VoidCallback? onRestoreVersion;
  final bool busy;

  const PlanView({
    super.key,
    required this.plan,
    required this.selectedDay,
    required this.onSelectDay,
    required this.onMealTap,
    required this.onToggleFavorite,
    this.onLeaveVersion,
    this.onRestoreVersion,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final day = plan.dayOf(selectedDay) ?? (plan.days.isEmpty ? null : plan.days.first);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _PlanHeader(
          plan: plan, busy: busy, onToggleFavorite: onToggleFavorite, onLeaveVersion: onLeaveVersion, onRestoreVersion: onRestoreVersion),
      const SizedBox(height: 12),
      if (day == null)
        const Padding(padding: EdgeInsets.all(16), child: Text('Thực đơn này chưa có dữ liệu ngày.'))
      else ...[
        _DayChips(plan: plan, selected: day.day, onSelect: onSelectDay),
        const SizedBox(height: 12),
        _DayCard(day: day, onMealTap: onMealTap),
      ],
    ]);
  }
}

class _PlanHeader extends StatelessWidget {
  final MealPlan plan;
  final bool busy;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onLeaveVersion;
  final VoidCallback? onRestoreVersion;
  const _PlanHeader(
      {required this.plan,
      required this.busy,
      required this.onToggleFavorite,
      this.onLeaveVersion,
      this.onRestoreVersion});

  @override
  Widget build(BuildContext context) {
    final target = plan.target?.lines ?? const [];
    final viewing = plan.viewingVersion != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(plan.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ),
            if (!viewing)
              IconButton(
                tooltip: plan.isFavorite ? 'Bỏ yêu thích' : 'Thêm vào yêu thích',
                onPressed: busy ? null : onToggleFavorite,
                icon: Icon(plan.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: plan.isFavorite ? Colors.redAccent : context.textMuted),
              ),
          ]),
          Text(
            [
              if (plan.goalSummary.isNotEmpty) plan.goalSummary,
              'Phiên bản ${plan.version}',
              if (plan.createdAt != null) fmtDate(plan.createdAt!.toLocal()),
            ].join(' • '),
            style: TextStyle(color: context.textMuted, fontSize: 13),
          ),
          if (viewing) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppColors.star.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(LucideIcons.history, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text('Đang xem phiên bản ${plan.viewingVersion} (chỉ đọc).',
                          style: TextStyle(color: context.cs.onSurface, fontSize: 13))),
                ]),
                Wrap(spacing: 8, children: [
                  TextButton(onPressed: onLeaveVersion, child: const Text('Về bản hiện tại')),
                  if (onRestoreVersion != null)
                    FilledButton.tonal(
                        onPressed: busy ? null : onRestoreVersion, child: const Text('Khôi phục phiên bản này')),
                ]),
              ]),
            ),
          ],
          if (target.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('Mục tiêu mỗi ngày', style: TextStyle(fontSize: 12, color: context.textMuted)),
            const SizedBox(height: 2),
            Wrap(spacing: 14, runSpacing: 2, children: [
              for (final (label, range) in target)
                Text('$label: $range', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
          ],
          if (plan.missedDays > 0) ...[
            const SizedBox(height: 8),
            Text('${plan.missedDays}/${plan.days.length} ngày chưa đạt mục tiêu calo.',
                style: const TextStyle(fontSize: 12, color: Colors.deepOrange)),
          ],
        ]),
      ),
    );
  }
}

class _DayChips extends StatelessWidget {
  final MealPlan plan;
  final String selected;
  final ValueChanged<String> onSelect;
  const _DayChips({required this.plan, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final today = todayDayKey();
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: plan.days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final d = plan.days[i];
          final isSel = d.day == selected;
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onSelect(d.day),
            child: Container(
              width: 56,
              decoration: BoxDecoration(
                color: isSel ? context.cs.primary : context.cs.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isSel ? context.cs.primary : Theme.of(context).dividerColor),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(dayShortLabel(d.day),
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: isSel ? context.cs.onPrimary : context.cs.onSurface)),
                const SizedBox(height: 2),
                Text(d.day == today ? 'Hôm nay' : '${d.totals.calories.round()}',
                    style: TextStyle(
                        fontSize: 10.5,
                        color: isSel ? context.cs.onPrimary : context.textMuted)),
                SizedBox(
                  height: 8,
                  child: d.missedTarget
                      ? const Icon(Icons.circle, size: 6, color: Colors.deepOrange)
                      : null,
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final PlanDay day;
  final void Function(PlanDay day, PlanMeal meal) onMealTap;
  const _DayCard({required this.day, required this.onMealTap});

  Widget _macro(BuildContext context, String label, double value) => Expanded(
        child: Column(children: [
          Text(value.round().toString(),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.cs.primary)),
          Text(label, style: TextStyle(fontSize: 11.5, color: context.textMuted)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final t = day.totals;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(dayLongLabel(day.day),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(children: [
            _macro(context, 'kcal', t.calories),
            _macro(context, 'Đạm (g)', t.protein),
            _macro(context, 'Tinh bột (g)', t.carbohydrate),
            _macro(context, 'Béo (g)', t.fat),
          ]),
          if (day.missedTarget && day.missedDeviations.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final d in day.missedDeviations)
              Text('Lệch mục tiêu • ${d.label}: ${d.actual.round()} ${d.unit} (cần ${d.range})',
                  style: const TextStyle(fontSize: 12.5, color: Colors.deepOrange)),
          ],
          for (final d in day.macroNotes)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Lưu ý • ${d.label}: ${d.actual.round()} ${d.unit} (mục tiêu ${d.range})',
                  style: TextStyle(fontSize: 12, color: context.textMuted)),
            ),
          const Divider(height: 28),
          for (final m in day.meals) _MealTile(meal: m, onTap: () => onMealTap(day, m)),
        ]),
      ),
    );
  }
}

class _MealTile extends StatelessWidget {
  final PlanMeal meal;
  final VoidCallback onTap;
  const _MealTile({required this.meal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: FutureBuilder<Recipe>(
          future: context.read<RecipeRepository>().cachedRecipe(meal.recipeId),
          builder: (context, snap) {
            final recipe = snap.data;
            final title = recipe?.title ??
                (snap.hasError ? 'Công thức #${meal.recipeId}' : 'Đang tải món...');
            return Row(children: [
              VegImage(recipe?.imageUrl, width: 64, height: 64, radius: BorderRadius.circular(12)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(planMealLabel(meal.mealType),
                      style: TextStyle(
                          fontSize: 11.5, fontWeight: FontWeight.w700, color: context.cs.primary)),
                  Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(
                    [
                      '${meal.nutrition.calories.round()} kcal',
                      if ((meal.servingMultiplier - 1).abs() > 0.001)
                        'khẩu phần ×${meal.servingMultiplier.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '')}',
                    ].join(' • '),
                    style: TextStyle(fontSize: 12.5, color: context.textMuted),
                  ),
                ]),
              ),
              Icon(LucideIcons.chevronRight, size: 18, color: context.textMuted),
            ]);
          },
        ),
      ),
    );
  }
}

/// Chi tiết một bữa: ảnh, dinh dưỡng, ghi chú của AI, nguyên liệu, các bước và nút đổi món.
/// [onReplace] null = thực đơn đang ở chế độ chỉ đọc (xem phiên bản cũ).
Future<void> showMealSheet(
  BuildContext context, {
  required PlanDay day,
  required PlanMeal meal,
  required VoidCallback? onReplace,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (ctx, scroll) => _MealSheet(
        scroll: scroll,
        day: day,
        meal: meal,
        onReplace: onReplace == null
            ? null
            : () {
                Navigator.pop(ctx);
                onReplace();
              },
      ),
    ),
  );
}

class _MealSheet extends StatelessWidget {
  final ScrollController scroll;
  final PlanDay day;
  final PlanMeal meal;
  final VoidCallback? onReplace;
  const _MealSheet(
      {required this.scroll, required this.day, required this.meal, required this.onReplace});

  Widget _macro(BuildContext context, String label, String value) => Expanded(
        child: Column(children: [
          Text(value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.cs.primary)),
          Text(label, style: TextStyle(fontSize: 12, color: context.textMuted)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final n = meal.nutrition;
    return FutureBuilder<Recipe>(
      future: context.read<RecipeRepository>().cachedRecipe(meal.recipeId),
      builder: (context, snap) {
        final r = snap.data;
        return ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Text('${planMealLabel(meal.mealType)} • ${dayLongLabel(day.day)}',
                style: TextStyle(fontSize: 12, color: context.cs.primary, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(r?.title ?? (snap.hasError ? 'Công thức #${meal.recipeId}' : 'Đang tải món...'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            if (r?.imageUrl != null) ...[
              const SizedBox(height: 12),
              VegImage(r!.imageUrl, width: double.infinity, height: 180, radius: BorderRadius.circular(16)),
            ],
            const SizedBox(height: 16),
            Row(children: [
              _macro(context, 'kcal', '${n.calories.round()}'),
              _macro(context, 'Đạm (g)', n.protein.toStringAsFixed(1)),
              _macro(context, 'Tinh bột (g)', n.carbohydrate.toStringAsFixed(1)),
              _macro(context, 'Béo (g)', n.fat.toStringAsFixed(1)),
            ]),
            if (meal.note.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(meal.note, style: TextStyle(fontStyle: FontStyle.italic, color: context.textMuted)),
            ],
            if (r?.totalMinutes != null || r?.servings != null) ...[
              const SizedBox(height: 12),
              Text(
                [
                  if (r?.totalMinutes != null) '${r!.totalMinutes} phút',
                  if (r?.servings != null) '${r!.servings} khẩu phần gốc',
                ].join(' • '),
                style: TextStyle(color: context.textMuted),
              ),
            ],
            if (snap.hasError) ...[
              const SizedBox(height: 12),
              Text('Không tải được chi tiết công thức. Kiểm tra mạng rồi mở lại.',
                  style: TextStyle(color: context.textMuted)),
            ],
            if (r != null && r.ingredients.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Nguyên liệu', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              for (final i in r.ingredients)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('• ${i.name}${i.amountText.isEmpty ? '' : ' - ${i.amountText}'}'),
                ),
            ],
            if (r != null && r.steps.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Cách làm', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              for (var i = 0; i < r.steps.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text('${i + 1}. ${r.steps[i].instruction}', style: const TextStyle(height: 1.35)),
                ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onReplace,
              icon: const Icon(LucideIcons.refreshCw),
              label: const Text('Đổi món'),
            ),
            if (onReplace == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Phiên bản cũ chỉ để xem, không đổi món được.',
                    style: TextStyle(fontSize: 12, color: context.textMuted)),
              ),
          ],
        );
      },
    );
  }
}
