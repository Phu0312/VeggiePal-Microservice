import { unwrapVideoResponse as unwrap } from "@/features/video/api/videoErrors";
import apiClient from "@/shared/api/apiClient";

const EMPTY_PAGE = { items: [], page: 0, size: 10, totalElements: 0, totalPages: 0 };

/**
 * GET /videos — danh sách video đã được duyệt & xuất bản (PUBLISHED), mới nhất trước.
 * Công khai, không cần token. Phân trang 0-based.
 */
export async function getVideos({ categoryId, page = 0, size = 12 } = {}) {
  const res = await apiClient.get("/videos", {
    params: {
      categoryId: categoryId || undefined,
      page,
      size,
    },
  });
  return unwrap(res, "Không lấy được danh sách video") ?? EMPTY_PAGE;
}

/**
 * GET /videos/:id — chi tiết video đã xuất bản; mỗi lần gọi server tính thêm 1 lượt xem.
 * Công khai, không cần token.
 */
export async function getVideo(id) {
  const res = await apiClient.get(`/videos/${id}`);
  return unwrap(res, "Không tìm thấy video hoặc video chưa được đăng");
}

/**
 * POST /videos — đăng video mới (multipart/form-data).
 * Cần đăng nhập. Form gửi đúng một trong hai: file .mp4 (≤ 30MB) hoặc youtubeUrl.
 * Kèm title, description, categoryId, publish (boolean).
 */
export async function createVideo(formData, { onUploadProgress } = {}) {
  const res = await apiClient.post("/videos", formData, {
    headers: { "Content-Type": "multipart/form-data" },
    onUploadProgress,
  });
  return unwrap(res, "Đăng video thất bại");
}

/**
 * GET /videos/me — video của người dùng hiện tại ở mọi trạng thái.
 * Cần đăng nhập. status: DRAFT | PENDING | PUBLISHED | REJECTED | BANNED (bỏ trống = tất cả).
 */
export async function getMyVideos({ status, page = 0, size = 10 } = {}) {
  const res = await apiClient.get("/videos/me", {
    params: {
      status: status || undefined,
      page,
      size,
    },
  });
  return unwrap(res, "Không lấy được danh sách video của bạn") ?? EMPTY_PAGE;
}

/**
 * PUT /videos/:id — sửa tiêu đề, mô tả, danh mục. Nguồn video (file hoặc youtube) không đổi.
 * Nếu video đã qua kiểm duyệt thì sau khi sửa sẽ được kiểm duyệt lại.
 */
export async function updateVideo(id, { title, description, categoryId }) {
  const res = await apiClient.put(`/videos/${id}`, {
    title,
    description: description || "",
    categoryId,
  });
  return unwrap(res, "Cập nhật video thất bại");
}

/**
 * POST /videos/:id/submit — gửi bản nháp đi kiểm duyệt.
 */
export async function submitVideo(id) {
  const res = await apiClient.post(`/videos/${id}/submit`);
  return unwrap(res, "Gửi duyệt video thất bại");
}

/**
 * DELETE /videos/:id — chủ xóa thật, admin xóa người khác thì video bị BANNED.
 */
export async function deleteVideo(id) {
  const res = await apiClient.delete(`/videos/${id}`);
  unwrap(res, "Xóa video thất bại");
}
