import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/data/auth_models.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../ingredient/data/pantry_controller.dart';
import '../../payment/data/payment_models.dart';
import '../../payment/data/subscription_controller.dart';
import '../../payment/presentation/upgrade_dialog.dart';
import '../../profile/presentation/edit_profile_screen.dart';
import '../data/health_sync.dart';
import '../data/meal_plan_models.dart';
import '../data/meal_plan_repository.dart';
import '../data/menu_models.dart';
import '../data/menu_repository.dart';
import 'plan_sheets.dart';
import 'plan_view.dart';

/// Phần "Thực đơn" của tab Thực đơn: BMI + tạo thực đơn tuần bằng AI + xem/đổi món/yêu thích/phiên bản.
/// Widget tree: ListView
///   ├─ _healthCard   (nhập chiều cao/cân nặng -> BMI)
///   ├─ _options      (tên + mục tiêu + calo mục tiêu backend tính + nguyên liệu sẵn có + nút tạo)
///   └─ PlanView      (thực đơn đang xem) + hàng nút Của tôi / Yêu thích / Phiên bản
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
  final _name = TextEditingController(text: _defaultName());
  final _ingredient = TextEditingController();
  final _ingredients = <String>[];
  PlanGoal _goal = PlanGoal.maintain;
  HealthInfo? _health;
  MealPlan? _plan;
  String _day = todayDayKey();
  NutritionTargetInfo? _target;
  ApiException? _targetError;
  int _targetRequest = 0;
  bool _busy = false;
  UserRole? _lastRole;
  int? _lastHealthVersion;

  static String _num(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : '$v';

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// Tên gợi ý: cả tuần T2 -> CN chứa hôm nay, ví dụ "Thực đơn 12/10 - 18/10".
  static String _defaultName() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final end = DateTime(start.year, start.month, start.day + 6);
    String dm(DateTime d) => '${_two(d.day)}/${_two(d.month)}';
    return 'Thực đơn ${dm(start)} - ${dm(end)}';
  }

  @override
  void dispose() {
    _height.dispose();
    _weight.dispose();
    _name.dispose();
    _ingredient.dispose();
    super.dispose();
  }

  /// Nạp lại chỉ số mới nhất, mục tiêu calo và thực đơn gần nhất khi đổi tài khoản
  /// (đăng nhập/đăng xuất) hoặc khi Hồ sơ > Lịch sử sức khỏe vừa thay đổi.
  void _syncHealth(UserRole role, int healthVersion) {
    if (_lastRole == role && _lastHealthVersion == healthVersion) return;
    final accountChanged = _lastRole != role;
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
          _target = null;
          _targetError = null;
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
      _loadTarget();
      if (accountChanged) _loadLatestPlan();
    });
  }

  /// Hiện sẵn thực đơn gần nhất của tài khoản; lỗi ở bước này không làm phiền người dùng.
  Future<void> _loadLatestPlan() async {
    try {
      final plans = await context.read<MealPlanRepository>().myPlans();
      if (!mounted || plans.isEmpty || _plan != null) return;
      _show(plans.first);
    } catch (_) {}
  }

  /// Mục tiêu calo do backend tính theo hồ sơ + mục tiêu đang chọn; lỗi (thiếu hồ sơ...) hiện ngay dưới nút.
  Future<void> _loadTarget() async {
    if (!context.read<AuthController>().isLoggedIn) return;
    final request = ++_targetRequest;
    try {
      final t = await context.read<MealPlanRepository>().nutritionTarget(_goal);
      if (!mounted || request != _targetRequest) return;
      setState(() {
        _target = t;
        _targetError = null;
      });
    } catch (e) {
      if (!mounted || request != _targetRequest) return;
      setState(() {
        _target = null;
        _targetError = e is ApiException ? e : ApiException(errorMessage(e));
      });
    }
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

  /// Chọn thực đơn đang xem; mở sẵn ngày hôm nay nếu thực đơn có, không thì ngày đầu tiên.
  void _show(MealPlan plan) {
    setState(() {
      _plan = plan;
      _day = plan.dayOf(todayDayKey())?.day ?? (plan.days.isEmpty ? _day : plan.days.first.day);
    });
  }

  Future<void> _calcBmi() => _run(() async {
        final h = double.tryParse(_height.text), w = double.tryParse(_weight.text);
        if (h == null || w == null || h < 50 || w < 10) {
          showSnack(context, 'Chiều cao/cân nặng không hợp lệ');
          return;
        }
        final info = await context.read<MenuRepository>().saveHealth(h, w);
        if (mounted) setState(() => _health = info);
        _loadTarget();
      });

  Future<void> _generate() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      showSnack(context, 'Vui lòng đặt tên cho thực đơn');
      return;
    }
    await _run(() async {
      try {
        final plan = await context
            .read<MealPlanRepository>()
            .generate(name: name, goal: _goal, ingredients: List.of(_ingredients));
        if (!mounted) return;
        _show(plan);
        setState(() => _name.text = _defaultName());
        showSnack(context, 'Đã tạo và lưu thực đơn');
        context.read<SubscriptionController>().refreshQuota();
      } on ApiException catch (e) {
        // 6003: hết lượt tạo thực đơn trong tháng theo gói -> mời nâng cấp thay vì chỉ báo lỗi.
        if (e.code != 6003 || !mounted) rethrow;
        await showUpgradeDialog(
            context,
            'Bạn đã hết lượt tạo thực đơn tuần của gói hiện tại. '
            'Hãy nâng cấp gói để có thêm lượt hoặc quay lại vào tháng sau.',
            title: 'Hết lượt tạo thực đơn');
      }
    });
  }

  Future<void> _toggleFavorite() => _run(() async {
        final plan = _plan!;
        await context.read<MealPlanRepository>().setFavorite(plan.id, !plan.isFavorite);
        if (!mounted) return;
        setState(() => _plan = plan.copyWith(isFavorite: !plan.isFavorite));
        showSnack(context, plan.isFavorite ? 'Đã bỏ khỏi yêu thích' : 'Đã thêm vào yêu thích');
      });

  Future<void> _replaceMeal(PlanDay day, PlanMeal meal) => _run(() async {
        final updated = await context.read<MealPlanRepository>().replaceMeal(_plan!, day.day, meal);
        if (!mounted) return;
        setState(() => _plan = updated);
        showSnack(context, 'Đã đổi ${planMealLabel(meal.mealType).toLowerCase()} ${dayLongLabel(day.day)}');
      });

  void _openMeal(PlanDay day, PlanMeal meal) {
    final readOnly = _plan!.viewingVersion != null;
    showMealSheet(context,
        day: day, meal: meal, onReplace: (readOnly || _busy) ? null : () => _replaceMeal(day, meal));
  }

  Future<void> _pickPlan(String title, String empty, Future<List<MealPlan>> Function() load) async {
    final picked = await showPlanPicker(context, title: title, emptyText: empty, load: load);
    if (picked != null && mounted) _show(picked);
  }

  Future<void> _pickVersion() async {
    final plan = _plan!;
    final repo = context.read<MealPlanRepository>();
    final v = await showVersionPicker(context,
        currentVersion: plan.viewingVersion == null ? plan.version : plan.viewingVersion!,
        load: () => repo.versions(plan.id));
    if (v == null || !mounted) return;
    // Đang xem bản cũ thì lấy lại bản hiện tại làm gốc (giữ yêu thích, mục tiêu).
    final current = plan.viewingVersion == null ? plan : await _currentOf(plan);
    if (current == null || !mounted) return;
    if (v.version == current.version) {
      setState(() => _plan = current);
    } else {
      setState(() => _plan = v.asPlanOf(current));
    }
  }

  Future<MealPlan?> _currentOf(MealPlan plan) async {
    try {
      return await context.read<MealPlanRepository>().plan(plan.id);
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e));
      return null;
    }
  }

  Future<void> _leaveVersion() async {
    final current = await _currentOf(_plan!);
    if (current != null && mounted) setState(() => _plan = current);
  }

  /// Đưa phiên bản đang xem về làm thực đơn hiện tại (POST .../versions/{version}/restore).
  Future<void> _restoreVersion() async {
    final plan = _plan!;
    final version = plan.viewingVersion;
    if (version == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Khôi phục phiên bản $version?'),
        content: const Text('Thực đơn hiện tại sẽ được thay bằng nội dung phiên bản này. '
            'Nội dung hiện tại vẫn được giữ lại trong lịch sử phiên bản.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Khôi phục')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _run(() async {
      final restored = await context.read<MealPlanRepository>().restoreVersion(plan.id, version);
      if (!mounted) return;
      _show(restored);
      showSnack(context, 'Đã khôi phục phiên bản $version');
    });
  }

  Future<void> _fixProfile() async {
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => const EditProfileScreen(highlightFields: {'dateOfBirth', 'gender', 'activityLevel'})));
    _loadTarget();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final auth = context.watch<AuthController>();
    final repo = context.read<MealPlanRepository>();
    _syncHealth(auth.role, context.watch<HealthSync>().version);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _healthCard(),
        const SizedBox(height: 16),
        _options(auth.isLoggedIn),
        if (auth.isLoggedIn) ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: OutlinedButton.icon(
                    onPressed: () => _pickPlan('Thực đơn của tôi', 'Chưa có thực đơn nào được lưu', repo.myPlans),
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Của tôi'))),
            const SizedBox(width: 12),
            Expanded(
                child: OutlinedButton.icon(
                    onPressed: () => _pickPlan('Thực đơn yêu thích', 'Bạn chưa yêu thích thực đơn nào', repo.favorites),
                    icon: const Icon(Icons.favorite_border),
                    label: const Text('Yêu thích'))),
          ]),
        ],
        if (_plan != null) ...[
          const SectionHeader('Thực đơn tuần của bạn'),
          PlanView(
            plan: _plan!,
            selectedDay: _day,
            busy: _busy,
            onSelectDay: (d) => setState(() => _day = d),
            onMealTap: _openMeal,
            onToggleFavorite: _toggleFavorite,
            onLeaveVersion: _plan!.viewingVersion == null ? null : _leaveVersion,
            onRestoreVersion: _plan!.viewingVersion == null ? null : _restoreVersion,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
              onPressed: _busy ? null : _pickVersion,
              icon: const Icon(LucideIcons.history),
              label: const Text('Lịch sử phiên bản')),
          const SizedBox(height: 8),
          Text('Bấm vào một món để xem công thức hoặc đổi sang món khác.',
              style: TextStyle(fontSize: 12, color: context.textMuted)),
        ],
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
              if (_target != null)
                _stat('Calo mục tiêu', '${_target!.targetCalories}', 'kcal/ngày')
              else
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

  Widget _options(bool loggedIn) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Tạo thực đơn tuần',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            maxLength: 160,
            decoration: const InputDecoration(
                labelText: 'Tên thực đơn',
                hintText: 'Ví dụ: Thực đơn tuần này',
                prefixIcon: Icon(LucideIcons.tag),
                counterText: ''),
          ),
          const SizedBox(height: 12),
          FullWidthSegmented<PlanGoal>(
            options: [for (final g in PlanGoal.all) SegmentOption(g, g.label)],
            selected: _goal,
            onChanged: (v) {
              setState(() => _goal = v);
              _loadTarget();
            },
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_goal.hint, style: TextStyle(fontSize: 12, color: context.textMuted)),
          ),
          _targetInfo(loggedIn),
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
          if (loggedIn && context.watch<PantryController>().items.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _usePantry,
                icon: const Icon(LucideIcons.refrigerator, size: 18),
                label: const Text('Dùng nguyên liệu trong tủ'),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: (_busy || !loggedIn) ? null : _generate,
              icon: _busy
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome),
              label: const Text('Tạo thực đơn'),
            ),
          ),
          if (!loggedIn)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Đăng nhập để tạo và lưu thực đơn cá nhân.',
                  style: TextStyle(color: context.textMuted)),
            )
          else if (context.watch<SubscriptionController>() case final subs when subs.subscription != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                  subs.quota != null
                      ? '${planName(subs.subscription!.planCode)}: ${subs.quota!.mealPlan.label}.'
                      : '${planName(subs.subscription!.planCode)}: tối đa ${subs.subscription!.mealPlansPerMonth} thực đơn mỗi tháng.',
                  style: TextStyle(fontSize: 12.5, color: context.textMuted)),
            ),
        ]),
      ),
    );
  }

  /// Calo mục tiêu backend tính được, hoặc lý do chưa tính được (thiếu chỉ số / hồ sơ / dưới 18 tuổi).
  Widget _targetInfo(bool loggedIn) {
    if (!loggedIn) return const SizedBox.shrink();
    final t = _target;
    final err = _targetError;
    if (t != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
            'Mục tiêu: ${t.targetCalories} kcal/ngày (BMR ${t.bmr}, nhu cầu ${t.tdee} kcal)',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      );
    }
    if (err == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(err.message, style: const TextStyle(fontSize: 13, color: Colors.deepOrange)),
        if (err.code == 6020 || err.code == 6010)
          TextButton.icon(
            onPressed: err.code == 6020 ? _fixProfile : null,
            icon: const Icon(LucideIcons.userPen, size: 18),
            label: Text(err.code == 6020 ? 'Cập nhật hồ sơ' : 'Nhập chiều cao, cân nặng ở trên'),
          ),
      ]),
    );
  }

  /// Thêm nguyên liệu gõ tay; backend nhận tối đa [PantryController.maxForPlan] nguyên liệu, mỗi cái tối đa 100 ký tự.
  void _addIngredient() {
    final t = _ingredient.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (t.isEmpty) return;
    if (t.length > 100) {
      showSnack(context, 'Tên nguyên liệu tối đa 100 ký tự');
      return;
    }
    if (_hasIngredient(t)) {
      _ingredient.clear();
      return;
    }
    if (_ingredients.length >= PantryController.maxForPlan) {
      showSnack(context, 'Tối đa ${PantryController.maxForPlan} nguyên liệu mỗi thực đơn');
      return;
    }
    setState(() {
      _ingredients.add(t);
      _ingredient.clear();
    });
  }

  bool _hasIngredient(String name) =>
      _ingredients.any((e) => e.toLowerCase() == name.toLowerCase());

  /// Điền nguyên liệu trong tủ (còn hạn, sắp hết hạn trước) vào danh sách "nguyên liệu bạn có".
  void _usePantry() {
    final names = context.read<PantryController>().namesForPlan();
    var added = 0;
    setState(() {
      for (final n in names) {
        if (_ingredients.length >= PantryController.maxForPlan) break;
        if (_hasIngredient(n)) continue;
        _ingredients.add(n);
        added++;
      }
    });
    showSnack(
        context,
        added > 0
            ? 'Đã thêm $added nguyên liệu từ tủ'
            : names.isEmpty
                ? 'Tủ không có nguyên liệu còn hạn'
                : 'Các nguyên liệu trong tủ đã có trong danh sách');
  }
}
