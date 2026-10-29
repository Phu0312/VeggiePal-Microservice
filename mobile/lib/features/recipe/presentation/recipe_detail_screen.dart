import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../profile/data/profile_models.dart';
import '../../profile/data/profile_repository.dart';
import '../data/recipe_models.dart';
import '../data/recipe_repository.dart';
import 'recipe_form_screen.dart';
import 'recipe_widgets.dart';

/// Chi tiết công thức (GET /recipes/{id}): ảnh, tác giả, thời gian, dinh dưỡng mỗi khẩu phần, cảnh báo
/// nguyên liệu, nguyên liệu và các bước. Chủ công thức và ADMIN có thêm menu Sửa / Đăng / Xoá.
/// [initial] (nếu có) hiện ngay trong lúc tải bản đầy đủ.
class RecipeDetailScreen extends StatefulWidget {
  final int recipeId;
  final Recipe? initial;
  const RecipeDetailScreen({super.key, required this.recipeId, this.initial});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  Recipe? _recipe;
  PublicUser? _author;
  bool _loading = true;
  bool _notFound = false;
  bool _failed = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _recipe = widget.initial;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
      _notFound = false;
    });
    try {
      final r = await context.read<RecipeRepository>().recipe(widget.recipeId);
      if (!mounted) return;
      setState(() => _recipe = r);
      _loadAuthor(r.userId);
    } catch (e) {
      if (!mounted) return;
      if (e is ApiException && e.code == 4100) {
        setState(() => _notFound = true);
      } else {
        setState(() => _failed = _recipe == null);
        showErrorDialog(context, errorMessage(e), title: 'Không tải được công thức');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Tên tác giả chỉ là thông tin phụ, lỗi được bỏ qua.
  Future<void> _loadAuthor(int userId) async {
    try {
      final users = await context.read<ProfileRepository>().publicUsers([userId]);
      if (mounted && users.isNotEmpty) setState(() => _author = users.first);
    } catch (_) {}
  }

  bool get _canManage {
    final r = _recipe;
    final auth = context.read<AuthController>();
    return r != null && auth.isLoggedIn && (r.userId == auth.user?.id || auth.isAdmin);
  }

  /// BE không cho sửa, đăng, xoá công thức đã xoá hoặc đang ẩn (lỗi 4108).
  bool get _mutable => _recipe != null && _recipe!.status != 'ARCHIVED' && _recipe!.status != 'HIDDEN';

  Future<void> _run(Future<void> Function() job, String errorTitle) async {
    setState(() => _busy = true);
    try {
      await job();
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e), title: errorTitle);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm(String title, String message, String action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(action)),
        ],
      ),
    );
    return ok == true && mounted;
  }

  Future<void> _edit() async {
    final saved = await Navigator.of(context)
        .push<Recipe>(MaterialPageRoute(builder: (_) => RecipeFormScreen(existing: _recipe)));
    if (saved != null && mounted) {
      setState(() => _recipe = saved);
      showSnack(context, 'Đã cập nhật công thức');
    }
  }

  Future<void> _publish() async {
    if (!await _confirm('Đăng công thức',
        'Công thức sẽ hiển thị công khai cho mọi người. Bạn có chắc muốn đăng?', 'Đăng')) {
      return;
    }
    await _run(() async {
      final r = await context.read<RecipeRepository>().publish(widget.recipeId);
      if (!mounted) return;
      setState(() => _recipe = r);
      showSnack(context, 'Đã đăng công thức');
    }, 'Không đăng được công thức');
  }

  Future<void> _delete() async {
    if (!await _confirm('Xoá công thức',
        'Bạn có chắc muốn xoá "${_recipe!.title}"? Thực đơn cũ đã dùng món này vẫn hiển thị bình thường.',
        'Xoá')) {
      return;
    }
    await _run(() async {
      await context.read<RecipeRepository>().delete(widget.recipeId);
      if (!mounted) return;
      showSnack(context, 'Đã xoá công thức');
      Navigator.of(context).pop();
    }, 'Không xoá được công thức');
  }

  @override
  Widget build(BuildContext context) {
    final r = _recipe;
    final auth = context.watch<AuthController>();
    final visible = r != null && (r.status == 'PUBLISHED' || _canManage);

    Widget body;
    if (_notFound || (r != null && !_loading && !visible)) {
      body = const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Công thức không tồn tại.')));
    } else if (r == null) {
      body = _loading
          ? const Center(child: CircularProgressIndicator())
          : RetryView(message: _failed ? 'Không tải được công thức.' : 'Không có dữ liệu.', onRetry: _load);
    } else {
      body = _Body(recipe: r, author: _author, loading: _loading);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(r?.title ?? 'Công thức', maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (r != null && visible && auth.isLoggedIn && _canManage && _mutable)
            PopupMenuButton<String>(
              enabled: !_busy,
              onSelected: (v) => switch (v) {
                'edit' => _edit(),
                'publish' => _publish(),
                _ => _delete(),
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Sửa công thức')),
                if (r.status == 'DRAFT') const PopupMenuItem(value: 'publish', child: Text('Đăng công thức')),
                const PopupMenuItem(value: 'delete', child: Text('Xoá công thức')),
              ],
            ),
        ],
      ),
      body: body,
    );
  }
}

