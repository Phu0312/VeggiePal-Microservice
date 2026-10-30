import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/common_widgets.dart';
import '../data/diary_models.dart';
import '../data/diary_repository.dart';

/// Đọc số từ ô nhập: bỏ trống là null, chấp nhận dấu phẩy thập phân. Không phải số hoặc số âm thì trả `double.nan`.
double? parseAmount(String? text) {
  final t = (text ?? '').trim().replaceAll(',', '.');
  if (t.isEmpty) return null;
  final v = double.tryParse(t);
  return (v == null || v < 0) ? double.nan : v;
}

String? _amountError(String? v) => (parseAmount(v)?.isNaN ?? false) ? 'Nhập số từ 0 trở lên' : null;

/// Mở hộp ghi một món vào nhật ký ngày [date] (POST /nutrition/me/food-logs). [prefill] điền sẵn tên và dinh dưỡng
/// (vd từ một công thức). Trả về `true` nếu đã ghi.
Future<bool> showAddFoodSheet(BuildContext context, {required DateTime date, MealSlot? meal, FoodDraft? prefill}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: AddFoodSheet(date: date, meal: meal ?? prefill?.meal ?? MealSlot.forTime(DateTime.now()), prefill: prefill),
    ),
  );
  return saved == true;
}

/// Biểu mẫu ghi món: tên, bữa, calo và các chất dinh dưỡng (không bắt buộc, bỏ trống tính là 0).
class AddFoodSheet extends StatefulWidget {
  final DateTime date;
  final MealSlot meal;
  final FoodDraft? prefill;
  const AddFoodSheet({super.key, required this.date, required this.meal, this.prefill});

  @override
  State<AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<AddFoodSheet> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.prefill?.name ?? '');
  late final _calories = TextEditingController(text: _fmt(widget.prefill?.calories));
  late final _protein = TextEditingController(text: _fmt(widget.prefill?.protein));
  late final _carbs = TextEditingController(text: _fmt(widget.prefill?.carbs));
  late final _fat = TextEditingController(text: _fmt(widget.prefill?.fat));
  late final _fiber = TextEditingController(text: _fmt(widget.prefill?.fiber));
  late MealSlot _meal = widget.meal;
  bool _busy = false;

  static String _fmt(num? v) => v == null ? '' : (v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1));

  @override
  void dispose() {
    for (final c in [_name, _calories, _protein, _carbs, _fat, _fiber]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final repo = context.read<DiaryRepository>();
    setState(() => _busy = true);
    try {
      await repo.addFood(
        widget.date,
        FoodDraft(
          name: _name.text,
          meal: _meal,
          recipeId: widget.prefill?.recipeId,
          calories: parseAmount(_calories.text)?.round(),
          protein: parseAmount(_protein.text),
          carbs: parseAmount(_carbs.text),
          fat: parseAmount(_fat.text),
          fiber: parseAmount(_fiber.text),
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showErrorDialog(context, errorMessage(e), title: 'Không ghi được món ăn');
      }
    }
  }

  Widget _numField(String label, TextEditingController c, {String suffix = 'g'}) => TextFormField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label, suffixText: suffix),
        validator: _amountError,
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Form(
          key: _form,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Ghi món ăn • ${fmtDate(widget.date)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Tên món', counterText: ''),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Vui lòng nhập tên món' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<MealSlot>(
              initialValue: _meal,
              decoration: const InputDecoration(labelText: 'Bữa'),
              items: [for (final m in MealSlot.values) DropdownMenuItem(value: m, child: Text(m.label))],
              onChanged: (m) => setState(() => _meal = m ?? _meal),
            ),
            const SizedBox(height: 12),
            _numField('Năng lượng', _calories, suffix: 'kcal'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _numField('Đạm', _protein)),
              const SizedBox(width: 8),
              Expanded(child: _numField('Tinh bột', _carbs)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _numField('Chất béo', _fat)),
              const SizedBox(width: 8),
              Expanded(child: _numField('Chất xơ', _fiber)),
            ]),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Ghi vào nhật ký'),
            ),
          ]),
        ),
      ),
    );
  }
}
