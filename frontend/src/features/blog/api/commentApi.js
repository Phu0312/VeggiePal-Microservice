import { unwrapBlogResponse as unwrap } from "@/features/blog/api/blogErrors";
import apiClient from "@/shared/api/apiClient";

/**
 * Comment APIs (blog-service qua api-gateway).
 * Công khai (không cần token):
 *   GET /comments?targetType=BLOG&targetId=&page=&size=   (comment cấp 1, cũ nhất trước)
 *   GET /comments/:id/replies?page=&size=                  (reply của một comment, cũ nhất trước)
 * Cần đăng nhập:
 *   POST   /comments        body { targetType, targetId, parentCommentId?, content }
 *   PUT    /comments/:id    body { targetType, targetId, content } (chỉ chủ comment)
 *   DELETE /comments/:id    (chủ comment hoặc ADMIN)
 *
 * Comment: { id, authorId, targetType, targetId, parentCommentId,
 *   content, deleted, replyCount, createdAt, updatedAt }
 * - Comment đã xóa: `deleted = true`, `content = null` (vẫn giữ dòng để reply không mất ngữ cảnh)
 *   -> UI hiện "Bình luận đã bị xóa".
 * - Reply chỉ sâu 1 cấp: replyCount của reply luôn = 0.
 * - Comment mới/sửa đi qua kiểm duyệt: có thể bị ẩn hoặc chờ duyệt mà response vẫn trả bình thường
 *   (không có field status) -> UI không được giả định comment vừa gửi sẽ hiện ngay trong danh sách.
 * - Nội dung tối đa 500 từ và 5000 ký tự.
 * Page: { items, page, size, totalElements, totalPages }
 */

const EMPTY_PAGE = { items: [], page: 0, size: 20, totalElements: 0, totalPages: 0 };

/** GET /comments — comment cấp 1 của một nội dung (hiện chỉ hỗ trợ BLOG). */
export async function getComments({ targetType = "BLOG", targetId, page = 0, size = 20 }) {
  const res = await apiClient.get("/comments", {
    params: { targetType, targetId, page, size },
  });
  return unwrap(res, "Không lấy được bình luận") ?? EMPTY_PAGE;
}

/** GET /comments/:id/replies */
export async function getReplies(commentId, { page = 0, size = 20 } = {}) {
  const res = await apiClient.get(`/comments/${commentId}/replies`, {
    params: { page, size },
  });
  return unwrap(res, "Không lấy được phản hồi") ?? EMPTY_PAGE;
}

/** POST /comments — bình luận mới; truyền parentCommentId để phản hồi một comment gốc. */
export async function createComment({ blogId, parentCommentId, content }) {
  const res = await apiClient.post("/comments", {
    targetType: "BLOG",
    targetId: blogId,
    parentCommentId: parentCommentId ?? null,
    content,
  });
  return unwrap(res, "Gửi bình luận thất bại");
}

/** PUT /comments/:id — BE bắt buộc gửi lại targetType + targetId dù không cho đổi. */
export async function updateComment(commentId, { blogId, content }) {
  const res = await apiClient.put(`/comments/${commentId}`, {
    targetType: "BLOG",
    targetId: blogId,
    content,
  });
  return unwrap(res, "Sửa bình luận thất bại");
}

/** DELETE /comments/:id — xóa mềm, comment vẫn còn dạng "đã bị xóa" nếu có phản hồi. */
export async function deleteComment(commentId) {
  const res = await apiClient.delete(`/comments/${commentId}`);
  unwrap(res, "Xóa bình luận thất bại");
}
