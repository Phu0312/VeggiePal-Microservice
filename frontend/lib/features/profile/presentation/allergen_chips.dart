import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../data/profile_models.dart';

/// Danh mục chất gây dị ứng chia theo nhóm (Ngũ cốc, Đậu, Hạt, ...), mỗi chất là một FilterChip
/// chọn được nhiều. Dùng chung cho màn "Dị ứng thực phẩm" và bộ lọc công thức.
class AllergenGroupedChips extends StatelessWidget {
  final List<Allergen> catalog;
  final Set<int> selected;
  final void Function(Allergen allergen, bool selected) onChanged;

  const AllergenGroupedChips({
    super.key,
    required this.catalog,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Giữ thứ tự nhóm của backend; nhóm lạ (nếu có) xếp cuối.
    final groups = <String, List<Allergen>>{
      for (final k in Allergen.categoryLabels.keys) k: [],
    };
    for (final a in catalog) {
      groups.putIfAbsent(a.category, () => []).add(a);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final e in groups.entries)
        if (e.value.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(Allergen.categoryLabels[e.key] ?? e.key,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700, color: context.cs.primary)),
          ),
          Wrap(spacing: 8, runSpacing: 4, children: [
            for (final a in e.value)
              FilterChip(
                label: Text(a.name),
                selected: selected.contains(a.id),
                onSelected: (v) => onChanged(a, v),
              ),
          ]),
        ],
    ]);
  }
}
