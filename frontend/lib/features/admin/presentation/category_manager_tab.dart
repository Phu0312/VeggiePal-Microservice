import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../blog/data/blog_models.dart';
import '../../blog/data/blog_repository.dart';

String _typeLabel(String type) => type == 'RECIPE_TYPE' ? 'Loại công thức' : 'Loại thực phẩm';

/// Quản lý danh mục (admin): xem cây danh mục kể cả mục đã ẩn, thêm (gốc/con), sửa, ẩn/hiện, xoá.
/// API: GET /categories?activeOnly=false, GET /categories/{id}, POST/PUT/DELETE /categories[/{id}].
class CategoryManagerTab extends StatefulWidget {
  const CategoryManagerTab({super.key});

  @override
  State<CategoryManagerTab> createState() => _CategoryManagerTabState();
}

class _CategoryManagerTabState extends State<CategoryManagerTab> {
  static const _filters = {null: 'Tất cả', 'RECIPE_TYPE': 'Công thức', 'FOOD_TYPE': 'Thực phẩm'};

  List<CategoryNode> _tree = [];
  String? _type;
  bool _loading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final r = await context.read<BlogRepository>().categoryTree(type: _type, activeOnly: false);
      if (mounted) setState(() => _tree = r);
    } catch (e) {
      if (mounted) {
        setState(() => _loadFailed = true);
        showErrorDialog(context, errorMessage(e), title: 'Không tải được danh mục');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Mở form thêm/sửa. Khi sửa, lấy bản mới nhất bằng GET /categories/{id} trước.
  Future<void> _openForm({CategoryNode? edit, CategoryNode? parent}) async {
    CategoryNode? fresh = edit;
    if (edit != null) {
      try {
        fresh = await context.read<BlogRepository>().category(edit.id);
      } catch (e) {
        if (mounted) showErrorDialog(context, errorMessage(e), title: 'Không tải được danh mục');
        return;
      }
    }
    if (!mounted) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _CategoryForm(edit: fresh, parent: parent),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(CategoryNode c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá danh mục'),
        content: Text('Xoá "${c.name}"? Chỉ xoá được danh mục chưa có nội dung nào dùng.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xoá')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<BlogRepository>().deleteCategory(c.id);
      if (!mounted) return;
      showSnack(context, 'Đã xoá danh mục "${c.name}"');
      _load();
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e), title: 'Không xoá được danh mục');
    }
  }

  Widget _tile(CategoryNode c, {required bool isRoot}) {
    return ListTile(
      contentPadding: EdgeInsets.only(left: isRoot ? 16 : 40, right: 4),
      leading: Icon(isRoot ? LucideIcons.folder : LucideIcons.cornerDownRight,
          color: c.active ? context.cs.primary : context.textMuted),
      title: Text(c.name,
          style: TextStyle(
              fontWeight: isRoot ? FontWeight.w700 : FontWeight.w500,
              color: c.active ? null : context.textMuted)),
      subtitle: Text([
        if (isRoot) _typeLabel(c.type),
        'Thứ tự ${c.displayOrder}',
        if (!c.active) 'Đang ẩn',
      ].join('  •  ')),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (isRoot)
          IconButton(
              tooltip: 'Thêm danh mục con',
              onPressed: () => _openForm(parent: c),
              icon: const Icon(LucideIcons.plus, size: 20)),
        IconButton(
            tooltip: 'Sửa', onPressed: () => _openForm(edit: c), icon: const Icon(LucideIcons.pencil, size: 20)),
        IconButton(
            tooltip: 'Xoá',
            onPressed: () => _delete(c),
            icon: Icon(LucideIcons.trash2, size: 20, color: context.cs.error)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'category-add',
        onPressed: () => _openForm(),
        icon: const Icon(LucideIcons.plus),
        label: const Text('Thêm danh mục'),
      ),
      body: Column(children: [
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              for (final e in _filters.entries) ...[
                ChoiceChip(
                  label: Text(e.value),
                  selected: _type == e.key,
                  onSelected: (_) {
                    setState(() => _type = e.key);
                    _load();
                  },
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _loadFailed
                  ? RetryView(onRetry: _load)
                  : _tree.isEmpty
                      ? Center(
                          child: Text('Chưa có danh mục nào.', style: TextStyle(color: context.textMuted)))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                            children: [
                              for (final root in _tree)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Card(
                                    clipBehavior: Clip.antiAlias,
                                    child: Column(children: [
                                      _tile(root, isRoot: true),
                                      for (final child in root.children) _tile(child, isRoot: false),
                                    ]),
                                  ),
                                ),
                            ],
                          ),
                        ),
        ),
      ]),
    );
  }
}

