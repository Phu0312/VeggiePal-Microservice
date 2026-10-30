import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../menu_planner/data/meal_plan_models.dart';
import '../../profile/presentation/edit_profile_screen.dart';
import '../../profile/presentation/health_history_screen.dart';
import '../data/diary_models.dart';
import '../data/diary_repository.dart';
import 'add_food_sheet.dart';

/// Nhật ký dinh dưỡng theo ngày (GET /nutrition/me/daily-summary): calo và macro so với mục tiêu, nước uống,
/// vận động và các món đã ăn theo từng bữa. Chọn ngày bằng mũi tên hoặc lịch (không quá hôm nay).
/// Mọi thay đổi gọi BE rồi tải lại tổng kết của ngày đó để số liệu luôn khớp với server.
/// Mục tiêu calo do BE tính theo hồ sơ và mục tiêu người dùng chọn (giảm cân / duy trì / tăng cân, được nhớ lại ở lần
/// mở sau). Hồ sơ chưa đủ (BE trả 2013) thì màn hình hướng dẫn bổ sung thay vì chỉ báo lỗi.
class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

DateTime _today() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

class _DiaryScreenState extends State<DiaryScreen> {
  DateTime _date = _today();
  DailySummary? _summary;
  bool _loading = true;
  bool _failed = false;
  bool _needsProfile = false; // BE trả 2013 / 2014: không tính được mục tiêu calo
  bool _underage = false; // 2014: dưới 18 tuổi, bổ sung chiều cao/cân nặng cũng không giúp được
  String _needsProfileMessage = '';
  PlanGoal _goal = PlanGoal.maintain;
  int _generation = 0; // bỏ kết quả của lần tải cũ khi đã đổi ngày hoặc mục tiêu

  static const _goalKey = 'diary_goal_type';

  @override
  void initState() {
    super.initState();
    _restoreGoalThenLoad();
  }

  /// Nhớ mục tiêu đã chọn ở lần trước. Không đọc được bộ nhớ cục bộ thì dùng "Duy trì".
  Future<void> _restoreGoalThenLoad() async {
    try {
      final saved = (await SharedPreferences.getInstance()).getString(_goalKey);
      final goal = PlanGoal.all.where((g) => g.value == saved);
      if (goal.isNotEmpty && mounted) _goal = goal.first;
    } catch (_) {}
    if (mounted) await _load();
  }

  Future<void> _setGoal(PlanGoal goal) async {
    if (goal.value == _goal.value) return;
    setState(() {
      _goal = goal;
      _summary = null;
    });
    try {
      (await SharedPreferences.getInstance()).setString(_goalKey, goal.value);
    } catch (_) {}
    if (mounted) _load();
  }

  Future<void> _load({bool silent = false}) async {
    final gen = ++_generation;
    if (!silent) {
      setState(() {
        _loading = true;
        _failed = false;
        _needsProfile = false;
        _underage = false;
      });
    }
    try {
      final s = await context.read<DiaryRepository>().summary(_date, goalType: _goal.value);
      if (mounted && gen == _generation) {
        setState(() {
          _summary = s;
          _needsProfile = false;
        });
      }
    } catch (e) {
      if (mounted && gen == _generation) {
        if (e is ApiException && (e.code == 2013 || e.code == 2014)) {
          // Không phải sự cố: người dùng cần bổ sung hồ sơ (2013) hoặc chưa đủ tuổi (2014). Màn hình hiện hướng dẫn
          // thay vì popup lỗi.
          setState(() {
            _needsProfile = true;
            _underage = e.code == 2014;
            _needsProfileMessage = e.message;
            _summary = null;
          });
        } else {
          setState(() => _failed = _summary == null);
          showErrorDialog(context, errorMessage(e), title: 'Không tải được nhật ký');
        }
      }
    } finally {
      if (mounted && gen == _generation) setState(() => _loading = false);
    }
  }

  void _setDate(DateTime d) {
    setState(() {
      _date = d;
      _summary = null;
    });
    _load();
  }

