// Nhãn + màu + gợi ý cho trạng thái của bài viết (blog-service), công thức (recipe-service),
// video (blog-service) và job bóc tách video (ai-service).
// tone ánh xạ sang class ở StatusBadge: success | warning | danger | muted.

const BLOG_STATUS = {
  DRAFT: { label: "Bản nháp", tone: "muted", hint: "Chưa gửi duyệt, chỉ mình bạn thấy" },
  PENDING: { label: "Chờ duyệt", tone: "warning", hint: "Đang chờ kiểm duyệt" },
  PUBLISHED: { label: "Đã đăng", tone: "success", hint: "" },
  REJECTED: { label: "Bị từ chối", tone: "danger", hint: "Không vượt qua kiểm duyệt" },
  BANNED: { label: "Đã bị gỡ", tone: "danger", hint: "Quản trị viên đã gỡ bài này" },
};

const RECIPE_STATUS = {
  DRAFT: { label: "Bản nháp", tone: "muted", hint: "Chưa đăng, chỉ mình bạn thấy" },
  PUBLISHED: { label: "Đã đăng", tone: "success", hint: "" },
  HIDDEN: { label: "Đang ẩn", tone: "danger", hint: "Công thức đang bị ẩn khỏi mọi người" },
};

const VIDEO_STATUS = {
  DRAFT: { label: "Bản nháp", tone: "muted", hint: "Chưa gửi duyệt, chỉ mình bạn thấy" },
  PENDING: { label: "Chờ duyệt", tone: "warning", hint: "Đang chờ kiểm duyệt" },
  PUBLISHED: { label: "Đã đăng", tone: "success", hint: "" },
  REJECTED: { label: "Bị từ chối", tone: "danger", hint: "Không vượt qua kiểm duyệt" },
  BANNED: { label: "Đã bị gỡ", tone: "danger", hint: "Quản trị viên đã gỡ video này" },
};

// Job bóc tách công thức từ video (ai-service).
const VIDEO_JOB_STATUS = {
  PROCESSING: { label: "Đang xử lý", tone: "warning", hint: "AI đang bóc tách, bạn có thể rời trang này" },
  COMPLETED: { label: "Hoàn tất", tone: "success", hint: "" },
  FAILED: { label: "Thất bại", tone: "danger", hint: "" },
};

// Bộ lọc ở tab bài viết: "" = tất cả (không gửi status lên BE).
export const BLOG_STATUS_FILTERS = [
  { value: "", label: "Tất cả" },
  ...Object.entries(BLOG_STATUS).map(([value, { label }]) => ({ value, label })),
];

// Bộ lọc ở tab video: "" = tất cả.
export const VIDEO_STATUS_FILTERS = [
  { value: "", label: "Tất cả" },
  ...Object.entries(VIDEO_STATUS).map(([value, { label }]) => ({ value, label })),
];

const UNKNOWN = { label: "Không rõ", tone: "muted", hint: "" };

/** Thông tin hiển thị của một trạng thái bài viết; trạng thái lạ rơi về "Không rõ". */
export function getBlogStatusInfo(status) {
  return BLOG_STATUS[status] ?? UNKNOWN;
}

/** Thông tin hiển thị của một trạng thái công thức. */
export function getRecipeStatusInfo(status) {
  return RECIPE_STATUS[status] ?? UNKNOWN;
}

/** Thông tin hiển thị của một trạng thái video. */
export function getVideoStatusInfo(status) {
  return VIDEO_STATUS[status] ?? UNKNOWN;
}

/** Thông tin hiển thị của một trạng thái job bóc tách video. */
export function getVideoJobStatusInfo(status) {
  return VIDEO_JOB_STATUS[status] ?? UNKNOWN;
}

// Hành động nào hợp lệ ở trạng thái nào (khớp luật chuyển trạng thái của BE).

/**
 * Sửa bài: BE cho sửa bài ở mọi trạng thái trừ BANNED (bài bị gỡ là cuối cùng, sửa sẽ bị từ chối).
 * Chủ bài đọc lại được bài chưa đăng qua GET /blogs/:id (kèm token) nên form sửa nạp được cả
 * bản nháp, chờ duyệt, bị từ chối.
 */
export const canEditBlog = (status) => status !== "BANNED";

/** Gửi duyệt: chỉ bản nháp (BE trả lỗi 3015 với trạng thái khác). */
export const canSubmitBlog = (status) => status === "DRAFT";

/** Đăng công thức: chỉ bản nháp. (BE từ chối đăng công thức HIDDEN / ARCHIVED với lỗi 4108.) */
export const canPublishRecipe = (status) => status === "DRAFT";

/** Sửa video: BE cho sửa ở mọi trạng thái trừ BANNED. */
export const canEditVideo = (status) => status !== "BANNED";

/** Gửi duyệt video: chỉ bản nháp (BE trả lỗi 3068 với trạng thái khác). */
export const canSubmitVideo = (status) => status === "DRAFT";
