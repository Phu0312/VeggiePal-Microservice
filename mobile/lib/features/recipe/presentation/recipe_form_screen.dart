import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../ingredient/presentation/ingredient_picker.dart';
import '../data/recipe_models.dart';
import '../data/recipe_repository.dart';

/// Tạo công thức mới hoặc sửa công thức của tôi. Trả về [Recipe] đã lưu qua Navigator.pop.
/// - Tạo: POST /recipes (luôn là bản nháp), nút "Lưu và đăng" gọi thêm POST /recipes/{id}/publish.
/// - Sửa: PUT /recipes/{id} (không đổi trạng thái); bản nháp có thêm "Lưu và đăng".
/// Nguyên liệu chọn từ danh mục chung (GET /ingredients). Ảnh chỉ là đường dẫn (recipe-service chưa có API tải ảnh).
class RecipeFormScreen extends StatefulWidget {
  final Recipe? existing; // null = tạo mới
  const RecipeFormScreen({super.key, this.existing});

  @override
  State<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

/// Một dòng nguyên liệu trong form: dữ liệu + ô nhập số lượng / ghi chú.
class _IngRow {
  final int ingredientId;
  final String name;
  String unit;
  final TextEditingController quantity;
  final TextEditingController note;

  _IngRow(this.ingredientId, this.name, this.unit, String quantity, String note)
      : quantity = TextEditingController(text: quantity),
        note = TextEditingController(text: note);

  void dispose() {
    quantity.dispose();
    note.dispose();
  }
}

class _RecipeFormScreenState extends State<RecipeFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  late final _description = TextEditingController(text: widget.existing?.description ?? '');
  late final _imageUrl = TextEditingController(text: widget.existing?.imageUrl ?? '');
  late final _servings = TextEditingController(text: '${widget.existing?.servings ?? 2}');
  late final _prep = TextEditingController(text: '${widget.existing?.prepTime ?? ''}');
  late final _cook = TextEditingController(text: '${widget.existing?.cookTime ?? ''}');
  final _ingredients = <_IngRow>[];
  final _steps = <TextEditingController>[];
  String? _listError;
  bool _busy = false;