  bool get _isToday => _date == _today();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
        context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: _today());
    if (picked != null && mounted) _setDate(DateTime(picked.year, picked.month, picked.day));
  }

  Future<void> _run(Future<void> Function() job, String errorTitle) async {
    try {
      await job();
      if (mounted) await _load(silent: true);
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e), title: errorTitle);
    }
  }

  Future<void> _openAndReload(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) _load();
  }

  Future<void> _addFood([MealSlot? meal]) async {
    final saved = await showAddFoodSheet(context, date: _date, meal: meal);
    if (saved && mounted) {
      showSnack(context, 'Đã ghi món vào nhật ký');
      await _load(silent: true);
    }
  }

  Future<void> _deleteFood(FoodEntry e) => _run(() async {
        await context.read<DiaryRepository>().deleteFood(e.id);
        if (mounted) showSnack(context, 'Đã xoá "${e.name}"');
      }, 'Không xoá được món');

  Future<void> _addWater(int ml) =>
      _run(() => context.read<DiaryRepository>().addWater(_date, ml), 'Không ghi được lượng nước');

  Future<void> _customWater() async {
    final c = TextEditingController();
    final ml = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm lượng nước'),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Lượng nước', suffixText: 'ml', hintText: '1 - 5000'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
              onPressed: () {
                final v = int.tryParse(c.text.trim());
                if (v != null && v >= 1 && v <= 5000) Navigator.pop(ctx, v);
              },
              child: const Text('Thêm')),
        ],
      ),
    );
    c.dispose();
    if (ml != null && mounted) await _addWater(ml);
  }

  Future<void> _editActivity() async {
    final a = _summary?.activity ?? const DailyActivity();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _ActivitySheet(date: _date, initial: a),
      ),
    );
    if (saved == true && mounted) {
      showSnack(context, 'Đã cập nhật vận động và nước uống');
      await _load(silent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _summary;
    return Scaffold(
      appBar: AppBar(title: const Text('Nhật ký dinh dưỡng')),
      floatingActionButton: _needsProfile
          ? null
          : FloatingActionButton.extended(
              heroTag: 'diary-add',
              onPressed: () => _addFood(),
              icon: const Icon(LucideIcons.plus),
              label: const Text('Ghi món'),
            ),
      body: Column(children: [
        _DateBar(
          date: _date,
          isToday: _isToday,
          onPrev: () => _setDate(_date.subtract(const Duration(days: 1))),
          onNext: _isToday ? null : () => _setDate(_date.add(const Duration(days: 1))),
          onPick: _pickDate,
        ),
        if (!_needsProfile) _GoalBar(goal: _goal, onChanged: _setGoal),
        Expanded(
          child: _needsProfile
              ? _ProfileIncompleteView(
                  message: _needsProfileMessage,
                  underage: _underage,
                  onEditProfile: () => _openAndReload(const EditProfileScreen(
                      highlightFields: {'dateOfBirth', 'gender', 'activityLevel'})),
                  onEditHealth: () => _openAndReload(const HealthHistoryScreen()),
                )
              : s == null
              ? (_loading
                  ? const Center(child: CircularProgressIndicator())
                  : RetryView(message: _failed ? 'Không tải được nhật ký.' : 'Không có dữ liệu.', onRetry: _load))
              : RefreshIndicator(
                  onRefresh: () => _load(silent: true),
                  child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 96), children: [
                    _CalorieCard(s),
                    const SizedBox(height: 12),
                    _WaterCard(s, onAdd: _addWater, onCustom: _customWater),
                    const SizedBox(height: 12),
                    _ActivityCard(s.activity, onEdit: _editActivity),
                    const SizedBox(height: 12),
                    for (final m in MealSlot.values)
                      _MealSection(
                          meal: m,
                          summary: s,
                          onAdd: () => _addFood(m),
                          onDelete: _deleteFood),
                  ]),
                ),
        ),
      ]),
    );
  }
}

/// Chọn mục tiêu để BE tính calo mỗi ngày (cùng ba mục tiêu với tab Thực đơn).
class _GoalBar extends StatelessWidget {
  final PlanGoal goal;
  final ValueChanged<PlanGoal> onChanged;
  const _GoalBar({required this.goal, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        child: Column(children: [
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [for (final g in PlanGoal.all) ButtonSegment(value: g.value, label: Text(g.label))],
              selected: {goal.value},
              onSelectionChanged: (v) => onChanged(PlanGoal.all.firstWhere((g) => g.value == v.first)),
            ),
          ),
          const SizedBox(height: 4),
          Text('Mục tiêu: ${goal.hint}', style: TextStyle(fontSize: 12, color: context.textMuted)),
        ]),
      );
}

