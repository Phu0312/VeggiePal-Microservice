import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/paged_list_view.dart';
import '../../ingredient/data/ingredient_models.dart';
import '../../ingredient/data/ingredient_repository.dart';
import '../data/admin_repository.dart';

/// Quản lý danh mục nguyên liệu (admin): tìm, lọc thuần chay / dị ứng, thêm, sửa, xoá.
/// Danh sách GET /ingredients chỉ trả nguyên liệu đang hoạt động (kể cả với admin); nguyên liệu đã chuyển sang
/// "ngừng dùng" sẽ không còn hiện ở đây. Ghi bằng POST / PUT / DELETE /ingredients (chỉ ADMIN).
class AdminIngredientsTab extends StatefulWidget {
  const AdminIngredientsTab({super.key});

  @override
  State<AdminIngredientsTab> createState() => _AdminIngredientsTabState();
}

class _AdminIngredientsTabState extends State<AdminIngredientsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _search = TextEditingController();
  final _list = GlobalKey<PagedListViewState<Ingredient>>();
  IngredientFilter _filter = IngredientFilter.all;
  String _keyword = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reload() => _list.currentState?.reload();

  Future<void> _openForm([Ingredient? edit]) async {
    final saved = await Navigator.of(context)
        .push<Ingredient>(MaterialPageRoute(builder: (_) => IngredientFormScreen(existing: edit)));
    if (saved != null && mounted) {
      showSnack(context, edit == null ? 'Đã thêm nguyên liệu' : 'Đã cập nhật nguyên liệu');
      _reload();
    }
  }

  Future<void> _delete(Ingredient g) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá nguyên liệu'),
        content: Text('Xoá hẳn "${g.name}" khỏi danh mục? Thao tác này không thể hoàn tác. '
            'Nếu chỉ muốn ngừng dùng, hãy sửa và tắt "Đang sử dụng".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xoá')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<AdminRepository>().deleteIngredient(g.id);
      if (!mounted) return;
      showSnack(context, 'Đã xoá "${g.name}"');
      _reload();
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e), title: 'Không xoá được nguyên liệu');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final repo = context.read<IngredientRepository>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'admin-ingredient-add',
        onPressed: () => _openForm(),
        icon: const Icon(LucideIcons.plus),
        label: const Text('Thêm nguyên liệu'),
      ),
      body: Column(children: [
        VegSearchBar(
          controller: _search,
          hint: 'Tìm nguyên liệu...',
          onSubmitted: (v) {
            _keyword = v.trim();
            _reload();
          },
        ),
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
          child: PagedListView<Ingredient>(
            key: _list,
            errorTitle: 'Không tải được nguyên liệu',
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
            load: (page) => repo.page(keyword: _keyword, filter: _filter, page: page),
            emptyText: 'Không tìm thấy nguyên liệu phù hợp.',
            itemBuilder: (context, g) => Card(
              child: ListTile(
                onTap: () => _openForm(g),
                title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                    '${g.calories.round()} kcal • ${g.protein.toStringAsFixed(1)}g đạm / 100g'
                    '${g.hasDescription ? '\n${g.description!.trim()}' : ''}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis),
                isThreeLine: g.hasDescription,
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (g.allergen)
                    const Icon(LucideIcons.triangleAlert, size: 16, color: Colors.deepOrange),
                  if (g.vegan)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(LucideIcons.leaf, size: 16, color: context.cs.primary),
                    ),
                  IconButton(
                    tooltip: 'Xoá',
                    icon: Icon(LucideIcons.trash2, size: 20, color: context.cs.error),
                    onPressed: () => _delete(g),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Thêm / sửa một nguyên liệu. Trả về [Ingredient] đã lưu qua Navigator.pop.
/// Dinh dưỡng tính trên 100g; bốn chỉ số đầu bắt buộc và không âm, chất xơ có thể bỏ trống.
class IngredientFormScreen extends StatefulWidget {
  final Ingredient? existing;
  const IngredientFormScreen({super.key, this.existing});

  @override
  State<IngredientFormScreen> createState() => _IngredientFormScreenState();
}

class _IngredientFormScreenState extends State<IngredientFormScreen> {
  final _form = GlobalKey<FormState>();

  static String _n(double? v) =>
      v == null ? '' : (v == v.roundToDouble() ? v.toStringAsFixed(0) : '$v');

  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _description = TextEditingController(text: widget.existing?.description ?? '');
  late final _calories = TextEditingController(text: widget.existing == null ? '' : _n(widget.existing!.calories));
  late final _protein = TextEditingController(text: widget.existing == null ? '' : _n(widget.existing!.protein));
  late final _carbs = TextEditingController(text: widget.existing == null ? '' : _n(widget.existing!.carbs));
  late final _fat = TextEditingController(text: widget.existing == null ? '' : _n(widget.existing!.fat));
  late final _fiber = TextEditingController(text: _n(widget.existing?.fiber));
  late bool _vegan = widget.existing?.vegan ?? true;
  late bool _allergen = widget.existing?.allergen ?? false;
  late bool _active = widget.existing?.active ?? true;
  bool _busy = false;

  bool get _isEdit => widget.existing != null;

  @override
  void dispose() {
    for (final c in [_name, _description, _calories, _protein, _carbs, _fat, _fiber]) {
      c.dispose();
    }
    super.dispose();
  }

  /// "12,5" hoặc "12.5" -> 12.5; null nếu không phải số.
  static double? _parse(String t) => double.tryParse(t.trim().replaceAll(',', '.'));

  String? _required(String? v) {
    final n = _parse(v ?? '');
    if (n == null) return 'Nhập một số';
    return n < 0 ? 'Không được âm' : null;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final payload = IngredientPayload(
      name: _name.text,
      description: _description.text,
      calories: _parse(_calories.text)!,
      protein: _parse(_protein.text)!,
      carbs: _parse(_carbs.text)!,
      fat: _parse(_fat.text)!,
      fiber: _fiber.text.trim().isEmpty ? null : _parse(_fiber.text),
      vegan: _vegan,
      allergen: _allergen,
      active: _active,
    );
    final repo = context.read<AdminRepository>();
    try {
      final saved = _isEdit
          ? await repo.updateIngredient(widget.existing!.id, payload)
          : await repo.createIngredient(payload);
      if (mounted) Navigator.of(context).pop(saved);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showErrorDialog(context, errorMessage(e), title: 'Không lưu được nguyên liệu');
      }
    }
  }

  Widget _num(TextEditingController c, String label, {bool optional = false}) => TextFormField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
        validator: optional
            ? (v) => (v ?? '').trim().isEmpty ? null : _required(v)
            : _required,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Sửa nguyên liệu' : 'Thêm nguyên liệu')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
            TextFormField(
              controller: _name,
              maxLength: 150,
              decoration: const InputDecoration(
                  labelText: 'Tên nguyên liệu', prefixIcon: Icon(LucideIcons.leaf), counterText: ''),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Vui lòng nhập tên nguyên liệu' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              maxLines: 3,
              maxLength: 1000,
              decoration: const InputDecoration(
                  labelText: 'Mô tả (nên ghi trạng thái: sống / chín / khô)',
                  alignLabelWithHint: true,
                  counterText: ''),
            ),
            const SizedBox(height: 16),
            Text('Dinh dưỡng trên 100g',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: _num(_calories, 'Năng lượng (kcal)')),
              const SizedBox(width: 12),
              Expanded(child: _num(_protein, 'Đạm (g)')),
            ]),
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: _num(_carbs, 'Tinh bột (g)')),
              const SizedBox(width: 12),
              Expanded(child: _num(_fat, 'Chất béo (g)')),
            ]),
            const SizedBox(height: 12),
            _num(_fiber, 'Chất xơ (g, không bắt buộc)', optional: true),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Thuần chay'),
              value: _vegan,
              onChanged: (v) => setState(() => _vegan = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Có thể gây dị ứng'),
              value: _allergen,
              onChanged: (v) => setState(() => _allergen = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Đang sử dụng'),
              subtitle: const Text('Tắt thì nguyên liệu không còn hiện trong danh mục chọn công thức'),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEdit ? 'Lưu thay đổi' : 'Thêm nguyên liệu'),
            ),
          ]),
        ),
      ),
    );
  }
}