  bool get _isEdit => widget.existing != null;
  bool get _canPublish => !_isEdit || widget.existing!.status == 'DRAFT';

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      for (final i in e.ingredients) {
        _ingredients.add(_IngRow(
            i.ingredientId, i.name, i.unit, formatQuantity(i.quantity), i.note ?? ''));
      }
      for (final s in e.steps) {
        _steps.add(TextEditingController(text: s.instruction));
      }
    }
    if (_steps.isEmpty) _steps.add(TextEditingController());
  }

  @override
  void dispose() {
    for (final c in [_title, _description, _imageUrl, _servings, _prep, _cook, ..._steps]) {
      c.dispose();
    }
    for (final i in _ingredients) {
      i.dispose();
    }
    super.dispose();
  }

  Future<void> _addIngredient() async {
    final picked = await showIngredientPicker(context,
        excludeIds: {for (final i in _ingredients) i.ingredientId});
    if (picked == null || !mounted) return;
    setState(() {
      _listError = null;
      _ingredients.add(_IngRow(picked.id, picked.name, 'GRAM', '', ''));
    });
  }

  void _moveStep(int from, int to) {
    if (to < 0 || to >= _steps.length) return;
    setState(() => _steps.insert(to, _steps.removeAt(from)));
  }

  String? _optionalInt(String? v, String label) {
    final t = (v ?? '').trim();
    return t.isEmpty || RegExp(r'^\d{1,4}$').hasMatch(t) ? null : '$label phải là số nguyên không âm';
  }

  /// Kiểm tra các danh sách (ngoài các ô nhập đã có validator); trả về lỗi đầu tiên hoặc null.
  String? _validateLists() {
    if (_ingredients.isEmpty) return 'Thêm ít nhất 1 nguyên liệu';
    if (_steps.every((s) => s.text.trim().isEmpty)) return 'Thêm ít nhất 1 bước thực hiện';
    return null;
  }

  RecipePayload _payload() => RecipePayload(
        title: _title.text,
        description: _description.text,
        imageUrl: _imageUrl.text,
        servings: int.parse(_servings.text.trim()),
        prepTime: int.tryParse(_prep.text.trim()),
        cookTime: int.tryParse(_cook.text.trim()),
        ingredients: [
          for (final i in _ingredients)
            RecipeIngredientDraft(
                ingredientId: i.ingredientId,
                name: i.name,
                quantity: i.quantity.text,
                unit: i.unit,
                note: i.note.text),
        ],
        // Bước bỏ trống bị loại, số thứ tự đánh lại từ 1.
        steps: [for (final s in _steps) if (s.text.trim().isNotEmpty) s.text],
      );

  /// [publish]: tạo xong thì đăng luôn; sửa bản nháp thì đăng sau khi lưu.
  Future<void> _save({required bool publish}) async {
    final formOk = _form.currentState!.validate();
    final listError = _validateLists();
    setState(() => _listError = listError);
    if (!formOk || listError != null) return;

    setState(() => _busy = true);
    final repo = context.read<RecipeRepository>();
    final payload = _payload();
    Recipe saved;
    try {
      saved = _isEdit
          ? await repo.update(widget.existing!.id, payload)
          : await repo.create(payload);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showErrorDialog(context, errorMessage(e), title: 'Không lưu được công thức');
      }
      return;
    }

    if (publish && saved.status == 'DRAFT') {
      try {
        saved = await repo.publish(saved.id);
      } catch (e) {
        if (mounted) {
          // Công thức đã được lưu ở dạng nháp, chỉ bước đăng thất bại.
          await showErrorDialog(context, '${errorMessage(e)}\nCông thức đã được lưu ở dạng bản nháp.',
              title: 'Chưa đăng được công thức');
        }
      }
    }
    if (mounted) Navigator.of(context).pop(saved);
  }

  Widget _section(String title, {Widget? trailing}) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        child: Row(children: [
          Expanded(
              child: Text(title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
          if (trailing != null) trailing,
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Sửa công thức' : 'Tạo công thức')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              TextFormField(
                controller: _title,
                maxLength: RecipeLimits.title,
                decoration: const InputDecoration(
                    labelText: 'Tên công thức', prefixIcon: Icon(LucideIcons.chefHat), counterText: ''),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Vui lòng nhập tên công thức' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                maxLines: 3,
                maxLength: RecipeLimits.description,
                decoration: const InputDecoration(
                    labelText: 'Mô tả (không bắt buộc)', alignLabelWithHint: true, counterText: ''),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageUrl,
                keyboardType: TextInputType.url,
                maxLength: RecipeLimits.imageUrl,
                decoration: const InputDecoration(
                    labelText: 'Link ảnh (không bắt buộc)',
                    hintText: 'https://...',
                    prefixIcon: Icon(LucideIcons.image),
                    counterText: ''),
                validator: (v) {
                  final t = (v ?? '').trim();
                  return t.isEmpty || RegExp(r'^https?://\S+$', caseSensitive: false).hasMatch(t)
                      ? null
                      : 'Link ảnh phải bắt đầu bằng http:// hoặc https://';
                },
              ),
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: TextFormField(
                    controller: _servings,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Khẩu phần'),
                    validator: (v) => RegExp(r'^[1-9]\d{0,3}$').hasMatch((v ?? '').trim())
                        ? null
                        : 'Từ 1 trở lên',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _prep,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Chuẩn bị (phút)'),
                    validator: (v) => _optionalInt(v, 'Thời gian'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cook,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Nấu (phút)'),
                    validator: (v) => _optionalInt(v, 'Thời gian'),
                  ),
                ),
              ]),
              _section('Nguyên liệu',
                  trailing: TextButton.icon(
                      onPressed: _addIngredient,
                      icon: const Icon(LucideIcons.plus, size: 18),
                      label: const Text('Thêm'))),
              if (_ingredients.isEmpty)
                Text('Chưa có nguyên liệu nào. Bấm "Thêm" để chọn từ danh mục.',
                    style: TextStyle(color: context.textMuted)),
              for (var i = 0; i < _ingredients.length; i++) _ingredientCard(i),
              _section('Các bước thực hiện',
                  trailing: TextButton.icon(
                      onPressed: () => setState(() {
                            _listError = null;
                            _steps.add(TextEditingController());
                          }),
                      icon: const Icon(LucideIcons.plus, size: 18),
                      label: const Text('Thêm bước'))),
              for (var i = 0; i < _steps.length; i++) _stepRow(i),
              if (_listError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_listError!, style: TextStyle(color: context.cs.error)),
                ),
              const SizedBox(height: 24),
              if (_canPublish)
                FilledButton.icon(
                  onPressed: _busy ? null : () => _save(publish: true),
                  icon: const Icon(LucideIcons.send),
                  label: const Text('Lưu và đăng'),
                ),
              if (_canPublish) const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _save(publish: false),
                icon: _busy
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(LucideIcons.save),
                label: Text(_isEdit ? 'Lưu thay đổi' : 'Lưu bản nháp'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ingredientCard(int index) {
    final row = _ingredients[index];
    // Đơn vị của công thức cũ có thể không nằm trong danh sách chọn (vd "G"): thêm vào để hiển thị đúng.
    final units = {...recipeUnitOptions.keys, row.unit};
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text(row.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
            IconButton(
              tooltip: 'Bỏ nguyên liệu',
              icon: const Icon(LucideIcons.trash2, size: 18),
              onPressed: () => setState(() => _ingredients.removeAt(index).dispose()),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: row.quantity,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Số lượng'),
                  validator: (v) =>
                      isValidQuantity(v ?? '') ? null : 'Tối thiểu 0,01, tối đa 2 số thập phân',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  initialValue: row.unit,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Đơn vị'),
                  items: [
                    for (final u in units)
                      DropdownMenuItem(value: u, child: Text(recipeUnitOptions[u] ?? unitLabel(u))),
                  ],
                  onChanged: (v) => setState(() => row.unit = v ?? row.unit),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 8),
            child: TextFormField(
              controller: row.note,
              maxLength: RecipeLimits.note,
              decoration: const InputDecoration(
                  labelText: 'Ghi chú (không bắt buộc)', hintText: 'Ví dụ: cắt hạt lựu', counterText: ''),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _stepRow(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 14, right: 8),
          child: CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.accent,
            child: Text('${index + 1}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87)),
          ),
        ),
        Expanded(
          child: TextFormField(
            controller: _steps[index],
            minLines: 2,
            maxLines: 6,
            maxLength: RecipeLimits.instruction,
            decoration: const InputDecoration(hintText: 'Mô tả bước này', counterText: ''),
          ),
        ),
        Column(children: [
          IconButton(
            tooltip: 'Lên',
            visualDensity: VisualDensity.compact,
            icon: const Icon(LucideIcons.chevronUp, size: 18),
            onPressed: index == 0 ? null : () => _moveStep(index, index - 1),
          ),
          IconButton(
            tooltip: 'Xuống',
            visualDensity: VisualDensity.compact,
            icon: const Icon(LucideIcons.chevronDown, size: 18),
            onPressed: index == _steps.length - 1 ? null : () => _moveStep(index, index + 1),
          ),
          IconButton(
            tooltip: 'Xoá bước',
            visualDensity: VisualDensity.compact,
            icon: const Icon(LucideIcons.trash2, size: 18),
            onPressed: _steps.length == 1
                ? null
                : () => setState(() => _steps.removeAt(index).dispose()),
          ),
        ]),
      ]),
    );
  }
}
