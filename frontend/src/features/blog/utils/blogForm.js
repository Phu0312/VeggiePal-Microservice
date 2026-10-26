// Logic thuần của form bài viết: kiểm tra ảnh bìa + diễn giải kết quả kiểm duyệt của BE.

export const THUMBNAIL_MAX_BYTES = 5 * 1024 * 1024;
export const THUMBNAIL_TYPES = ["image/jpeg", "image/png", "image/webp"];

/** Kiểm tra ảnh bìa theo luật của BE (JPEG/PNG/WEBP, ≤ 5MB). Trả message lỗi hoặc null nếu hợp lệ. */
export function validateThumbnail(file) {
  if (!file) return null;
  if (!THUMBNAIL_TYPES.includes(file.type)) return "Ảnh bìa phải là JPEG, PNG hoặc WEBP";
  if (file.size > THUMBNAIL_MAX_BYTES) return "Ảnh bìa không được vượt quá 5MB";
  return null;
}

/**
 * Diễn giải BlogResponse sau khi tạo / sửa / gửi duyệt thành thông báo cho người dùng.
 * Trả { tone: "success" | "info" | "error", message } để chọn toast.success / info / error.
 * BE kiểm duyệt ngay lúc lưu nên trạng thái trả về chính là kết quả kiểm duyệt.
 */
export function describeBlogOutcome(blog) {
  switch (blog?.status) {
    case "PUBLISHED":
      return { tone: "success", message: "Bài viết đã được đăng" };
    case "PENDING":
      return { tone: "info", message: "Bài viết đang chờ kiểm duyệt, bạn sẽ thấy nó khi được duyệt" };
    case "REJECTED":
      return {
        tone: "error",
        message: blog.moderationReason
          ? `Bài viết không vượt qua kiểm duyệt: ${blog.moderationReason}`
          : "Bài viết không vượt qua kiểm duyệt",
      };
    default:
      return { tone: "success", message: "Đã lưu bản nháp" };
  }
}
