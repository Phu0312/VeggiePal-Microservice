import 'package:flutter/material.dart';

import '../../../core/widgets/common_widgets.dart';
import 'ingredient_catalog_view.dart';
import 'pantry_view.dart';

/// Phần "Nguyên liệu" của tab Thực đơn: "Tủ của tôi" (nguyên liệu đang có, lưu trên máy)
/// và "Danh mục" (nguyên liệu chung của hệ thống, kèm dinh dưỡng).
class IngredientTab extends StatefulWidget {
  const IngredientTab({super.key});

  @override
  State<IngredientTab> createState() => _IngredientTabState();
}

class _IngredientTabState extends State<IngredientTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int _view = 0;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: FullWidthSegmented<int>(
          options: const [SegmentOption(0, 'Tủ của tôi'), SegmentOption(1, 'Danh mục')],
          selected: _view,
          onChanged: (v) => setState(() => _view = v),
        ),
      ),
      // IndexedStack giữ trạng thái (từ khoá, trang đã cuộn) của từng phần khi chuyển qua lại.
      Expanded(
        child: IndexedStack(index: _view, children: const [PantryView(), IngredientCatalogView()]),
      ),
    ]);
  }
}
