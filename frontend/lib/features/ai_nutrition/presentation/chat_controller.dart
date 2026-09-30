import 'package:flutter/foundation.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../data/chat_repository.dart';

class ChatMessage {
  final String text;
  final bool fromUser;
  const ChatMessage(this.text, {required this.fromUser});
}

/// Trạng thái phiên chat. Đặt ở Provider (không phải State của widget) để lịch sử
/// chat không mất khi chuyển tab.
class ChatController extends ChangeNotifier {
  ChatController(this._repo) {
    _repo.guestRemaining().then((v) {
      guestRemaining = v;
      notifyListeners();
    });
  }

  final ChatRepository _repo;

  final messages = <ChatMessage>[
    const ChatMessage(
        'Xin chào! Mình là trợ lý dinh dưỡng chay VeggiePal. Bạn muốn hỏi gì hôm nay?',
        fromUser: false),
  ];
  int? _conversationId;
  bool sending = false;
  int guestRemaining = AppStrings.guestQuota;

  /// Bật lên khi server báo hết lượt -> UI hiện dialog yêu cầu đăng ký.
  bool quotaExceeded = false;

  void ackQuotaDialog() => quotaExceeded = false;

  /// [isMember] = đã đăng nhập (User/Admin). Luồng phân quyền:
  ///  - Khách còn lượt: gọi bình thường, cập nhật bộ đếm còn lại.
  ///  - Khách hết lượt: chặn ngay ở client (không gọi server) và mở dialog đăng ký;
  ///    nếu server vẫn trả code 2030 thì xử lý giống hệt.
  ///  - Thành viên: không giới hạn, giữ conversationId để nối tiếp hội thoại.
  Future<void> send(String text, {required bool isMember}) async {
    final msg = text.trim();
    if (msg.isEmpty || sending) return;

    if (!isMember && guestRemaining <= 0) {
      quotaExceeded = true;
      notifyListeners();
      return;
    }

    messages.add(ChatMessage(msg, fromUser: true));
    sending = true;
    notifyListeners();

    try {
      final reply = await _repo.send(msg, isMember: isMember, conversationId: _conversationId);
      _conversationId = reply.conversationId ?? _conversationId;
      if (reply.remaining != null) guestRemaining = reply.remaining!;
      messages.add(ChatMessage(reply.answer, fromUser: false));
    } on ApiException catch (e) {
      if (e.code == guestQuotaExceededCode) {
        guestRemaining = 0;
        quotaExceeded = true;
        messages.add(const ChatMessage(
            'Bạn đã dùng hết 3 câu hỏi miễn phí. Đăng ký để chat không giới hạn nhé!',
            fromUser: false));
      } else {
        messages.add(ChatMessage('Xin lỗi, có lỗi xảy ra: ${e.message}', fromUser: false));
      }
    } finally {
      sending = false;
      notifyListeners();
    }
  }

  /// Đăng nhập xong thì bắt đầu hội thoại mới thuộc tài khoản.
  void resetConversation() {
    _conversationId = null;
    notifyListeners();
  }
}
