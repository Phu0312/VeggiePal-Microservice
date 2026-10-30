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

/// Nhãn nhóm vi phạm ở hàng đợi kiểm duyệt: `ai_fallback` là nhóm máy chủ gán khi AI không phân loại được.
String moderationCategoryVi(String category) =>
    category == 'ai_fallback' ? 'AI chưa phân loại được' : category;
