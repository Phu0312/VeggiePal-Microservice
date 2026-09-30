import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/mock_fallback.dart';

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
  ///  - Thành viên có JWT thật: POST /ai/chat, không giới hạn, giữ conversationId.
  ///  - Thành viên ở phiên demo (không JWT) hoặc server tắt: trả lời mock, không giới hạn.
  Future<ChatReply> send(String message, {required bool isMember, int? conversationId}) async {
    if (isMember) {
      if (_api.token == null) return _mockReply(message);
      return withFallback(() async {
        final r = await _api.post(Endpoints.chat,
            body: {'message': message, 'conversationId': conversationId});
        final m = Map<String, dynamic>.from(r as Map);
        return ChatReply('${m['answer']}', conversationId: (m['conversationId'] as num?)?.toInt());
      }, () => _mockReply(message));
    }

    final remainingBefore = await guestRemaining();
    return withFallback(() async {
      final r = await _api.post(Endpoints.chatGuest,
          body: {'message': message}, headers: {'X-Guest-Id': await _guestId()});
      final m = Map<String, dynamic>.from(r as Map);
      final remaining = (m['questionsRemaining'] as num?)?.toInt() ?? 0;
      await _setUsed(AppStrings.guestQuota - remaining);
      return ChatReply('${m['answer']}', remaining: remaining);
    }, () {
      // Mock: tự đếm lượt để minh hoạ luồng hết lượt khi chưa bật server.
      if (remainingBefore <= 0) {
        throw ApiException('Bạn đã dùng hết lượt thử', code: guestQuotaExceededCode);
      }
      _setUsed(AppStrings.guestQuota - remainingBefore + 1);
      return ChatReply(_mockReply(message).answer, remaining: remainingBefore - 1);
    });
  }

  ChatReply _mockReply(String q) {
    final s = q.toLowerCase();
    String a;
    if (s.contains('trứng')) {
      a = 'Thay 1 quả trứng bằng: 1 muỗng canh bột hạt lanh + 3 muỗng nước (làm bánh), '
          '¼ chén đậu hũ non xay (món mặn), hoặc ¼ chén sốt táo (bánh ngọt).';
    } else if (s.contains('bmi')) {
      a = 'BMI = cân nặng (kg) / chiều cao (m)². Dưới 18.5 là thiếu cân, 18.5–22.9 bình thường, '
          '23–24.9 thừa cân nhẹ, từ 25 là béo phì (chuẩn châu Á). Hãy nhập chỉ số ở tab Thực đơn để mình gợi ý cụ thể.';
    } else if (s.contains('protein') || s.contains('đạm')) {
      a = 'Thực đơn chay giàu protein: đậu hũ, tempeh, đậu lăng, đậu gà, quinoa, hạt chia và sữa đậu nành. '
          'Ví dụ: sáng cháo yến mạch hạt chia, trưa cơm gạo lứt đậu hũ sốt nấm, tối salad đậu gà.';
    } else {
      a = 'Mình là trợ lý dinh dưỡng VeggiePal. Bạn có thể hỏi về thay thế nguyên liệu, BMI, '
          'hoặc thực đơn chay theo mục tiêu sức khỏe nhé!';
    }
    return ChatReply(a);
  }
}