class _Body extends StatelessWidget {
  final Recipe recipe;
  final PublicUser? author;
  final bool loading;
  const _Body({required this.recipe, required this.author, required this.loading});

  Widget _title(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(text,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      );

  Widget _macro(BuildContext context, String label, String value) => Expanded(
        child: Column(children: [
          Text(value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: context.cs.primary)),
          Text(label, style: TextStyle(fontSize: 12, color: context.textMuted)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final r = recipe;
    final n = r.nutrition;
    final gap = r.nutritionGapHint;
    final allergens = r.allergenNames;
    final nonVegan = r.nonVeganNames;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        if (loading) const LinearProgressIndicator(),
        if (r.imageUrl != null && r.imageUrl!.isNotEmpty)
          VegImage(r.imageUrl, width: double.infinity, height: 200, radius: BorderRadius.circular(16)),
        const SizedBox(height: 12),
        if (r.status != 'PUBLISHED') ...[
          Align(alignment: Alignment.centerLeft, child: RecipeStatusBadge(r.status)),
          const SizedBox(height: 8),
        ],
        Text(r.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(
          [
            if (author != null) 'Bởi ${author!.fullName}',
            if (r.createdAt != null) fmtDate(r.createdAt!.toLocal()),
          ].join('  •  '),
          style: TextStyle(color: context.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 16, runSpacing: 4, children: [
          if (r.totalMinutes != null && r.totalMinutes! > 0)
            _Meta(LucideIcons.clock, '${r.totalMinutes} phút'
                '${r.prepTime != null && r.cookTime != null ? ' (chuẩn bị ${r.prepTime}, nấu ${r.cookTime})' : ''}'),
          _Meta(LucideIcons.users, '${r.servings} khẩu phần'),
        ]),
        if (r.description != null && r.description!.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(r.description!, style: const TextStyle(height: 1.4)),
        ],
        if (allergens.isNotEmpty || nonVegan.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.deepOrange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (allergens.isNotEmpty)
                Text('Có nguyên liệu dễ gây dị ứng: ${allergens.join(', ')}',
                    style: const TextStyle(fontSize: 13)),
              if (nonVegan.isNotEmpty)
                Text('Nguyên liệu không thuần chay: ${nonVegan.join(', ')}',
                    style: const TextStyle(fontSize: 13)),
            ]),
          ),
        ],
        _title(context, 'Dinh dưỡng mỗi khẩu phần'),
        if (n != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(children: [
                _macro(context, 'kcal', '${n.kcal}'),
                _macro(context, 'Đạm (g)', n.protein.toStringAsFixed(1)),
                _macro(context, 'Tinh bột (g)', n.carbs.toStringAsFixed(1)),
                _macro(context, 'Béo (g)', n.fat.toStringAsFixed(1)),
              ]),
            ),
          )
        else
          Text(gap ?? 'Chưa đủ dữ liệu để tính dinh dưỡng.',
              style: TextStyle(fontSize: 13, color: context.textMuted)),
        _title(context, 'Nguyên liệu'),
        for (final i in r.ingredients)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('• '),
              Expanded(
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: i.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(text: ' - ${i.amountText}'),
                  if (i.note != null && i.note!.trim().isNotEmpty)
                    TextSpan(text: ' (${i.note})', style: TextStyle(color: context.textMuted)),
                ])),
              ),
              if (i.allergen)
                const Padding(
                  padding: EdgeInsets.only(left: 6, top: 2),
                  child: Icon(LucideIcons.triangleAlert, size: 14, color: Colors.deepOrange),
                ),
            ]),
          ),
        _title(context, 'Cách làm'),
        for (var k = 0; k < r.steps.length; k++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.accent,
                child: Text('${k + 1}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(r.steps[k].instruction, style: const TextStyle(height: 1.4))),
            ]),
          ),
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Meta(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: context.cs.primary),
        const SizedBox(width: 6),
        Flexible(child: Text(text, style: const TextStyle(fontSize: 13.5))),
      ]);
}
