import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/login_screen.dart';
import '../data/meal_models.dart';
import '../data/meal_repository.dart';

/// Phần "Nguyên liệu của tôi": quản lý nguyên liệu đang có trong tủ (cần đăng nhập).
/// API: GET/POST /nutrition/me/ingredients, PATCH/DELETE /nutrition/me/ingredients/{id}.
/// Khi tạo thực đơn, BE tự ưu tiên các món dùng nguyên liệu trong tủ này.
class PantryTab extends StatefulWidget {
  const PantryTab({super.key});

  @override
  State<PantryTab> createState() => _PantryTabState();
}

class _PantryTabState extends State<PantryTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<PantryItem> _items = [];
  bool _loading = false;
  bool _loadFailed = false;
  int? _loadedFor; // userId đã nạp dữ liệu

  void _syncWithUser(int? userId) {
    if (_loadedFor == userId) return;
    _loadedFor = userId;
    if (userId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _items = []);
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final r = await context.read<MealRepository>().pantry();
      if (mounted) setState(() => _items = r);
    } catch (e) {
      if (mounted) {
        setState(() => _loadFailed = true);
        showErrorDialog(context, errorMessage(e), title: 'Không tải được nguyên liệu');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([PantryItem? item]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _PantryForm(item),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(PantryItem item) async {
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
    if (ok != true || !mounted) return;
    try {
      await context.read<MealRepository>().deletePantryItem(item.id);
      if (!mounted) return;
      setState(() => _items = _items.where((e) => e.id != item.id).toList());
      showSnack(context, 'Đã xoá "${item.name}"');
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e), title: 'Không xoá được');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final auth = context.watch<AuthController>();
    _syncWithUser(auth.user?.id);

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
        onPressed: () => _openForm(),
        icon: const Icon(LucideIcons.plus),
        label: const Text('Thêm nguyên liệu'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadFailed
              ? RetryView(onRetry: _load)
              : _items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                            'Tủ nguyên liệu đang trống. Thêm nguyên liệu bạn có để AI ưu tiên các món dùng chúng khi tạo thực đơn.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: context.textMuted)),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _PantryCard(
                          _items[i],
                          onEdit: () => _openForm(_items[i]),
                          onDelete: () => _delete(_items[i]),
                        ),
                      ),
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
    final left = item.daysLeft;
    final expired = left != null && left < 0;
    final soon = left != null && left >= 0 && left <= 3;
    final warn = expired || soon;
    final hasQuantity = (item.quantity ?? '').trim().isNotEmpty;
    final hasUnit = (item.unit ?? '').trim().isNotEmpty;
    final expiryText = item.expiryDate == null
        ? null
        : expired
            ? 'Đã hết hạn (${fmtDate(item.expiryDate!)})'
            : soon
                ? 'Còn $left ngày (${fmtDate(item.expiryDate!)})'
                : 'HSD: ${fmtDate(item.expiryDate!)}';

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
              if (hasQuantity || hasUnit || expiryText != null) const SizedBox(height: 6),
              if (hasQuantity || hasUnit)
                Wrap(spacing: 16, runSpacing: 4, children: [
                  if (hasQuantity)
                    _info(context, LucideIcons.hash, 'Số lượng: ${item.quantity!.trim()}'),
                  if (hasUnit) _info(context, LucideIcons.scale, 'Đơn vị: ${item.unit!.trim()}'),
                ]),
              if ((hasQuantity || hasUnit) && expiryText != null) const SizedBox(height: 4),
              if (expiryText != null)
                _info(context, warn ? LucideIcons.triangleAlert : LucideIcons.calendar, expiryText,
                    color: warn ? context.cs.error : null),
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

/// Form thêm/sửa nguyên liệu (item == null -> thêm mới).
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
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _unit.dispose();
    super.dispose();
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

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final repo = context.read<MealRepository>();
    final name = _name.text.trim();
    final qty = _quantity.text.trim();
    final unit = _unit.text.trim();
    final expiry = _expiry == null ? null : isoDate(_expiry!);
    try {
      if (widget.item == null) {
        await repo.addPantryItem(
          name: name,
          quantity: qty.isEmpty ? null : qty,
          unit: unit.isEmpty ? null : unit,
          expiryDate: expiry,
        );
      } else {
        // BE bỏ qua trường rỗng/null (giữ giá trị cũ), nên chỉ gửi những gì đã nhập.
        await repo.updatePantryItem(
          widget.item!.id,
          name: name,
          quantity: qty.isEmpty ? null : qty,
          unit: unit.isEmpty ? null : unit,
          expiryDate: expiry,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e), title: 'Không lưu được nguyên liệu');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
                labelText: 'Tên nguyên liệu',
                hintText: 'Ví dụ: Nấm hương, đậu hũ...',
                prefixIcon: Icon(LucideIcons.leaf)),
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
