import { unwrapBlogResponse as unwrap } from "@/features/blog/api/blogErrors";
import apiClient from "@/shared/api/apiClient";
import { chunk, joinIds, normalizeIds } from "@/shared/utils/ids";

/**
 * Blog APIs (blog-service qua api-gateway).
 * Công khai (không cần token):
 *   GET /blogs?categoryId=&keyword=&sort=&page=&size=
 *   GET /blogs/:id           (bài đã đăng; mỗi lần gọi BE tính thêm 1 lượt xem -> chỉ gọi ở trang chi tiết)
 *     Kèm token hợp lệ thì chủ bài và ADMIN còn đọc được bài DRAFT/PENDING/REJECTED/BANNED (không tính
 *     lượt xem); người khác nhận lỗi như bài không tồn tại. Token hỏng/hết hạn bị bỏ qua, không làm 401.
 *   GET /blogs/:id/related
 * Cần đăng nhập:
 *   POST   /blogs                body { title, content, categoryId, publish }
 *   PUT    /blogs/:id            body { title, content, categoryId }
 *   POST   /blogs/:id/submit     (gửi bản nháp đi kiểm duyệt)
 *   DELETE /blogs/:id
 *   POST   /blogs/:id/thumbnail  multipart field "file" (JPEG/PNG/WEBP, tối đa 5MB)
 *   POST   /blogs/:id/vote      body { value: 1 | -1 } — gửi lại cùng giá trị thì BE thu hồi vote
 *   DELETE /blogs/:id/vote
 *   GET    /blogs/me/votes?blogIds=1,2,3
 *   GET    /blogs/me?status=&page=&size=
 *
 * BlogSummary (item của danh sách / related / "của tôi"): { id, authorId, categoryId, categoryName,
 *   title, thumbnailUrl, status, viewCount, voteScore, publishedAt, createdAt }
 *   -> KHÔNG có nội dung bài và số bình luận.
 * Blog (chi tiết) = BlogSummary + { content, updatedAt, moderationReason }
 * status: "DRAFT" | "PENDING" | "PUBLISHED" | "REJECTED" | "BANNED"
 * Vote: { blogId, myVote: 1 | -1 | null, voteScore }  (voteScore = null ở GET /blogs/me/votes)
 * Page: { items, page, size, totalElements, totalPages }  (chú ý: `items`, không phải `content`)
 * authorId -> lấy tên/avatar qua usePublicUsers (GET /users/batch).
 */

// BE giới hạn 100 id mỗi lần gọi GET /blogs/me/votes.
const MAX_VOTE_IDS_PER_REQUEST = 100;

const EMPTY_PAGE = { items: [], page: 0, size: 10, totalElements: 0, totalPages: 0 };

/**
 * GET /blogs — bài đã duyệt, có phân trang.
 * - keyword: tìm trong tiêu đề + nội dung, khớp tiêu đề xếp trước ("" coi như không lọc)
 * - sort: "popular" (nhiều vote) | "mostViewed" (nhiều lượt xem) | bỏ trống = mới đăng nhất
 */
export async function getBlogs({ categoryId, keyword, sort, page = 0, size = 10 } = {}) {
  const res = await apiClient.get("/blogs", {
    params: {
      categoryId: categoryId || undefined,
      keyword: keyword?.trim() || undefined,
      sort: sort || undefined,
      page,
      size,
    },
  });
  return unwrap(res, "Không lấy được danh sách bài viết") ?? EMPTY_PAGE;
}

/** GET /blogs/:id — chi tiết một bài đã duyệt (+1 lượt xem); chủ bài / ADMIN đọc được cả bài chưa đăng. */
export async function getBlog(id) {
  const res = await apiClient.get(`/blogs/${id}`);
  return unwrap(res, "Không lấy được bài viết");
}

/** GET /blogs/:id/related — tối đa 5 bài cùng danh mục. */
export async function getRelatedBlogs(id) {
  const res = await apiClient.get(`/blogs/${id}/related`);
  return unwrap(res, "Không lấy được bài viết liên quan") ?? [];
}

/**
 * POST /blogs/:id/vote — nút tim luôn gửi 1: chưa vote thì thành vote, đã vote 1 thì BE thu hồi.
 * Không vote được bài của chính mình (BE trả lỗi 3041).
 */
