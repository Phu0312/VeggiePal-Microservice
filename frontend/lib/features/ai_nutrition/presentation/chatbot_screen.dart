import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/login_screen.dart';
import 'chat_controller.dart';

/// TAB 4 - Trợ lý AI dinh dưỡng (giao diện kiểu Messenger).
/// Widget tree: Column
///   ├─ Banner lượt dùng thử (chỉ hiện với khách)
///   ├─ Expanded ListView.builder các bong bóng chat
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
  bool _dialogOpen = false;

  Future<void> _send(String text) async {
    final isMember = context.read<AuthController>().isLoggedIn;
    _input.clear();
    await context.read<ChatController>().send(text, isMember: isMember);
    _scrollToEnd();
  }

  void _scrollToEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
        }
      });

  /// Dialog yêu cầu đăng ký khi khách hết lượt.
  Future<void> _showQuotaDialog() async {
    _dialogOpen = true;
    context.read<ChatController>().ackQuotaDialog();
    final go = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        icon: Icon(Icons.lock_outline, color: context.cs.primary, size: 36),
        title: const Text('Hết lượt dùng thử'),
        content: const Text(
            'Bạn đã dùng hết 3 câu hỏi miễn phí. Đăng ký hoặc đăng nhập để chat không giới hạn với trợ lý AI.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Để sau')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Đăng ký / Đăng nhập')),
        ],
      ),
    );
    _dialogOpen = false;
    if (go == true && mounted) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatController>();
    final isMember = context.watch<AuthController>().isLoggedIn;

    // Mở dialog sau khi build xong khi controller báo hết lượt.
    if (chat.quotaExceeded && !_dialogOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_dialogOpen) _showQuotaDialog();
      });
    }

    // Lỗi từ backend -> popup (tin nhắn của người dùng vẫn nằm trong khung chat).
    final err = chat.error;
    if (err != null) {
      chat.ackError();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showErrorDialog(context, err, title: 'Trợ lý AI không phản hồi');
      });
    }

    return Column(children: [
      // Khách thấy số lượt còn lại; thành viên thấy nhãn "không giới hạn".
      Container(
        width: double.infinity,
        color: AppColors.accent.withValues(alpha: 0.25),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          isMember
              ? 'Thành viên: chat không giới hạn'
              : 'Dùng thử: còn ${chat.guestRemaining}/${AppStrings.guestQuota} câu hỏi miễn phí',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      Expanded(
        child: ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.all(16),
          itemCount: chat.messages.length + (chat.sending ? 1 : 0),
          itemBuilder: (_, i) {
            if (i == chat.messages.length) return const _Typing();
            return _Bubble(chat.messages[i]);
          },
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
            onPressed: () => _send(AppStrings.quickQuestions[i]),
          ),
        ),
      ),
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _input,
                textInputAction: TextInputAction.send,
                onSubmitted: _send,
                decoration: const InputDecoration(hintText: 'Hỏi về dinh dưỡng chay...'),
              ),
            ),
            IconButton.filled(
              onPressed: chat.sending ? null : () => _send(_input.text),
              icon: const Icon(Icons.send),
            ),
          ]),
        ),
      ),
    ]);
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage m;
  const _Bubble(this.m);

  @override
  Widget build(BuildContext context) {
    final me = m.fromUser;
    return Align(
      alignment: me ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
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
        child: Text(m.text, style: TextStyle(color: me ? context.cs.onPrimary : context.cs.onSurface, height: 1.35)),
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
          padding: EdgeInsets.only(bottom: 10),
          child: Text('Đang trả lời...', style: TextStyle(color: context.textMuted)),
        ),
      );
}
