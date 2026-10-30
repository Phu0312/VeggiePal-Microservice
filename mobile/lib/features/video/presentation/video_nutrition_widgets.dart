import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/common_widgets.dart';
import '../data/video_models.dart';
import '../data/video_repository.dart';

/// Thẻ dinh dưỡng và nguyên liệu do người đăng khai báo cho video (không phải kết quả AI). [onEdit] có thì hiện nút sửa
/// (chủ video và ADMIN).
class VideoNutritionCard extends StatelessWidget {
  final VideoNutrition? nutrition;
  final VoidCallback? onEdit;
  const VideoNutritionCard({super.key, required this.nutrition, this.onEdit});

  Widget _macro(BuildContext context, String label, String value) => Expanded(
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.cs.primary)),
          Text(label, style: TextStyle(fontSize: 12, color: context.textMuted)),
        ]),
      );

  String _g(double? v) => v == null ? '-' : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final n = nutrition;
    if (n == null && onEdit == null) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(
                  (n?.servingLabel ?? '').isEmpty ? 'Dinh dưỡng và nguyên liệu' : 'Dinh dưỡng • ${n!.servingLabel}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
            if (onEdit != null)
              IconButton(tooltip: 'Sửa dinh dưỡng', onPressed: onEdit, icon: const Icon(LucideIcons.pencil, size: 18)),
          ]),
          if (n == null)
            Text('Người đăng chưa khai báo dinh dưỡng cho video này.', style: TextStyle(color: context.textMuted))
          else ...[
            if (n.hasMacros) ...[
              const SizedBox(height: 8),
              Row(children: [
                _macro(context, 'kcal', n.kcal?.toString() ?? '-'),
                _macro(context, 'Đạm (g)', _g(n.protein)),
                _macro(context, 'Tinh bột (g)', _g(n.carbs)),
                _macro(context, 'Béo (g)', _g(n.fat)),
              ]),
              if (n.fiber != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('Chất xơ: ${_g(n.fiber)}g', style: TextStyle(fontSize: 12.5, color: context.textMuted)),
                ),
            ],
            if (n.ingredients.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('Nguyên liệu', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              for (final i in n.ingredients)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text((i.amount ?? '').isEmpty ? '• ${i.name}' : '• ${i.name} — ${i.amount}'),
                ),
            ],
          ],
        ]),
      ),
    );
  }
}

/// Mở hộp sửa dinh dưỡng của video (PUT /videos/{id}/nutrition). Trả về dinh dưỡng đã lưu hoặc null nếu hủy.
Future<VideoNutrition?> showEditVideoNutrition(BuildContext context, int videoId, VideoNutrition? current) =>
    showModalBottomSheet<VideoNutrition>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _EditNutritionSheet(videoId: videoId, current: current),
      ),
    );

class _EditNutritionSheet extends StatefulWidget {
  final int videoId;
  final VideoNutrition? current;
  const _EditNutritionSheet({required this.videoId, required this.current});

  @override
  State<_EditNutritionSheet> createState() => _EditNutritionSheetState();
}

class _EditNutritionSheetState extends State<_EditNutritionSheet> {
  final _form = GlobalKey<FormState>();
  late final _serving = TextEditingController(text: widget.current?.servingLabel ?? '');
  late final _kcal = TextEditingController(text: widget.current?.kcal?.toString() ?? '');
  late final _protein = TextEditingController(text: _fmt(widget.current?.protein));
  late final _carbs = TextEditingController(text: _fmt(widget.current?.carbs));
  late final _fat = TextEditingController(text: _fmt(widget.current?.fat));
  late final _fiber = TextEditingController(text: _fmt(widget.current?.fiber));
  late final _ingredients =
      TextEditingController(text: VideoNutrition.ingredientLines(widget.current?.ingredients ?? const []));
  bool _busy = false;

  static String _fmt(double? v) => v == null ? '' : (v == v.roundToDouble() ? v.round().toString() : v.toString());

  @override
  void dispose() {
    for (final c in [_serving, _kcal, _protein, _carbs, _fat, _fiber, _ingredients]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _num(String s) => s.trim().isEmpty ? null : double.tryParse(s.trim().replaceAll(',', '.'));

  String? _check(String? v) {
    if ((v ?? '').trim().isEmpty) return null;
    final n = double.tryParse(v!.trim().replaceAll(',', '.'));
    return n == null || n < 0 ? 'Nhập số từ 0 trở lên' : null;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final repo = context.read<VideoRepository>();
    final n = VideoNutrition(
      servingLabel: _serving.text.trim().isEmpty ? null : _serving.text.trim(),
      kcal: _num(_kcal.text)?.round(),
      protein: _num(_protein.text),
      carbs: _num(_carbs.text),
      fat: _num(_fat.text),
      fiber: _num(_fiber.text),
      ingredients: VideoNutrition.parseIngredientLines(_ingredients.text),
    );
    setState(() => _busy = true);
    try {
      final saved = await repo.updateNutrition(widget.videoId, n);
      if (mounted) Navigator.of(context).pop(saved ?? n);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showErrorDialog(context, errorMessage(e), title: 'Không lưu được dinh dưỡng');
      }
    }
  }

  Widget _numField(String label, TextEditingController c, String suffix) => TextFormField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label, suffixText: suffix),
        validator: _check,
      );

  @override
  Widget build(BuildContext context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Form(
            key: _form,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Dinh dưỡng của video', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _serving,
                  maxLength: 100,
                  decoration: const InputDecoration(labelText: 'Khẩu phần (ví dụ: 1 tô, 2 người ăn)', counterText: '')),
              const SizedBox(height: 12),
              _numField('Năng lượng', _kcal, 'kcal'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _numField('Đạm', _protein, 'g')),
                const SizedBox(width: 8),
                Expanded(child: _numField('Tinh bột', _carbs, 'g')),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _numField('Chất béo', _fat, 'g')),
                const SizedBox(width: 8),
                Expanded(child: _numField('Chất xơ', _fiber, 'g')),
              ]),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ingredients,
                minLines: 3,
                maxLines: 8,
                decoration: const InputDecoration(
                    labelText: 'Nguyên liệu (mỗi dòng một món: tên | lượng)',
                    hintText: 'Đậu hũ | 200g\nCà chua | 2 quả',
                    alignLabelWithHint: true),
              ),
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
