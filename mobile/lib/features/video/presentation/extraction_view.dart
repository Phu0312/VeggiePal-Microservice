import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../data/video_models.dart';

/// Công thức AI bóc tách từ video: nguyên liệu kèm số lượng và các bước. [maxSteps] (nếu có) chỉ hiện vài bước đầu.
class ExtractionView extends StatelessWidget {
  final VideoExtraction extraction;
  final int? maxSteps;
  const ExtractionView(this.extraction, {super.key, this.maxSteps});

  @override
  Widget build(BuildContext context) {
    final steps = maxSteps == null ? extraction.steps : extraction.steps.take(maxSteps!).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(extraction.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      const Text('Nguyên liệu', style: TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      for (final i in extraction.ingredients)
        Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: context.cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Expanded(child: Text(i.name)),
            const SizedBox(width: 12),
            Text(i.quantity, style: TextStyle(color: context.textMuted)),
          ]),
        ),
      const SizedBox(height: 12),
      const Text('Các bước thực hiện', style: TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      for (final s in steps)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.accent,
              child: Text('${s.number}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(s.instruction, style: const TextStyle(height: 1.4))),
          ]),
        ),
      if (steps.length < extraction.steps.length)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('… và ${extraction.steps.length - steps.length} bước nữa',
              style: TextStyle(color: context.textMuted)),
        ),
    ]);
  }
}

/// Kết quả đầy đủ của một lượt bóc tách (công thức + lời trong video) trong bottom sheet.
Future<void> showJobResultSheet(BuildContext context, VideoJob job) {
  final extraction = job.extraction;
  if (extraction == null) return Future.value();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (ctx, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text('Từ ${job.sourceVideoId != null ? job.sourceLabel.toLowerCase() : 'video “${job.filename}”'}',
              style: TextStyle(fontSize: 12.5, color: ctx.textMuted)),
          const SizedBox(height: 6),
          ExtractionView(extraction),
          if ((job.transcript ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Lời trong video', style: TextStyle(fontWeight: FontWeight.w700)),
              children: [Text(job.transcript!.trim(), style: const TextStyle(height: 1.4))],
            ),
          ],
          const SizedBox(height: 12),
          Text('Kết quả do AI tạo từ lời trong video, bạn nên đối chiếu lại trước khi dùng.',
              style: TextStyle(fontSize: 12, color: ctx.textMuted)),
        ],
      ),
    ),
  );
}
