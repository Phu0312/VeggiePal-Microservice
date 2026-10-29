import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/common_widgets.dart';
import '../data/ingredient_models.dart';
import '../data/ingredient_repository.dart';

/// Bottom sheet tìm nguyên liệu trong danh mục (GET /ingredients?keyword=). Bấm một mục để chọn.
/// [excludeIds] là các nguyên liệu không cho chọn nữa (vd đã có trong công thức, BE không cho trùng - lỗi 4105).
Future<Ingredient?> showIngredientPicker(BuildContext context, {Set<int> excludeIds = const {}}) {
  return showModalBottomSheet<Ingredient>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _IngredientPicker(excludeIds: excludeIds),
  );
}

class _IngredientPicker extends StatefulWidget {
  final Set<int> excludeIds;
  const _IngredientPicker({required this.excludeIds});

  @override
  State<_IngredientPicker> createState() => _IngredientPickerState();
}

class _IngredientPickerState extends State<_IngredientPicker> {
  final _text = TextEditingController();
  Timer? _debounce;
  List<Ingredient> _results = [];
  bool _loading = true;
  String? _error;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _text.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(v.trim()));
  }

  Future<void> _search(String keyword) async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Lấy dư kết quả để vẫn đủ sau khi ẩn các nguyên liệu đã chọn.
      final r = await context
          .read<IngredientRepository>()
          .page(keyword: keyword, size: 20 + widget.excludeIds.length);
      if (!mounted || request != _request) return;
      setState(() => _results = r.items.where((i) => !widget.excludeIds.contains(i.id)).take(20).toList());
    } catch (e) {
      if (mounted && request == _request) setState(() => _error = errorMessage(e));
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _text,
              autofocus: true,
              onChanged: _onChanged,
              decoration: const InputDecoration(
                  hintText: 'Tìm nguyên liệu (vd: đậu hũ, nấm hương...)',
                  prefixIcon: Icon(LucideIcons.search)),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? RetryView(message: _error!, onRetry: () => _search(_text.text.trim()))
                    : _results.isEmpty
                        ? Center(
                            child: Text(
                                _text.text.trim().isEmpty
                                    ? 'Không còn nguyên liệu nào để thêm.'
                                    : 'Không tìm thấy nguyên liệu phù hợp.',
                                style: TextStyle(color: context.textMuted)))
                        : ListView.separated(
                            itemCount: _results.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final g = _results[i];
                              return ListTile(
                                onTap: () => Navigator.pop(context, g),
                                title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                // description ghi trạng thái nguyên liệu (sống / chín / khô): chọn nhầm thì calo lệch nhiều lần.
                                subtitle: Text(
                                    [
                                      '${g.calories.round()} kcal • ${g.protein.toStringAsFixed(1)}g đạm / 100g',
                                      if (g.hasDescription) g.description!.trim(),
                                    ].join('\n'),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis),
                                isThreeLine: g.hasDescription,
                                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                  if (g.allergen)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 6),
                                      child: Icon(LucideIcons.triangleAlert, size: 16, color: Colors.deepOrange),
                                    ),
                                  if (g.vegan) Icon(LucideIcons.leaf, size: 16, color: context.cs.primary),
                                ]),
                              );
                            },
                          ),
          ),
        ]),
      ),
    );
  }
}
