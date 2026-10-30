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

/** Lý do hiển thị cho người dùng: câu tiếng Anh cố định của máy chủ được dịch, lý do khác (do AI viết) giữ nguyên. */
export function moderationReasonVi(reason) {
  const text = String(reason ?? "").trim();
  return isAiUnavailableReason(text) ? AI_UNAVAILABLE_REASON_VI : text;
}
