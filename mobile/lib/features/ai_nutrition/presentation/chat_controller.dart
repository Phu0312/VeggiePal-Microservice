import 'package:flutter/foundation.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../data/chat_models.dart';
import '../data/chat_repository.dart';

/// Backend nhận câu hỏi tối đa 4000 ký tự (ChatDtos.ChatRequest).
const chatMaxInputLength = 4000;

/// Kết quả một lần gửi câu hỏi, để màn hình quyết định hiện gì.
class SendOutcome {
  final bool ok;

  /// Thông báo lỗi tiếng Việt (null nếu thành công hoặc câu hỏi bị bỏ qua).
  final String? error;

  /// Khách hết lượt: màn hình mời đăng ký / đăng nhập.
  final bool guestQuotaExceeded;

  const SendOutcome.sent() : this._(true, null, false);
  const SendOutcome.ignored() : this._(false, null, false);
  const SendOutcome.failed(String error) : this._(false, error, false);
  const SendOutcome.guestQuota(String error) : this._(false, error, true);
  const SendOutcome._(this.ok, this.error, this.guestQuotaExceeded);
}

/// Dịch lỗi của ai-service sang thông báo tiếng Việt cho người dùng (backend trả message tiếng Anh).
String chatErrorMessage(Object e, {required bool guest}) {
  if (e is! ApiException) return errorMessage(e);
  if (e.isNetwork) return e.message;
  final code = e.code, status = e.statusCode;
  if (code == aiQuotaExceededCode || status == 429) {
    return guest
        ? 'Bạn đã dùng hết lượt hỏi thử hôm nay. Hãy đăng ký hoặc đăng nhập để tiếp tục trò chuyện.'
        : 'Bạn đã dùng hết lượt hỏi AI hôm nay. Hãy nâng cấp gói thành viên để có thêm lượt hoặc quay lại vào ngày mai.';
  }
  if (code == aiUnauthenticatedCode) {
    return guest
        ? 'Phiên dùng thử không còn hợp lệ. Hãy gửi lại câu hỏi để tạo phiên mới.'
        : 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
  }
  if (code == 6000 || status == 400) {
    return 'Câu hỏi không hợp lệ hoặc quá dài (tối đa $chatMaxInputLength ký tự).';
  }
  if ({6004, 6005, 6006, 6007}.contains(code) || (status != null && status >= 500)) {
    return 'Trợ lý AI tạm thời không khả dụng. Vui lòng thử lại sau ít phút.';
  }
  return e.message;
}

/// Trạng thái chat. Đặt ở Provider (không phải State của widget) để cuộc trò chuyện không mất khi chuyển tab.
/// - Thành viên: cuộc trò chuyện lưu ở backend (danh sách / mở lại / xoá / nối tiếp). [activeId] null = cuộc mới,
///   backend tự tạo ở tin nhắn đầu tiên.
/// - Khách: tin nhắn chỉ giữ trong bộ nhớ, backend giới hạn lượt hỏi theo IP mỗi ngày.
class ChatController extends ChangeNotifier {
  ChatController(this._repo);

  final ChatRepository _repo;

  int? _userId;
  int _epoch = 0; // tăng khi đổi tài khoản để bỏ kết quả của yêu cầu cũ

  bool get isMember => _userId != null;

  List<ChatMessage> messages = [];
  int? activeId;
  bool sending = false;
  bool loadingMessages = false;

  /// Số lượt hỏi còn lại hôm nay theo lần trả lời gần nhất; null khi chưa biết.
  int? remaining;

  List<Conversation> conversations = [];
  bool loadingConversations = false;
  String? conversationsError;

  /// Gọi khi đăng nhập / đăng xuất (từ ProxyProvider): xoá toàn bộ cuộc trò chuyện của tài khoản trước.
  void bindUser(int? userId) {
    if (userId == _userId) return;
    _userId = userId;
    _epoch++;
    messages = [];
    activeId = null;
    sending = false;
    loadingMessages = false;
    remaining = null;
    conversations = [];
    conversationsError = null;
    loadingConversations = false;
    // Được gọi từ ProxyProvider.update (đang trong build) nên hoãn thông báo sang microtask.
    Future.microtask(notifyListeners);
    if (userId != null) Future.microtask(loadConversations);
  }

  Conversation? get activeConversation {
    for (final c in conversations) {
      if (c.id == activeId) return c;
    }
    return null;
  }

