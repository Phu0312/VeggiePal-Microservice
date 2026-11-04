// Lý do kiểm duyệt do máy chủ tự điền (tiếng Anh) khi AI kiểm duyệt không dùng được: bài viết / video được chuyển sang
// PENDING chờ quản trị viên duyệt tay thay vì báo lỗi. blog-service ghi câu "pending", ai-service ghi câu "queued".
const AI_UNAVAILABLE_REASONS = new Set([
  "ai moderation temporarily unavailable; pending manual review",
  "ai moderation temporarily unavailable; queued for manual review",
]);

export const AI_UNAVAILABLE_REASON_VI =
  "Hệ thống kiểm duyệt AI tạm thời gián đoạn nên nội dung được chuyển cho quản trị viên duyệt thủ công.";

/** true nếu lý do là câu "AI kiểm duyệt tạm gián đoạn" của máy chủ. */
export function isAiUnavailableReason(reason) {
  return AI_UNAVAILABLE_REASONS.has(String(reason ?? "").trim().toLowerCase());
}

// Nhóm vi phạm ai-service gắn cho một case kiểm duyệt (ModerationService: VALID_VIOLATION_CATEGORIES cùng hai nhóm
// máy chủ tự gán: `unverified_content` khi AI từ chối nhưng thiếu căn cứ, `ai_fallback` khi AI không phân loại được).
const CATEGORY_LABELS_VI = {
  hate: "Thù ghét",
  harassment: "Quấy rối, xúc phạm",
  sexual: "Nội dung tình dục",
  violence: "Bạo lực",
  self_harm: "Tự gây hại",
  illegal: "Vi phạm pháp luật",
  spam: "Spam, quảng cáo rác",
  misinformation_dangerous: "Thông tin y tế sai lệch nguy hiểm",
  prompt_injection: "Thao túng bộ kiểm duyệt",
  unverified_health_claim: "Tuyên bố sức khỏe chưa kiểm chứng",
  sensitive_health_question: "Câu hỏi sức khỏe nhạy cảm",
  community_dispute: "Tranh cãi cộng đồng",
  unverified_content: "Nội dung chưa xác minh",
  ai_fallback: "AI chưa phân loại được",
};

/** Nhãn tiếng Việt của một nhóm vi phạm; nhóm lạ giữ nguyên mã gốc. */
export function moderationCategoryVi(category) {
  const key = String(category ?? "").trim().toLowerCase();
  return CATEGORY_LABELS_VI[key] ?? category;
}

/** Lý do hiển thị cho người dùng: câu tiếng Anh cố định của máy chủ được dịch, lý do khác (do AI viết) giữ nguyên. */
export function moderationReasonVi(reason) {
  const text = String(reason ?? "").trim();
  return isAiUnavailableReason(text) ? AI_UNAVAILABLE_REASON_VI : text;
}
