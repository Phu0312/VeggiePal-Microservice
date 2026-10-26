import { recipeStateFromResponse } from "@/features/video/utils/videoJob";
import apiClient from "@/shared/api/apiClient";

// Upload tối đa 100MB nên cho chờ lâu hơn mặc định; BE trả 202 ngay sau khi kiểm tra file bằng ffprobe.
const UPLOAD_TIMEOUT_MS = 600_000;
// Bóc tách video đã đăng: BE tải tệp từ Cloudinary về và kiểm tra bằng ffprobe trước khi trả 202.
const PROCESS_EXISTING_TIMEOUT_MS = 120_000;

const EMPTY_PAGE = { content: [], page: 0, size: 0, totalElements: 0, totalPages: 0, first: true, last: true };

// ai-service dùng dải mã 60xx. Message gốc của BE là tiếng Anh nên đổi sang tiếng Việt theo `code`.
const VI_MESSAGES = {
  6000: "Tệp không phải video hợp lệ, vui lòng chọn tệp video khác",
  6001: "Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại",
  6002: "Không tìm thấy lượt bóc tách này",
  6003: "Bạn đã dùng hết lượt bóc tách video trong tháng này. Bạn có thể nâng cấp gói tại /pricing để tiếp tục hoặc quay lại vào tháng sau",
  6004: "AI đang tạm thời quá tải, vui lòng thử lại sau ít phút",
  6005: "Tính năng AI chưa được cấu hình trên máy chủ",
  6007: "AI chưa bóc tách được công thức từ video này, vui lòng thử lại",
  6008: "Không xử lý được video này: tệp bị lỗi hoặc dài hơn 30 phút",
  6009: "Tệp video vượt quá dung lượng cho phép (tối đa 100MB)",
  6020: "Hệ thống đang bận xử lý nhiều video, vui lòng thử lại sau ít phút",
  6021: "Chưa hỗ trợ bóc tách video YouTube, chỉ bóc tách được video tải lên trực tiếp",
  6022: "Video này đang được bóc tách, vui lòng chờ trong giây lát",
  6023: "Lần bóc tách trước của video này chưa thành công",
  6024: "Video không có đủ thông tin công thức (nguyên liệu kèm số lượng và các bước) để AI bóc tách",
  6999: "Máy chủ đang gặp lỗi, vui lòng thử lại sau ít phút",
};

// Lỗi 401/413/429/503 do Spring Security hoặc multipart trả về có thể không kèm mã 60xx nên dựa thêm vào HTTP status.
function toMessage(res, fallbackMessage) {
  const byCode = VI_MESSAGES[res.data?.code];
  if (byCode) return byCode;
  if (res.status === 401) return VI_MESSAGES[6001];
  if (res.status === 413) return VI_MESSAGES[6009];
  if (res.status === 429) return VI_MESSAGES[6003];
  if (res.status === 503) return VI_MESSAGES[6004];
  return res.data?.message || fallbackMessage;
}

// validateStatus tắt throw theo status, nên chỉ còn lỗi mạng / quá thời gian chờ rơi vào catch.
function networkError(error, timeoutMessage) {
  return new Error(
    error?.code === "ECONNABORTED" ? timeoutMessage : "Không kết nối được máy chủ, vui lòng thử lại",
    { cause: error },
  );
}

function unwrap(res, fallbackMessage) {
  if (res.status >= 400) throw new Error(toMessage(res, fallbackMessage));
  return res.data?.result;
}

/**
 * POST /ai/videos/process (multipart, field `file`, cần đăng nhập và còn lượt trong gói).
 * BE trả 202 kèm job { id, status: "PROCESSING", ... }; kết quả lấy bằng cách hỏi lại GET /ai/videos/:id.
 */
export async function processVideo(file, { onUploadProgress } = {}) {
  const formData = new FormData();
  formData.append("file", file);

  let res;
  try {
    res = await apiClient.post("/ai/videos/process", formData, {
      headers: { "Content-Type": "multipart/form-data" },
      timeout: UPLOAD_TIMEOUT_MS,
      onUploadProgress,
    });
  } catch (error) {
    throw networkError(error, "Tải video lên quá thời gian chờ, bạn kiểm tra mạng rồi thử lại nhé");
  }
  return unwrap(res, "Gửi video bóc tách thất bại");
}

/**
 * POST /ai/videos/process-existing { videoId } — bóc tách công thức của một video đã đăng (chỉ video UPLOAD,
 * đã xuất bản). BE trả 202 kèm job: đã có kết quả thì dùng lại (COMPLETED, không trừ lượt), đang chạy thì trả
 * job PROCESSING, còn lại tạo job mới và trừ 1 lượt (hoàn lại nếu thất bại).
 * Theo dõi bằng getVideoRecipe, không dùng GET /ai/videos/:id vì job có thể của người khác (BE trả 404).
 */
export async function processExistingVideo(videoId) {
  let res;
  try {
    res = await apiClient.post("/ai/videos/process-existing", { videoId }, { timeout: PROCESS_EXISTING_TIMEOUT_MS });
  } catch (error) {
    throw networkError(error, "Gửi video bóc tách quá thời gian chờ, bạn thử lại sau nhé");
  }
  return unwrap(res, "Gửi video bóc tách thất bại");
}

/**
 * GET /ai/videos/by-video/:videoId — công thức AI dùng chung của một video đã đăng (công khai, không tốn lượt).
 * Trả { state, extraction? } với state: "ready" | "processing" | "failed" | "unsupported" | "none"
 * (xem recipeStateFromResponse); lỗi khác (mạng, 5xx...) thì ném.
 */
export async function getVideoRecipe(videoId) {
  let res;
  try {
    res = await apiClient.get(`/ai/videos/by-video/${videoId}`);
  } catch (error) {
    throw networkError(error, "Tải công thức quá thời gian chờ");
  }
  const state = recipeStateFromResponse(res);
  if (state) return state;
  throw new Error(toMessage(res, "Không lấy được công thức AI của video"));
}

/**
 * GET /ai/videos — lịch sử bóc tách của tôi, mới nhất trước.
 * PageResponse { content, page, size, totalElements, totalPages, first, last } (size tối đa 100).
 * Mỗi job: { id, status: PROCESSING | COMPLETED | FAILED, filename, transcript,
 *   extraction: { title, ingredients: [{ name, quantity }], steps: [{ number, instruction }] },
 *   error, createdAt, updatedAt }.
 */
export async function getVideoJobs({ page = 0, size = 10 } = {}) {
  let res;
  try {
    res = await apiClient.get("/ai/videos", { params: { page, size } });
  } catch (error) {
    throw networkError(error, "Tải danh sách quá thời gian chờ");
  }
  return unwrap(res, "Không lấy được lịch sử bóc tách video") ?? EMPTY_PAGE;
}
