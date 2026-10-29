import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/common_widgets.dart';
import '../data/meal_plan_models.dart';

/// Bottom sheet chọn một thực đơn đã lưu (của tôi / yêu thích). Trả về thực đơn được chọn.
Future<MealPlan?> showPlanPicker(
  BuildContext context, {
  required String title,
  required String emptyText,
  required Future<List<MealPlan>> Function() load,
}) {
  return showModalBottomSheet<MealPlan>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _SheetList<MealPlan>(
      title: title,
      emptyText: emptyText,
      load: load,
      tileBuilder: (ctx, p) => ListTile(
        leading: Icon(p.isFavorite ? Icons.favorite : Icons.calendar_month,
            color: p.isFavorite ? Colors.redAccent : ctx.cs.primary),
        title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text([
          if (p.goalSummary.isNotEmpty) p.goalSummary,
          if (p.createdAt != null) fmtDate(p.createdAt!.toLocal()),
        ].join(' • ')),
        onTap: () => Navigator.pop(ctx, p),
      ),
    ),
  );
}

/// Bottom sheet lịch sử phiên bản của một thực đơn. Trả về phiên bản được chọn để xem (chỉ đọc).
Future<MealPlanVersion?> showVersionPicker(
  BuildContext context, {
  required int currentVersion,
  required Future<List<MealPlanVersion>> Function() load,
}) {
  return showModalBottomSheet<MealPlanVersion>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _SheetList<MealPlanVersion>(
      title: 'Lịch sử phiên bản',
      emptyText: 'Thực đơn này chưa có phiên bản nào.',
      load: load,
      tileBuilder: (ctx, v) => ListTile(
        leading: CircleAvatar(
          backgroundColor: v.version == currentVersion ? ctx.cs.primary : AppColors.accent,
          foregroundColor: v.version == currentVersion ? ctx.cs.onPrimary : Colors.black87,
          child: Text('${v.version}'),
        ),
        title: Text(v.changeSummary.isEmpty ? 'Phiên bản ${v.version}' : v.changeSummary,
            maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text([
          if (v.version == currentVersion) 'Hiện tại',
          if (v.createdAt != null) fmtDateTime(v.createdAt!.toLocal()),
        ].join(' • ')),
        onTap: () => Navigator.pop(ctx, v),
      ),
    ),
  );
}

/// Danh sách tải bất đồng bộ trong bottom sheet: vòng quay khi tải, thử lại khi lỗi, thông báo khi rỗng.
class _SheetList<T> extends StatefulWidget {
  final String title;
  final String emptyText;
  final Future<List<T>> Function() load;
  final Widget Function(BuildContext, T) tileBuilder;
  const _SheetList({
    required this.title,
    required this.emptyText,
    required this.load,
    required this.tileBuilder,
  });

  @override
  State<_SheetList<T>> createState() => _SheetListState<T>();
}

class _SheetListState<T> extends State<_SheetList<T>> {
  late Future<List<T>> _future = widget.load();

  void _retry() => setState(() => _future = widget.load());

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
              title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
          Flexible(
            child: FutureBuilder<List<T>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                      padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()));
                }
                if (snap.hasError) {
                  return RetryView(message: errorMessage(snap.error!), onRetry: _retry);
                }
                final items = snap.data!;
                if (items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                        child: Text(widget.emptyText, style: TextStyle(color: context.textMuted))),
                  );
                }
                return ListView(
                  shrinkWrap: true,
                  children: [for (final i in items) widget.tileBuilder(context, i)],
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