/// Hiện khi BE chưa tính được mục tiêu calo: hồ sơ chưa đủ (mã 2013) hoặc người dùng dưới 18 tuổi (mã 2014).
/// Người dưới 18 tuổi chỉ được sửa hồ sơ (phòng khi nhập sai ngày sinh), không có nút nhập chiều cao, cân nặng.
class _ProfileIncompleteView extends StatelessWidget {
  final String message;
  final bool underage;
  final VoidCallback onEditProfile;
  final VoidCallback onEditHealth;
  const _ProfileIncompleteView(
      {required this.message, required this.underage, required this.onEditProfile, required this.onEditHealth});

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(LucideIcons.userPen, size: 48, color: context.cs.primary),
            const SizedBox(height: 12),
            Text(underage ? 'Chưa đủ tuổi để tính mục tiêu' : 'Cần bổ sung hồ sơ',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: context.textMuted)),
            if (underage) ...[
              const SizedBox(height: 8),
              Text('Nếu bạn đã nhập sai ngày sinh, hãy sửa lại trong hồ sơ.',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: context.textMuted)),
            ],
            const SizedBox(height: 20),
            if (!underage) ...[
              SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                      onPressed: onEditHealth,
                      icon: const Icon(LucideIcons.ruler),
                      label: const Text('Nhập chiều cao, cân nặng'))),
              const SizedBox(height: 8),
            ],
            SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                    onPressed: onEditProfile,
                    icon: const Icon(LucideIcons.userPen),
                    label: const Text('Cập nhật hồ sơ'))),
          ]),
        ),
      );
}

class _DateBar extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final VoidCallback onPick;
  const _DateBar({required this.date, required this.isToday, required this.onPrev, required this.onNext, required this.onPick});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(children: [
          IconButton(tooltip: 'Ngày trước', onPressed: onPrev, icon: const Icon(LucideIcons.chevronLeft)),
          Expanded(
            child: TextButton.icon(
              onPressed: onPick,
              icon: const Icon(LucideIcons.calendarDays, size: 18),
              label: Text(isToday ? 'Hôm nay • ${fmtDate(date)}' : fmtDate(date)),
            ),
          ),
          IconButton(tooltip: 'Ngày sau', onPressed: onNext, icon: const Icon(LucideIcons.chevronRight)),
        ]),
      );
}

class _CalorieCard extends StatelessWidget {
  final DailySummary s;
  const _CalorieCard(this.s);

  Widget _macro(BuildContext context, String label, double value, double target) => Expanded(
        child: Column(children: [
          Text('${value.toStringAsFixed(0)}g', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text(label, style: TextStyle(fontSize: 12, color: context.textMuted)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(value: target <= 0 ? 0 : (value / target).clamp(0.0, 1.0), minHeight: 5),
          ),
          Text('/ ${target.toStringAsFixed(0)}g', style: TextStyle(fontSize: 11, color: context.textMuted)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final over = s.overTarget;
    final color = over ? context.cs.error : context.cs.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${s.consumedCalories}',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: color)),
            Text(' / ${s.targetCalories} kcal', style: TextStyle(color: context.textMuted)),
            const Spacer(),
            Text(over ? 'Vượt ${s.consumedCalories - s.targetCalories} kcal' : 'Còn ${s.remainingCalories} kcal',
                style: TextStyle(fontWeight: FontWeight.w700, color: color)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(value: s.calorieRatio, minHeight: 10, color: color),
          ),
          if (s.activity.caloriesBurned > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Đã đốt ${s.activity.caloriesBurned} kcal nhờ vận động',
                    style: TextStyle(fontSize: 12.5, color: context.textMuted)),
              ),
            ),
          const SizedBox(height: 14),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _macro(context, 'Đạm', s.protein, s.targetProtein),
            const SizedBox(width: 12),
            _macro(context, 'Tinh bột', s.carbs, s.targetCarbs),
            const SizedBox(width: 12),
            _macro(context, 'Chất béo', s.fat, s.targetFat),
          ]),
          if (s.fiber > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Chất xơ: ${s.fiber.toStringAsFixed(1)}g', style: TextStyle(fontSize: 12.5, color: context.textMuted)),
            ),
        ]),
      ),
    );
  }
}

class _WaterCard extends StatelessWidget {
  final DailySummary s;
  final Future<void> Function(int ml) onAdd;
  final VoidCallback onCustom;
  const _WaterCard(this.s, {required this.onAdd, required this.onCustom});

