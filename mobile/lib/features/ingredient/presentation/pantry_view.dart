import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/format.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/login_screen.dart';
import '../data/ingredient_models.dart';
import '../data/pantry_controller.dart';
import 'ingredient_picker.dart';

/// "Tủ của tôi": nguyên liệu đang có, lưu trên máy theo tài khoản (cần đăng nhập). Khi tạo thực đơn tuần,
/// nút "Dùng nguyên liệu trong tủ" ở tab Thực đơn gửi các nguyên liệu còn hạn cho AI để ưu tiên các món dùng chúng.
class PantryView extends StatelessWidget {
  const PantryView({super.key});

  Future<void> _openForm(BuildContext context, [PantryItem? item]) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _PantryForm(item),
      ),
    );
  }

  Future<void> _delete(BuildContext context, PantryItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá nguyên liệu'),
        content: Text('Bạn có chắc muốn xoá "${item.name}" khỏi tủ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xoá')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    context.read<PantryController>().remove(item);
    showSnack(context, 'Đã xoá "${item.name}"');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final items = context.watch<PantryController>().items;

    if (!auth.isLoggedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(LucideIcons.refrigerator, size: 64, color: context.textMuted),
            const SizedBox(height: 12),
            Text('Đăng nhập để quản lý nguyên liệu trong tủ của bạn.',
                textAlign: TextAlign.center, style: TextStyle(color: context.textMuted)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const LoginScreen())),
              icon: const Icon(LucideIcons.logIn),
              label: const Text('Đăng nhập / Đăng ký'),
            ),
          ]),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'pantry-add',
        onPressed: () => _openForm(context),
        icon: const Icon(LucideIcons.plus),
        label: const Text('Thêm nguyên liệu'),
      ),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                    'Tủ nguyên liệu đang trống. Thêm nguyên liệu bạn có (hoặc chọn từ tab Danh mục) để điền nhanh khi tạo thực đơn tuần.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.textMuted)),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: items.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                if (i == 0) {
                  return Text('Tủ được lưu trên máy này, không đồng bộ lên máy chủ.',
                      style: TextStyle(fontSize: 12.5, color: context.textMuted));
                }
                final item = items[i - 1];
                return _PantryCard(item,
                    onEdit: () => _openForm(context, item), onDelete: () => _delete(context, item));
              },
            ),
    );
  }
}

class _PantryCard extends StatelessWidget {
  final PantryItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _PantryCard(this.item, {required this.onEdit, required this.onDelete});

  /// Một dòng thông tin nhỏ: icon + chữ, cùng cỡ để các dòng thẳng hàng.
  Widget _info(BuildContext context, IconData icon, String text, {Color? color}) {
    final c = color ?? context.textMuted;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 15, color: c),
      const SizedBox(width: 6),
      Flexible(child: Text(text, style: TextStyle(fontSize: 13, color: c))),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final left = item.daysLeft();
    final expired = left != null && left < 0;
    final soon = left != null && left >= 0 && left <= 3;
    final expiry = item.expiryDate;
    final expiryText = expiry == null
        ? null
        : expired
            ? 'Đã hết hạn (${fmtDate(expiry)}), không dùng khi tạo thực đơn'
            : soon
                ? 'Còn $left ngày (${fmtDate(expiry)})'
                : 'HSD: ${fmtDate(expiry)}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: context.cs.primaryContainer, borderRadius: BorderRadius.circular(14)),
            child: Icon(LucideIcons.leaf, color: context.cs.onPrimaryContainer, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              if (item.amountText.isNotEmpty || expiryText != null) const SizedBox(height: 6),
              if (item.amountText.isNotEmpty)
                _info(context, LucideIcons.scale, item.amountText),
              if (item.amountText.isNotEmpty && expiryText != null) const SizedBox(height: 4),
              if (expiryText != null)
                _info(context, (expired || soon) ? LucideIcons.triangleAlert : LucideIcons.calendar,
                    expiryText,
                    color: (expired || soon) ? context.cs.error : null),
            ]),
          ),
          IconButton(
              tooltip: 'Sửa', onPressed: onEdit, icon: const Icon(LucideIcons.pencil, size: 20)),
          IconButton(
              tooltip: 'Xoá',
              onPressed: onDelete,
              icon: Icon(LucideIcons.trash2, size: 20, color: context.cs.error)),
        ]),
      ),
    );
  }
}

/// Form thêm/sửa nguyên liệu trong tủ (item == null -> thêm mới).
/// Nên chọn tên từ danh mục để AI khớp được với nguyên liệu của công thức.
class _PantryForm extends StatefulWidget {
  final PantryItem? item;
  const _PantryForm(this.item);

  @override
  State<_PantryForm> createState() => _PantryFormState();
}

class _PantryFormState extends State<_PantryForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.item?.name ?? '');
  late final _quantity = TextEditingController(text: widget.item?.quantity ?? '');
  late final _unit = TextEditingController(text: widget.item?.unit ?? '');
  late DateTime? _expiry = widget.item?.expiryDate;

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _unit.dispose();
    super.dispose();
  }

  Future<void> _pickFromCatalog() async {
    final g = await showIngredientPicker(context);
    if (g != null && mounted) setState(() => _name.text = g.name);
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _expiry ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: 'Chọn hạn sử dụng',
    );
    if (d != null) setState(() => _expiry = d);
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    final pantry = context.read<PantryController>();
    final item = PantryItem(
      name: _name.text.trim().replaceAll(RegExp(r'\s+'), ' '),
      quantity: _quantity.text.trim(),
      unit: _unit.text.trim(),
      expiryDate: _expiry,
    );
    final ok = widget.item == null ? pantry.add(item) : pantry.update(widget.item!, item);
    if (!ok) {
      showErrorDialog(context, '"${item.name}" đã có trong tủ.', title: 'Không lưu được nguyên liệu');
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Form(
        key: _form,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(widget.item == null ? 'Thêm nguyên liệu' : 'Sửa nguyên liệu',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _name,
            maxLength: 100, // backend giới hạn 100 ký tự cho mỗi nguyên liệu khi tạo thực đơn
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Tên nguyên liệu',
              hintText: 'Ví dụ: Nấm hương, đậu hũ...',
              prefixIcon: const Icon(LucideIcons.leaf),
              counterText: '',
              suffixIcon: IconButton(
                tooltip: 'Chọn từ danh mục',
                icon: const Icon(LucideIcons.search),
                onPressed: _pickFromCatalog,
              ),
            ),
            validator: (v) => v!.trim().isEmpty ? 'Vui lòng nhập tên nguyên liệu' : null,
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _quantity,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                    labelText: 'Số lượng', hintText: 'Ví dụ: 500', prefixIcon: Icon(LucideIcons.hash)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _unit,
                decoration: const InputDecoration(
                    labelText: 'Đơn vị', hintText: 'g, kg, bó...', prefixIcon: Icon(LucideIcons.scale)),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _pickExpiry,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Hạn sử dụng',
                prefixIcon: const Icon(LucideIcons.calendar),
                suffixIcon: _expiry == null
                    ? null
                    : IconButton(
                        tooltip: 'Bỏ chọn',
                        icon: const Icon(LucideIcons.x, size: 18),
                        onPressed: () => setState(() => _expiry = null),
                      ),
              ),
              child: Text(_expiry == null ? 'Không bắt buộc' : fmtDate(_expiry!),
                  style: TextStyle(color: _expiry == null ? context.textMuted : null)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: _submit, child: const Text('Lưu')),
          ),
        ]),
      ),
    );
  }
}
