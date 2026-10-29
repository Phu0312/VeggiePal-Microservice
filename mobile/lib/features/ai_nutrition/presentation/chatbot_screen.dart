import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/presentation/login_screen.dart';
import '../data/chat_models.dart';
import 'chat_controller.dart';
import 'chat_markdown.dart';
import 'conversation_history_sheet.dart';

/// TAB 3 - Trợ lý AI dinh dưỡng (giao diện kiểu Messenger).
/// Widget tree: Column
///   ├─ _TopBar       (khách: lượt dùng thử | thành viên: lịch sử, tên cuộc trò chuyện, cuộc mới)
///   ├─ Expanded ListView các bong bóng chat (AI trả lời bằng markdown)
///   ├─ Hàng Quick Chips gợi ý câu hỏi
///   └─ Ô nhập + nút gửi
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    final chat = context.read<ChatController>();
    if (text.trim().isEmpty || chat.sending) return;
    _input.clear();
    final pending = chat.send(text);
    _scrollToEnd(); // tin nhắn của người dùng đã hiện ngay
    final outcome = await pending;
    if (!mounted) return;
    _scrollToEnd();
    if (outcome.ok || outcome.error == null) return;
    // Gửi thất bại: trả câu hỏi về ô nhập để người dùng gửi lại, không phải gõ lại.
    if (_input.text.isEmpty) _input.text = text.trim();
    if (outcome.guestQuotaExceeded) {
      await _showQuotaDialog();
    } else {
      await showErrorDialog(context, outcome.error!, title: 'Trợ lý AI không phản hồi');
    }
  }

  void _scrollToEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
        }
      });

  /// Dialog mời đăng ký khi khách hết lượt hỏi thử.
  Future<void> _showQuotaDialog() async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.lock_outline, color: ctx.cs.primary, size: 36),
        title: const Text('Hết lượt dùng thử'),
        content: const Text(
            'Bạn đã dùng hết lượt hỏi thử hôm nay. Đăng ký hoặc đăng nhập để tiếp tục trò chuyện với trợ lý AI.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Để sau')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true), child: const Text('Đăng ký / Đăng nhập')),
        ],
      ),
    );
    if (go == true && mounted) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatController>();

    return Column(children: [
      _TopBar(chat),
      Expanded(
        child: chat.loadingMessages
            ? const Center(child: CircularProgressIndicator())
            // Cho phép bôi đen / sao chép câu trả lời của AI.
            : SelectionArea(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: chat.messages.length + 1 + (chat.sending ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == 0) return const _Greeting();
                    final k = i - 1;
                    if (k == chat.messages.length) return const _Typing();
                    return _Bubble(chat.messages[k]);
                  },
                ),
              ),
      ),
      SizedBox(
        height: 48,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: AppStrings.quickQuestions.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) => ActionChip(
            label: Text(AppStrings.quickQuestions[i]),
            onPressed: chat.sending ? null : () => _send(AppStrings.quickQuestions[i]),
          ),
        ),
      ),
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: TextField(
                controller: _input,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                inputFormatters: [LengthLimitingTextInputFormatter(chatMaxInputLength)],
                onSubmitted: _send,
                decoration: const InputDecoration(hintText: 'Hỏi về dinh dưỡng chay...'),
              ),
            ),
            IconButton.filled(
              tooltip: 'Gửi',
              onPressed: chat.sending ? null : () => _send(_input.text),
              icon: const Icon(Icons.send),
            ),
          ]),
        ),
      ),
    ]);
  }
}

/// Thanh trên cùng. Khách: lượt dùng thử. Thành viên: nút lịch sử, tên cuộc trò chuyện + lượt còn lại, nút cuộc mới.
class _TopBar extends StatelessWidget {
  final ChatController chat;
  const _TopBar(this.chat);

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.accent.withValues(alpha: 0.25);
    if (!chat.isMember) {
      return Container(
        width: double.infinity,
        color: bg,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(chat.quotaLabel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      );
    }
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(children: [
        IconButton(
          tooltip: 'Lịch sử trò chuyện',
          onPressed: () => showConversationHistory(context),
          icon: const Icon(LucideIcons.history),
        ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(chat.activeConversation?.title ?? 'Cuộc trò chuyện mới',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            Text(chat.quotaLabel, style: TextStyle(fontSize: 12, color: context.textMuted)),
          ]),
        ),
        IconButton(
          tooltip: 'Cuộc trò chuyện mới',
          onPressed: chat.sending ? null : chat.startNew,
          icon: const Icon(LucideIcons.squarePen),
        ),
      ]),
    );
  }
}

/// Lời chào của trợ lý ở đầu mỗi cuộc trò chuyện (chỉ hiển thị, không gửi lên máy chủ).
class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) => const _Bubble(ChatMessage(
      'Xin chào! Mình là trợ lý dinh dưỡng chay VeggiePal. Bạn muốn hỏi gì hôm nay?',
      fromUser: false));
}

class _Bubble extends StatelessWidget {
  final ChatMessage m;
  const _Bubble(this.m);

  @override
  Widget build(BuildContext context) {
    final me = m.fromUser;
    final fg = me ? context.cs.onPrimary : context.cs.onSurface;
    return Align(
      alignment: me ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        decoration: BoxDecoration(
          color: me ? context.cs.primary : context.cs.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(me ? 18 : 4),
            bottomRight: Radius.circular(me ? 4 : 18),
          ),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: me
            ? Text(m.text, style: TextStyle(color: fg, height: 1.35))
            : ChatMarkdown(m.text, color: fg),
      ),
    );
  }
}

class _Typing extends StatelessWidget {
  const _Typing();
  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text('Đang trả lời...', style: TextStyle(color: context.textMuted)),
        ),
      );
}
