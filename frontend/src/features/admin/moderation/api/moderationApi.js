import apiClient from "@/shared/api/apiClient";

/**
 * AI Content Moderation APIs (ai-service qua api-gateway). Chỉ dành cho ADMIN.
 *
 * @typedef {"BLOG" | "VIDEO" | "COMMENT"} ContentType
 * @typedef {"APPROVED" | "REJECTED" | "REVIEW_REQUIRED" | "DISMISSED"} Decision
 *
 * @typedef {Object} ModerationResponse
 * @property {number} caseId - ID case kiểm duyệt (ai_moderation_cases.id)
 * @property {ContentType} contentType - Loại nội dung được kiểm duyệt
 * @property {number|null} externalContentId - ID bài viết/video/bình luận gốc
 * @property {number|null} authorId - ID tài khoản tạo nội dung
 * @property {string|null} content - Nội dung văn bản thực tế bị AI gắn cờ
 * @property {Decision} decision - Trạng thái/quyết định kiểm duyệt
 * @property {string[]} categories - Danh mục vi phạm (hate, spam, violence, harassment, ...)
 * @property {string|null} reason - Lý do giải thích từ AI hoặc ghi chú của Admin
 * @property {number} confidence - Độ tin cậy nhận diện của AI (0.0000 -> 1.0000)
 * @property {number|null} reviewedBy - ID của Admin xử lý case (null nếu chưa duyệt)
 * @property {string|null} reviewedAt - Thời điểm Admin xử lý (ISO-8601, null nếu chưa duyệt)
 * @property {string} createdAt - Thời điểm tạo case kiểm duyệt (ISO-8601)
 *
 * Error codes từ AI-Service:
 * - 6012 (MODERATION_TARGET_NOT_FOUND): "Nội dung đã bị xóa, không thể áp dụng quyết định"
 * - 6013 (MODERATION_CASE_STALE): "Case đã được xử lý" (không còn ở trạng thái REVIEW_REQUIRED)
 */

function toMessage(res, fallbackMessage) {
  const code = res.data?.code;
  if (code === 6012) return "Nội dung đã bị xóa, không thể áp dụng quyết định";
  if (code === 6013) return "Case đã được xử lý";
  if (res.status === 401) return "Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại";
  if (res.status === 403) return "Bạn không có quyền thực hiện kiểm duyệt nội dung";
  if (res.status === 404) return "Không tìm thấy yêu cầu kiểm duyệt này";
  if (res.status === 400) return "Dữ liệu quyết định kiểm duyệt không hợp lệ";
  return res.data?.message || fallbackMessage;
}

function unwrap(res, fallbackMessage) {
  if (res.status >= 400) {
    const error = new Error(toMessage(res, fallbackMessage));
    error.code = res.data?.code;
    error.status = res.status;
    error.response = res;
    throw error;
  }
  return res.data?.result;
}

/**
 * GET /ai/admin/moderation
 * Lấy danh sách case kiểm duyệt đang chờ (REVIEW_REQUIRED, sắp xếp cũ nhất trước).
 *
 * @returns {Promise<ModerationResponse[]>}
 */
export async function getPendingModerationCases() {
  const res = await apiClient.get("/ai/admin/moderation");
  return unwrap(res, "Không lấy được danh sách hàng đợi kiểm duyệt") ?? [];
}

/**
 * PUT /ai/admin/moderation/{id}
 * Quản trị viên duyệt hoặc từ chối case kiểm duyệt kèm lý do.
 * Khi quyết định được lưu, BE tự động gọi sang blog-service để cập nhật trạng thái nội dung gốc.
 *
 * @param {number} id - Mã case kiểm duyệt (caseId)
 * @param {{ decision: "APPROVED" | "REJECTED", reason?: string }} payload
 * @returns {Promise<ModerationResponse>}
 */
export async function reviewModerationCase(id, { decision, reason }) {
  const res = await apiClient.put(`/ai/admin/moderation/${id}`, {
    decision,
    reason: reason?.trim() || undefined,
  });
  return unwrap(res, "Không thể cập nhật quyết định kiểm duyệt");
}

/**
 * DELETE /ai/admin/moderation/{id}?reason=
 * Bỏ qua case: chỉ đưa case ra khỏi hàng đợi (decision = DISMISSED). Khác với từ chối (REJECTED),
 * nội dung gốc KHÔNG bị đổi trạng thái. Case đã được xử lý trước đó sẽ trả lỗi 6013.
 *
 * @param {number} id - Mã case kiểm duyệt (caseId)
 * @param {{ reason?: string }} [payload] - Lý do tùy chọn (gửi dạng query param `reason`)
 * @returns {Promise<ModerationResponse>}
 */
export async function dismissModerationCase(id, { reason } = {}) {
  const res = await apiClient.delete(`/ai/admin/moderation/${id}`, {
    params: { reason: reason?.trim() || undefined },
  });
  return unwrap(res, "Không thể bỏ qua case kiểm duyệt");
}