/// Form thêm/sửa danh mục. edit == null: thêm mới (parent != null -> danh mục con).
/// Danh mục gốc cần chọn loại; danh mục con thừa hưởng loại của cha.
class _CategoryForm extends StatefulWidget {
  final CategoryNode? edit;
  final CategoryNode? parent;
  const _CategoryForm({this.edit, this.parent});

  @override
  State<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<_CategoryForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.edit?.name ?? '');
  late final _order = TextEditingController(text: '${widget.edit?.displayOrder ?? 0}');
  late String _type = widget.edit?.type ?? widget.parent?.type ?? 'RECIPE_TYPE';
  late bool _active = widget.edit?.active ?? true;
  bool _busy = false;

  bool get _isRoot => widget.edit != null ? widget.edit!.parentId == null : widget.parent == null;

  @override
  void dispose() {
    _name.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final repo = context.read<BlogRepository>();
    final name = _name.text.trim();
    final order = int.tryParse(_order.text.trim()) ?? 0;
    try {
      if (widget.edit == null) {
        await repo.createCategory(
            name: name,
            type: _isRoot ? _type : null,
            parentId: widget.parent?.id,
            displayOrder: order,
            active: _active);
      } else {
        await repo.updateCategory(widget.edit!.id,
            name: name, type: _isRoot ? _type : null, displayOrder: order, active: _active);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e), title: 'Không lưu được danh mục');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.edit != null
        ? 'Sửa danh mục'
        : widget.parent != null
            ? 'Thêm danh mục con của "${widget.parent!.name}"'
            : 'Thêm danh mục';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Form(
        key: _form,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _name,
            maxLength: 100,
            decoration: const InputDecoration(
                labelText: 'Tên danh mục',
                hintText: 'Nhập tên danh mục',
                prefixIcon: Icon(LucideIcons.tag)),
            validator: (v) => v!.trim().isEmpty ? 'Vui lòng nhập tên danh mục' : null,
          ),
          const SizedBox(height: 8),
          if (_isRoot) ...[
            FullWidthSegmented<String>(
              options: const [
                SegmentOption('RECIPE_TYPE', 'Loại công thức'),
                SegmentOption('FOOD_TYPE', 'Loại thực phẩm'),
              ],
              selected: _type,
              onChanged: (v) => setState(() => _type = v),
            ),
            const SizedBox(height: 12),
          ] else
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('Loại: ${_typeLabel(_type)} (thừa hưởng từ danh mục cha)',
                  style: TextStyle(color: context.textMuted)),
            ),
          TextFormField(
            controller: _order,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Thứ tự hiển thị',
                hintText: 'Số nhỏ hiện trước',
                prefixIcon: Icon(LucideIcons.arrowDownUp)),
            validator: (v) => v!.trim().isNotEmpty && int.tryParse(v.trim()) == null
                ? 'Vui lòng nhập số nguyên'
                : null,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Hiển thị cho người dùng'),
            subtitle: const Text('Tắt để ẩn danh mục khỏi danh sách công khai'),
            value: _active,
            onChanged: (v) => setState(() => _active = v),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Lưu'),
            ),
          ),
        ]),
      ),
    );
  }
}
