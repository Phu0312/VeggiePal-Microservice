/// Lý do kiểm duyệt do máy chủ tự điền (tiếng Anh) khi AI kiểm duyệt không dùng được: bài/video được chuyển sang
/// trạng thái chờ duyệt thay vì báo lỗi. Hai câu đến từ hai service:
/// - blog-service: không gọi được ai-service;
/// - ai-service: gọi được nhưng mô hình lỗi hoặc trả về kết quả không đọc được.
const _aiUnavailableReasons = {
  'ai moderation temporarily unavailable; pending manual review',
  'ai moderation temporarily unavailable; queued for manual review',
};

const aiUnavailableReasonVi =
    'Hệ thống kiểm duyệt AI tạm thời gián đoạn nên nội dung được chuyển cho quản trị viên duyệt thủ công.';

/// Lý do kiểm duyệt hiển thị cho người dùng: câu tiếng Anh có sẵn của máy chủ được dịch, lý do khác (do AI viết)
/// giữ nguyên.
String moderationReasonVi(String reason) {
  final r = reason.trim();
  return _aiUnavailableReasons.contains(r.toLowerCase()) ? aiUnavailableReasonVi : r;
}

/// Nhãn tiếng Việt của các nhóm vi phạm do ai-service gắn cho case kiểm duyệt. `unverified_content` và `ai_fallback`
/// là hai nhóm máy chủ tự gán (AI từ chối nhưng thiếu căn cứ; AI không phân loại được).
const _categoryLabelsVi = {
  'hate': 'Thù ghét',
  'harassment': 'Quấy rối, xúc phạm',
  'sexual': 'Nội dung tình dục',
  'violence': 'Bạo lực',
  'self_harm': 'Tự gây hại',
  'illegal': 'Vi phạm pháp luật',
  'spam': 'Spam, quảng cáo rác',
  'misinformation_dangerous': 'Thông tin y tế sai lệch nguy hiểm',
  'prompt_injection': 'Thao túng bộ kiểm duyệt',
  'unverified_health_claim': 'Tuyên bố sức khỏe chưa kiểm chứng',
  'sensitive_health_question': 'Câu hỏi sức khỏe nhạy cảm',
  'community_dispute': 'Tranh cãi cộng đồng',
  'unverified_content': 'Nội dung chưa xác minh',
  'ai_fallback': 'AI chưa phân loại được',
};

/// Nhãn nhóm vi phạm ở hàng đợi kiểm duyệt; nhóm lạ giữ nguyên mã gốc.
String moderationCategoryVi(String category) => _categoryLabelsVi[category.trim().toLowerCase()] ?? category;
