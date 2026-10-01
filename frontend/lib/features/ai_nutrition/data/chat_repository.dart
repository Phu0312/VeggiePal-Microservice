import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/endpoints.dart';
import '../../../core/network/api_client.dart';

class ChatReply {
  final String answer;
  final int? conversationId; // chỉ có với thành viên
  final int? remaining; // chỉ có với khách: số câu hỏi miễn phí còn lại
  const ChatReply(this.answer, {this.conversationId, this.remaining});
}

/// Mã lỗi backend cho "khách hết 3 lượt dùng thử" (ErrorCode.GUEST_AI_QUOTA_EXCEEDED).
const guestQuotaExceededCode = 2030;

class ChatRepository {
  final ApiClient _api;
  ChatRepository(this._api);

  static const _kGuestId = 'guest_id';
  static const _kGuestUsed = 'guest_used';

  /// Định danh khách ổn định giữa các lần mở app (gửi qua header X-Guest-Id).
  Future<String> _guestId() async {
    final p = await SharedPreferences.getInstance();
    var id = p.getString(_kGuestId);
    if (id == null) {
      id = 'guest-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(99999)}';
      await p.setString(_kGuestId, id);
    }
    return id;
  }

  /// Số lượt dùng thử còn lại (đọc từ bộ đếm cục bộ, được đồng bộ theo phản hồi server).
  Future<int> guestRemaining() async {
    final p = await SharedPreferences.getInstance();
    return AppStrings.guestQuota - (p.getInt(_kGuestUsed) ?? 0);
  }

  Future<void> _setUsed(int used) async =>
      (await SharedPreferences.getInstance()).setInt(_kGuestUsed, used);

  /// Gửi tin nhắn. Phân quyền:
  ///  - Khách (không token): POST /ai/chat/guest, server đếm tối đa 3 câu; hết lượt -> ApiException(code 2030).
  ///  - Thành viên có JWT: POST /ai/chat, không giới hạn, giữ conversationId.
  /// Mọi lỗi (kể cả không kết nối được máy chủ) được ném lại cho UI.
  Future<ChatReply> send(String message, {required bool isMember, int? conversationId}) async {
    if (isMember) {
      final r = await _api.post(Endpoints.chat,
          body: {'message': message, 'conversationId': conversationId});
      final m = Map<String, dynamic>.from(r as Map);
      return ChatReply('${m['answer']}', conversationId: (m['conversationId'] as num?)?.toInt());
    }

    final r = await _api.post(Endpoints.chatGuest,
        body: {'message': message}, headers: {'X-Guest-Id': await _guestId()});
    final m = Map<String, dynamic>.from(r as Map);
    final remaining = (m['questionsRemaining'] as num?)?.toInt() ?? 0;
    await _setUsed(AppStrings.guestQuota - remaining);
    return ChatReply('${m['answer']}', remaining: remaining);
  }
}
