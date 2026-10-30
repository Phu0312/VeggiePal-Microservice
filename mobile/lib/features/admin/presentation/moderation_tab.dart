import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/format.dart';
import '../../../core/utils/moderation.dart';
import '../../../core/widgets/common_widgets.dart';
import '../data/admin_models.dart';
import '../data/admin_repository.dart';

/// Hàng đợi kiểm duyệt nội dung (GET /ai/admin/moderation): các ca AI chưa chắc chắn (REVIEW_REQUIRED).
/// Admin chọn Duyệt (nội dung được đăng), Từ chối (nội dung bị chặn) hoặc Bỏ qua (chỉ đưa ca ra khỏi hàng đợi,
/// nội dung gốc không đổi trạng thái). Mỗi quyết định có thể kèm lý do.
class ModerationTab extends StatefulWidget {
  const ModerationTab({super.key});

  @override
  State<ModerationTab> createState() => _ModerationTabState();
}

enum _Decision { approve, reject, dismiss }

class _ModerationTabState extends State<ModerationTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<ModerationCase> _cases = [];
  bool _loading = true;
  bool _failed = false;
  final _busy = <int>{}; // các ca đang gửi quyết định

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final r = await context.read<AdminRepository>().pendingCases();
      if (mounted) setState(() => _cases = r);
    } catch (e) {
      if (mounted) {
        setState(() => _failed = true);
        showErrorDialog(context, errorMessage(e), title: 'Không tải được hàng đợi kiểm duyệt');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _decide(ModerationCase c, _Decision d) async {
    final reason = await _askReason(c, d);
    if (reason == null || !mounted) return; // bấm Hủy
    final repo = context.read<AdminRepository>();
    setState(() => _busy.add(c.caseId));
    try {
      switch (d) {
        case _Decision.approve:
          await repo.review(c.caseId, approve: true, reason: reason);
        case _Decision.reject:
          await repo.review(c.caseId, approve: false, reason: reason);
        case _Decision.dismiss:
          await repo.dismiss(c.caseId, reason: reason);
      }
      if (!mounted) return;
      setState(() => _cases = _cases.where((x) => x.caseId != c.caseId).toList());
      showSnack(
          context,
          switch (d) {
            _Decision.approve => 'Đã duyệt nội dung',
            _Decision.reject => 'Đã từ chối nội dung',
            _Decision.dismiss => 'Đã bỏ qua ca kiểm duyệt',
          });
    } catch (e) {
      if (!mounted) return;
      // Ngừng vòng quay trước khi hiện popup, nếu không nó quay mãi sau lưng popup.
      setState(() => _busy.remove(c.caseId));
      // 6012 / 6013: ca không còn xử lý được nữa, tải lại để hàng đợi khớp backend.
      final stale = e is ApiException && (e.code == 6012 || e.code == 6013);
      await showErrorDialog(context, errorMessage(e), title: 'Không xử lý được ca kiểm duyệt');
      if (stale && mounted) _load();
    } finally {
      if (mounted) setState(() => _busy.remove(c.caseId));
    }
  }

  /// Hộp thoại xác nhận kèm ô lý do (không bắt buộc). Trả về lý do ("" nếu bỏ trống) hoặc null nếu hủy.
  Future<String?> _askReason(ModerationCase c, _Decision d) {
    final ref = '${c.typeLabel.toLowerCase()} #${c.externalContentId ?? c.caseId}';
    final (title, hint, action) = switch (d) {
      _Decision.approve => ('Duyệt $ref', 'Nội dung sẽ được công khai trên hệ thống.', 'Duyệt'),
      _Decision.reject => ('Từ chối $ref', 'Nội dung sẽ bị chặn; tác giả thấy lý do bên dưới.', 'Từ chối'),
      _Decision.dismiss => (
          'Bỏ qua ca kiểm duyệt #${c.caseId}',
          'Ca chỉ rời khỏi hàng đợi, nội dung gốc KHÔNG đổi trạng thái (khác với Từ chối).',
          'Bỏ qua'
        ),
    };
    return showDialog<String>(
      context: context,
      builder: (_) => _ReasonDialog(title: title, hint: hint, action: action, destructive: d == _Decision.reject),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_failed) return RetryView(onRetry: _load);
    return RefreshIndicator(
      onRefresh: _load,
      child: _cases.isEmpty
          ? ListView(children: [
              Padding(
                padding: const EdgeInsets.all(48),
                child: Column(children: [
                  Icon(LucideIcons.shieldCheck, size: 56, color: context.cs.primary),
                  const SizedBox(height: 12),
                  Text('Hàng đợi kiểm duyệt đang trống.', style: TextStyle(color: context.textMuted)),
                ]),
              ),
            ])
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _cases.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                if (i == 0) {
                  return Text('${_cases.length} ca đang chờ, cũ nhất trước',
                      style: TextStyle(fontSize: 12.5, color: context.textMuted));
                }
                final c = _cases[i - 1];
                return _CaseCard(c, busy: _busy.contains(c.caseId), onDecide: (d) => _decide(c, d));
              },
            ),
    );
  }
}

