// Tiện ích thuần cho tính năng bóc tách công thức từ video (ai-service).

export const VIDEO_JOB_MAX_BYTES = 100 * 1024 * 1024; // 100MB
export const VIDEO_JOB_MAX_MINUTES = 30;

/** Khoảng thời gian hỏi lại BE khi còn job đang xử lý. */
export const VIDEO_JOB_POLL_MS = 4000;

/**
 * Kiểm tra tệp trước khi gửi: phải là video và ≤ 100MB (BE kiểm lại bằng ffprobe, kể cả thời lượng ≤ 30 phút).
 * Trả chuỗi lỗi tiếng Việt nếu không hợp lệ, hoặc null nếu hợp lệ.
 */
export function validateJobFile(file) {
  if (!file) return "Vui lòng chọn tệp video";
  if (!file.type?.toLowerCase().startsWith("video/")) return "Tệp phải là video (ví dụ .mp4, .mov, .webm)";
  if (file.size > VIDEO_JOB_MAX_BYTES) return "Tệp video vượt quá dung lượng cho phép (tối đa 100MB)";
  return null;
}

/** Còn job nào đang xử lý không — dùng để quyết định có tiếp tục hỏi lại BE hay không. */
export function hasProcessingJob(jobs) {
  return jobs.some((job) => job.status === "PROCESSING");
}

/** COMPLETED nhưng không còn nội dung: BE xóa kết quả sau 30 ngày. */
export function isJobResultExpired(job) {
  return job.status === "COMPLETED" && !job.extraction;
}

// Lý do thất bại do BE ghi vào job (tiếng Anh) -> tiếng Việt.
const JOB_ERROR_MESSAGES = {
  "Video processing failed": "Không xử lý được video: tệp bị lỗi hoặc dài hơn 30 phút",
  "AI provider returned an invalid response": "AI chưa trả về kết quả hợp lệ, bạn thử lại sau nhé",
  "Video does not contain sufficient recipe information":
    "Video không có đủ thông tin công thức (nguyên liệu kèm số lượng và các bước) để AI bóc tách",
  "AI provider is temporarily unavailable": "AI đang tạm thời quá tải, bạn thử lại sau ít phút",
  "AI provider is not configured": "Tính năng AI chưa được cấu hình trên máy chủ",
  "AI daily quota exceeded": "AI đã hết hạn mức sử dụng trong ngày, bạn thử lại vào ngày mai",
  "Video processing queue is full": "Hệ thống đang bận, bạn thử lại sau ít phút",
  "Video processing interrupted or timed out": "Quá trình xử lý bị gián đoạn hoặc quá lâu, bạn thử gửi lại nhé",
};

/** Lý do job thất bại bằng tiếng Việt; lý do lạ rơi về câu chung. */
export function describeJobError(error) {
  return JOB_ERROR_MESSAGES[error] ?? "Xử lý video thất bại, bạn thử lại sau nhé";
}

/**
 * Tên hiển thị của nguồn một job: job tạo từ video đã đăng có filename do BE tự đặt ("blog-video-8.mp4")
 * nên không đưa cho người dùng, thay bằng số video.
 */
export function jobSourceLabel(job) {
  return job.sourceVideoId ? `Video đã đăng #${job.sourceVideoId}` : job.filename;
}

/**
 * Trạng thái công thức AI của một video đã đăng, suy ra từ phản hồi của GET /ai/videos/by-video/:id:
 * "ready" (có kết quả) | "processing" (409, mã 6022) | "failed" (mã 6023) | "unsupported" (mã 6021)
 * | "none" (404, chưa từng bóc tách hoặc kết quả đã hết hạn).
 * Trả null với lỗi khác để nơi gọi ném lỗi.
 */
export function recipeStateFromResponse(res) {
  const code = res.data?.code;
  if (res.status < 400) {
    const extraction = res.data?.result?.extraction;
    return extraction ? { state: "ready", extraction } : { state: "none" };
  }
  if (code === 6022 || res.status === 409) return { state: "processing" };
  if (code === 6023) return { state: "failed" };
  if (code === 6021) return { state: "unsupported" };
  if (res.status === 404) return { state: "none" };
  return null;
}

/** Cùng kiểu trạng thái như trên, suy ra từ job BE trả về sau POST /ai/videos/process-existing. */
export function recipeStateFromJob(job) {
  if (job?.status === "PROCESSING") return { state: "processing" };
  if (job?.status === "COMPLETED" && job.extraction) return { state: "ready", extraction: job.extraction };
  if (job?.status === "FAILED") return { state: "failed" };
  return { state: "none" };
}

/** "12.3 MB" cho dung lượng hiển thị. */
export function formatFileSize(bytes) {
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}
