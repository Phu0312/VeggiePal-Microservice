import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/common_widgets.dart';
import '../data/chat_models.dart';
import 'chat_controller.dart';

/// Lịch sử trò chuyện của thành viên (GET /ai/chat/conversations): mở lại để nối tiếp hoặc xoá.
Future<void> showConversationHistory(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _HistorySheet(),
  );
}

class _HistorySheet extends StatelessWidget {
  const _HistorySheet();

  Future<void> _open(BuildContext context, Conversation c) async {
    final chat = context.read<ChatController>();
    Navigator.pop(context);
    final error = await chat.open(c.id);
    if (error != null && context.mounted) {
      showErrorDialog(context, error, title: 'Không mở được cuộc trò chuyện');
    }
  }

  Future<void> _delete(BuildContext context, Conversation c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá cuộc trò chuyện'),
        content: Text('Bạn có chắc muốn xoá "${c.title}"? Thao tác này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xoá')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final error = await context.read<ChatController>().delete(c.id);
    if (error != null && context.mounted) {
      showErrorDialog(context, error, title: 'Không xoá được cuộc trò chuyện');
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatController>();
    final Widget body;
    if (chat.loadingConversations && chat.conversations.isEmpty) {
      body = const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()));
    } else if (chat.conversationsError != null && chat.conversations.isEmpty) {
      body = RetryView(message: chat.conversationsError!, onRetry: chat.loadConversations);
    } else if (chat.conversations.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
            child: Text('Chưa có cuộc trò chuyện nào được lưu.',
                style: TextStyle(color: context.textMuted))),
      );
    } else {
      body = ListView(
        shrinkWrap: true,
        children: [
          for (final c in chat.conversations)
            ListTile(
              selected: c.id == chat.activeId,
              leading: const Icon(LucideIcons.messageSquare),
              title: Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: c.updatedAt == null ? null : Text(timeAgo(c.updatedAt!.toLocal())),
              trailing: IconButton(
                tooltip: 'Xoá',
                icon: Icon(LucideIcons.trash2, size: 20, color: context.cs.error),
                onPressed: chat.sending ? null : () => _delete(context, c),
              ),
              onTap: chat.sending ? null : () => _open(context, c),
            ),
        ],
      );
    }

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const ListTile(
              title: Text('Lịch sử trò chuyện', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
          Flexible(child: body),
        ]),
      ),
    );
  }
}