  @override
  Widget build(BuildContext context) {
    final a = s.activity;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(LucideIcons.droplets, color: context.cs.primary),
            const SizedBox(width: 8),
            const Text('Nước uống', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const Spacer(),
            Text('${a.waterMl} / ${a.waterTargetMl} ml', style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: s.waterRatio, minHeight: 8),
          ),
          const SizedBox(height: 4),
          Text('${a.waterGlasses} ly', style: TextStyle(fontSize: 12.5, color: context.textMuted)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            OutlinedButton(onPressed: () => onAdd(250), child: const Text('+250 ml')),
            OutlinedButton(onPressed: () => onAdd(500), child: const Text('+500 ml')),
            OutlinedButton(onPressed: onCustom, child: const Text('Khác...')),
          ]),
        ]),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final DailyActivity a;
  final VoidCallback onEdit;
  const _ActivityCard(this.a, {required this.onEdit});

  Widget _stat(BuildContext context, IconData icon, String value, String label) => Expanded(
        child: Column(children: [
          Icon(icon, size: 20, color: context.cs.primary),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text(label, style: TextStyle(fontSize: 12, color: context.textMuted)),
        ]),
      );

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('Vận động', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const Spacer(),
                Icon(LucideIcons.pencil, size: 18, color: context.textMuted),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                _stat(context, LucideIcons.timer, '${a.exerciseMinutes}', 'phút tập'),
                _stat(context, LucideIcons.footprints, '${a.steps}', 'bước chân'),
                _stat(context, LucideIcons.flame, '${a.caloriesBurned}', 'kcal đốt'),
              ]),
              if ((a.note ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(a.note!, style: TextStyle(color: context.textMuted)),
                ),
            ]),
          ),
        ),
      );
}

class _MealSection extends StatelessWidget {
  final MealSlot meal;
  final DailySummary summary;
  final VoidCallback onAdd;
  final Future<void> Function(FoodEntry) onDelete;
  const _MealSection({required this.meal, required this.summary, required this.onAdd, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final entries = summary.entriesOf(meal);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text('${meal.label} • ${summary.caloriesOf(meal)} kcal',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
            IconButton(tooltip: 'Thêm món vào ${meal.label.toLowerCase()}', onPressed: onAdd, icon: const Icon(LucideIcons.circlePlus)),
          ]),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('Chưa ghi món nào.', style: TextStyle(color: context.textMuted)),
            ),
          for (final e in entries)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(e.name, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                  '${e.calories} kcal • đạm ${e.protein.toStringAsFixed(0)}g • bột ${e.carbs.toStringAsFixed(0)}g • béo ${e.fat.toStringAsFixed(0)}g'),
              trailing: IconButton(
                tooltip: 'Xoá ${e.name}',
                icon: const Icon(LucideIcons.trash2, size: 18),
                onPressed: () => onDelete(e),
              ),
            ),
        ]),
      ),
    );
  }
}

/// Sửa vận động và mục tiêu nước của một ngày (PUT /nutrition/me/daily-activity).
class _ActivitySheet extends StatefulWidget {
  final DateTime date;
  final DailyActivity initial;
  const _ActivitySheet({required this.date, required this.initial});

  @override
  State<_ActivitySheet> createState() => _ActivitySheetState();
}

class _ActivitySheetState extends State<_ActivitySheet> {
  final _form = GlobalKey<FormState>();
  late final _minutes = TextEditingController(text: '${widget.initial.exerciseMinutes}');
  late final _steps = TextEditingController(text: '${widget.initial.steps}');
  late final _burned = TextEditingController(text: '${widget.initial.caloriesBurned}');
  late final _target = TextEditingController(text: '${widget.initial.waterTargetMl}');
  late final _note = TextEditingController(text: widget.initial.note ?? '');
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_minutes, _steps, _burned, _target, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _nonNegative(String? v) => int.tryParse((v ?? '').trim()) == null || int.parse(v!.trim()) < 0 ? 'Nhập số nguyên từ 0' : null;

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final repo = context.read<DiaryRepository>();
    setState(() => _busy = true);
    try {
      await repo.saveActivity(
        widget.date,
        exerciseMinutes: int.parse(_minutes.text.trim()),
        steps: int.parse(_steps.text.trim()),
        caloriesBurned: int.parse(_burned.text.trim()),
        waterTargetMl: int.parse(_target.text.trim()),
        note: _note.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showErrorDialog(context, errorMessage(e), title: 'Không lưu được');
      }
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Form(
            key: _form,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Vận động • ${fmtDate(widget.date)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _minutes,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Thời gian tập', suffixText: 'phút'),
                  validator: _nonNegative),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _steps,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Số bước chân'),
                  validator: _nonNegative),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _burned,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Năng lượng đốt', suffixText: 'kcal'),
                  validator: _nonNegative),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _target,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Mục tiêu nước uống', suffixText: 'ml'),
                  validator: (v) => (int.tryParse((v ?? '').trim()) ?? 0) < 1 ? 'Nhập số nguyên từ 1' : null),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _note,
                  maxLength: 200,
                  decoration: const InputDecoration(labelText: 'Ghi chú (không bắt buộc)', counterText: '')),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Lưu'),
              ),
            ]),
          ),
        ),
      );
}