export async function voteBlog(id, value = 1) {
  const res = await apiClient.post(`/blogs/${id}/vote`, { value });
  return unwrap(res, "Không bình chọn được, vui lòng thử lại");
}

/** DELETE /blogs/:id/vote — bỏ vote (gọi 2 lần cũng không lỗi). */
export async function removeBlogVote(id) {
  const res = await apiClient.delete(`/blogs/${id}/vote`);
  return unwrap(res, "Không bỏ bình chọn được, vui lòng thử lại");
}

/**
 * GET /blogs/me/votes — vote của tôi trên một danh sách bài, để phủ lên feed công khai.
 * Trả về mảng { blogId, myVote }, mỗi id được hỏi có đúng 1 phần tử (myVote null = chưa vote).
 */
export async function getMyVotes(blogIds) {
  const ids = normalizeIds(blogIds);
  if (ids.length === 0) return [];

  const responses = await Promise.all(
    chunk(ids, MAX_VOTE_IDS_PER_REQUEST).map((part) =>
      apiClient.get("/blogs/me/votes", { params: { blogIds: joinIds(part) } })
    )
  );
  return responses.flatMap((res) => unwrap(res, "Không lấy được bình chọn của bạn") ?? []);
}

/**
 * GET /blogs/me — bài của tôi ở mọi trạng thái, có phân trang.
 * status: bỏ trống để lấy tất cả.
 */
export async function getMyBlogs({ status, page = 0, size = 10 } = {}) {
  const res = await apiClient.get("/blogs/me", {
    params: { status: status || undefined, page, size },
  });
  return unwrap(res, "Không lấy được bài viết của bạn") ?? EMPTY_PAGE;
}

// ---- Tạo / sửa / xóa bài (chủ bài hoặc ADMIN) ------------------------------------------------
// Các hàm tạo/sửa/gửi duyệt trả BlogResponse có `status` và `moderationReason` để báo kết quả
// kiểm duyệt: PUBLISHED (đã đăng) | PENDING (chờ duyệt) | REJECTED (bị từ chối, kèm lý do) | DRAFT.

/**
 * POST /blogs — tạo bài. publish = false lưu bản nháp; true thì kiểm duyệt ngay (có thể đăng luôn).
 * Giới hạn: tiêu đề tối đa 150 ký tự, nội dung tối thiểu 20 ký tự, danh mục phải đang hoạt động.
 */
export async function createBlog({ title, content, categoryId, publish = false }) {
  const res = await apiClient.post("/blogs", { title, content, categoryId, publish });
  return unwrap(res, "Tạo bài viết thất bại");
}

/**
 * PUT /blogs/:id — sửa bài. Bài đã qua kiểm duyệt (đã đăng, chờ duyệt, bị từ chối) sẽ bị kiểm duyệt
 * lại khi sửa; bản nháp thì không. Bài đã bị gỡ (BANNED) không sửa được.
 */
export async function updateBlog(id, { title, content, categoryId }) {
  const res = await apiClient.put(`/blogs/${id}`, { title, content, categoryId });
  return unwrap(res, "Cập nhật bài viết thất bại");
}

/** POST /blogs/:id/submit — gửi bản nháp đi kiểm duyệt (chỉ bản nháp của chính mình). */
export async function submitBlog(id) {
  const res = await apiClient.post(`/blogs/${id}/submit`);
  return unwrap(res, "Gửi duyệt thất bại");
}

/** DELETE /blogs/:id — chủ bài xóa hẳn; ADMIN xóa bài người khác thì chỉ gỡ (BANNED). */
export async function deleteBlog(id) {
  const res = await apiClient.delete(`/blogs/${id}`);
  unwrap(res, "Xóa bài viết thất bại");
}

/** POST /blogs/:id/thumbnail — tải/thay ảnh bìa. Trả BlogResponse có thumbnailUrl mới. */
export async function uploadBlogThumbnail(id, file) {
  const formData = new FormData();
  formData.append("file", file);
  const res = await apiClient.post(`/blogs/${id}/thumbnail`, formData, {
    headers: { "Content-Type": "multipart/form-data" },
  });
  return unwrap(res, "Tải ảnh bìa thất bại");
}