  Future<void> loadConversations() async {
    if (!isMember) return;
    final epoch = _epoch;
    loadingConversations = true;
    conversationsError = null;
    notifyListeners();
    try {
      final list = await _repo.conversations();
      if (epoch != _epoch) return;
      conversations = list;
    } catch (e) {
      if (epoch != _epoch) return;
      conversationsError = errorMessage(e);
    } finally {
      if (epoch == _epoch) {
        loadingConversations = false;
        notifyListeners();
      }
    }
  }

  /// Bắt đầu cuộc trò chuyện mới (xoá khung chat). Không đổi được khi đang chờ AI trả lời.
  void startNew() {
    if (sending) return;
    _epoch++;
    activeId = null;
    messages = [];
    loadingMessages = false;
    notifyListeners();
  }

  /// Mở lại một cuộc trò chuyện đã lưu. Trả về thông báo lỗi nếu không tải được (null = thành công).
  Future<String?> open(int conversationId) async {
    if (!isMember || sending) return null;
    final epoch = ++_epoch;
    activeId = conversationId;
    messages = [];
    loadingMessages = true;
    notifyListeners();
    try {
      final list = await _repo.messages(conversationId);
      if (epoch != _epoch) return null;
      messages = list;
      return null;
    } catch (e) {
      if (epoch != _epoch) return null;
      // Mở không được thì quay về cuộc trò chuyện mới, tránh nối tiếp vào khung chat trống.
      activeId = null;
      return chatErrorMessage(e, guest: false);
    } finally {
      if (epoch == _epoch) {
        loadingMessages = false;
        notifyListeners();
      }
    }
  }

  /// Xoá một cuộc trò chuyện. Trả về thông báo lỗi nếu thất bại (null = thành công).
  Future<String?> delete(int conversationId) async {
    if (!isMember || sending) return null;
    final epoch = _epoch;
    String? error;
    try {
      await _repo.deleteConversation(conversationId);
    } catch (e) {
      error = chatErrorMessage(e, guest: false);
    }
    if (epoch != _epoch) return error;
    // 6002: đã bị xoá ở nơi khác -> danh sách vẫn phải khớp backend.
    conversations = conversations.where((c) => c.id != conversationId).toList();
    if (activeId == conversationId) startNew();
    notifyListeners();
    if (error != null) loadConversations();
    return error;
  }

  /// Gửi một câu hỏi. Tin nhắn của người dùng hiện ngay; nếu lỗi thì bị gỡ lại để UI trả nội dung về ô nhập.
  Future<SendOutcome> send(String text) async {
    final msg = text.trim();
    if (msg.isEmpty || sending) return const SendOutcome.ignored();
    final guest = !isMember;

    // Khách đã biết là hết lượt thì không cần gọi máy chủ.
    if (guest && remaining != null && remaining! <= 0) {
      return SendOutcome.guestQuota(chatErrorMessage(ApiException('', code: aiQuotaExceededCode), guest: true));
    }

    final epoch = _epoch;
    final mine = ChatMessage(msg, fromUser: true);
    messages = [...messages, mine];
    sending = true;
    notifyListeners();

    try {
      final reply = guest
          ? await _repo.sendGuest(msg)
          : await _repo.sendMember(msg, conversationId: activeId);
      if (epoch != _epoch) return const SendOutcome.ignored();
      messages = [...messages, ChatMessage(reply.answer, fromUser: false)];
      if (reply.remainingRequests != null) remaining = reply.remainingRequests;
      if (!guest) {
        activeId = reply.conversationId ?? activeId;
        loadConversations(); // cuộc trò chuyện mới / tiêu đề / thứ tự cập nhật
      }
      return const SendOutcome.sent();
    } catch (e) {
      if (epoch != _epoch) return const SendOutcome.ignored();
      messages = messages.where((m) => !identical(m, mine)).toList();
      final message = chatErrorMessage(e, guest: guest);
      final quota = e is ApiException && (e.code == aiQuotaExceededCode || e.statusCode == 429);
      if (quota) remaining = 0;
      return guest && quota ? SendOutcome.guestQuota(message) : SendOutcome.failed(message);
    } finally {
      if (epoch == _epoch) {
        sending = false;
        notifyListeners();
      }
    }
  }

  /// Dòng hiển thị lượt hỏi còn lại (khách và thành viên).
  String get quotaLabel {
    final r = remaining;
    if (isMember) return r == null ? 'Thành viên' : 'Còn $r lượt hỏi hôm nay';
    return r == null
        ? 'Dùng thử: tối đa ${AppStrings.guestQuota} câu hỏi mỗi ngày'
        : 'Dùng thử: còn $r lượt hỏi hôm nay';
  }
}
