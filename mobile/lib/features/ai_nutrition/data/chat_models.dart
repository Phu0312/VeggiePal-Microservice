// Model chatbot của ai-service (`/ai/chat`).

/// Một tin nhắn. [id] null với tin nhắn tạm phía máy (khách, hoặc câu hỏi đang chờ AI trả lời).
class ChatMessage {
  final int? id;
  final String text;
  final bool fromUser;
  const ChatMessage(this.text, {required this.fromUser, this.id});

  /// MessageView của backend: role là "user" hoặc "assistant".
  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        '${j['content'] ?? ''}',
        fromUser: '${j['role']}'.toLowerCase() == 'user',
        id: (j['id'] as num?)?.toInt(),
      );
}

/// Một cuộc trò chuyện đã lưu của thành viên (ConversationSummary).
class Conversation {
  final int id;
  final String title;
  final DateTime? updatedAt;
  const Conversation(this.id, this.title, this.updatedAt);

  factory Conversation.fromJson(Map<String, dynamic> j) {
    final title = '${j['title'] ?? ''}'.trim();
    return Conversation(
      (j['id'] as num).toInt(),
      title.isEmpty ? 'Cuộc trò chuyện mới' : title,
      DateTime.tryParse('${j['updatedAt'] ?? j['createdAt']}'),
    );
  }
}

/// Câu trả lời của AI (ChatReply). [conversationId] chỉ có với thành viên;
/// [remainingRequests] là số lượt hỏi còn lại hôm nay (khách: theo IP; thành viên: theo gói).
class ChatReply {
  final String answer;
  final int? conversationId;
  final int? remainingRequests;
  const ChatReply(this.answer, {this.conversationId, this.remainingRequests});

  factory ChatReply.fromJson(Map<String, dynamic> j) => ChatReply(
        '${j['answer'] ?? ''}',
        conversationId: (j['conversationId'] as num?)?.toInt(),
        remainingRequests: (j['remainingRequests'] as num?)?.toInt(),
      );
}

/// Phiên dùng thử của khách (POST /ai/chat/guest-sessions): hiệu lực 24 giờ.
class GuestSession {
  final String id;
  final DateTime expiresAt;
  const GuestSession(this.id, this.expiresAt);

  factory GuestSession.fromJson(Map<String, dynamic> j) => GuestSession(
        '${j['guestSession']}',
        DateTime.parse('${j['expiresAt']}'),
      );

  Map<String, dynamic> toJson() => {'guestSession': id, 'expiresAt': expiresAt.toIso8601String()};

  /// Còn dùng được không. `expiresAt` của backend là LocalDateTime (không có múi giờ) nên chừa 60 giây đệm.
  bool isUsable([DateTime? now]) =>
      expiresAt.subtract(const Duration(seconds: 60)).isAfter(now ?? DateTime.now());
}