class _CaseCard extends StatelessWidget {
  final ModerationCase item;
  final bool busy;
  final void Function(_Decision) onDecide;
  const _CaseCard(this.item, {required this.busy, required this.onDecide});

  @override
  Widget build(BuildContext context) {
    final c = item;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Chip(
              visualDensity: VisualDensity.compact,
              label: Text('${c.typeLabel}${c.externalContentId == null ? '' : ' #${c.externalContentId}'}'),
            ),
            const Spacer(),
            if (c.createdAt != null)
              Text(timeAgo(c.createdAt!), style: TextStyle(fontSize: 12, color: context.textMuted)),
          ]),
          if (c.categories.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 4, children: [
              for (final k in c.categories)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: context.cs.error.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: Text(moderationCategoryVi(k), style: TextStyle(fontSize: 12, color: context.cs.error)),
                ),
            ]),
          ],
          const SizedBox(height: 8),
          Text(c.content.isEmpty ? '(Không có nội dung)' : c.content,
              maxLines: 6, overflow: TextOverflow.ellipsis, style: const TextStyle(height: 1.35)),
          if ((c.reason ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('AI: ${moderationReasonVi(c.reason!)}', style: TextStyle(fontSize: 13, color: context.textMuted)),
          ],
          const SizedBox(height: 4),
          Text('Độ tin cậy của AI: ${(c.confidence * 100).round()}%'
              '${c.authorId == null ? '' : '  •  Tác giả #${c.authorId}'}',
              style: TextStyle(fontSize: 12, color: context.textMuted)),
          const SizedBox(height: 8),
          if (busy)
            const Align(
                alignment: Alignment.centerRight,
                child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)))
          else
            Wrap(alignment: WrapAlignment.end, spacing: 8, runSpacing: 4, children: [
              TextButton(onPressed: () => onDecide(_Decision.dismiss), child: const Text('Bỏ qua')),
              OutlinedButton(onPressed: () => onDecide(_Decision.reject), child: const Text('Từ chối')),
              FilledButton(onPressed: () => onDecide(_Decision.approve), child: const Text('Duyệt')),
            ]),
        ]),
      ),
    );
  }
}

/// Hộp thoại nhập lý do cho một quyết định kiểm duyệt. Tự giữ và giải phóng ô nhập để không dùng controller
/// đã dispose trong lúc hiệu ứng đóng hộp thoại còn chạy.
class _ReasonDialog extends StatefulWidget {
  final String title;
  final String hint;
  final String action;
  final bool destructive;
  const _ReasonDialog(
      {required this.title, required this.hint, required this.action, required this.destructive});

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.hint),
        const SizedBox(height: 12),
        TextField(
          controller: _reason,
          maxLines: 3,
          maxLength: 1000, // ReviewRequest.reason tối đa 1000 ký tự
          decoration: const InputDecoration(labelText: 'Lý do (không bắt buộc)', alignLabelWithHint: true),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        FilledButton(
          style: widget.destructive ? FilledButton.styleFrom(backgroundColor: context.cs.error) : null,
          onPressed: () => Navigator.pop(context, _reason.text.trim()),
          child: Text(widget.action),
        ),
      ],
    );
  }
}
