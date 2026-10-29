import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/endpoints.dart';
import '../../../core/network/api_client.dart';
import 'chat_models.dart';

/// Mã lỗi của ai-service dùng trong luồng chat.
const aiUnauthenticatedCode = 6001; // phiên dùng thử không hợp lệ / hết hạn
const aiQuotaExceededCode = 6003; // hết lượt (khách: theo IP mỗi ngày; thành viên: theo gói)

/// ai-service chatbot. Mọi lỗi (kể cả không kết nối được máy chủ) được ném lại cho UI.
class ChatRepository {
  final ApiClient _api;
  ChatRepository(this._api);

  static const _kGuestSession = 'chat_guest_session';

  // ---------------- Khách ----------------

  /// Dùng lại phiên còn hạn đã lưu trên máy (backend giới hạn số phiên tạo mới theo IP mỗi ngày).
  Future<GuestSession> _guestSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kGuestSession);
    if (raw != null) {
      try {
        final s = GuestSession.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
        if (s.isUsable()) return s;
      } catch (_) {
        // Dữ liệu hỏng: tạo phiên mới.
      }
    }
    // POST /ai/chat/guest-sessions
    final r = await _api.post(Endpoints.chatGuestSessions);
    final created = GuestSession.fromJson(Map<String, dynamic>.from(r as Map));
    await prefs.setString(_kGuestSession, jsonEncode(created.toJson()));
    return created;
  }

  Future<void> _clearGuestSession() async =>
      (await SharedPreferences.getInstance()).remove(_kGuestSession);

  Future<ChatReply> _guestSend(GuestSession session, String message) async {
    // POST /ai/chat/guest {guestSession, message}
    final r = await _api.post(Endpoints.chatGuest, body: {'guestSession': session.id, 'message': message});
    return ChatReply.fromJson(Map<String, dynamic>.from(r as Map));
  }

  /// Khách hỏi AI. Phiên bị từ chối (hết hạn, đổi mạng/IP) thì tạo phiên mới và gửi lại đúng một lần.
  Future<ChatReply> sendGuest(String message) async {
    final session = await _guestSession();
    try {
      return await _guestSend(session, message);
    } on ApiException catch (e) {
      if (e.statusCode != 401 && e.code != aiUnauthenticatedCode) rethrow;
      await _clearGuestSession();
      return _guestSend(await _guestSession(), message);
    }
  }

  // ---------------- Thành viên (cần JWT) ----------------

  /// POST /ai/chat {conversationId?, message}: không có conversationId thì backend tạo cuộc trò chuyện mới.
  Future<ChatReply> sendMember(String message, {int? conversationId}) async {
    final r = await _api.post(Endpoints.chat, body: {
      'conversationId': ?conversationId,
      'message': message,
    });
    return ChatReply.fromJson(Map<String, dynamic>.from(r as Map));
  }

  // GET /ai/chat/conversations -> mới cập nhật trước
  Future<List<Conversation>> conversations() async {
    final r = await _api.get(Endpoints.chatConversations);
    return asList(r).map((e) => Conversation.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  // GET /ai/chat/conversations/{id} -> {conversation, messages[]}
  Future<List<ChatMessage>> messages(int conversationId) async {
    final r = await _api.get(Endpoints.chatConversation(conversationId));
    final list = r is Map ? r['messages'] : null;
    return [
      if (list is List)
        for (final m in list) ChatMessage.fromJson(Map<String, dynamic>.from(m as Map)),
    ];
  }

  // DELETE /ai/chat/conversations/{id}
  Future<void> deleteConversation(int conversationId) async {
    await _api.delete(Endpoints.chatConversation(conversationId));
  }
}
