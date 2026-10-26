import apiClient from "@/shared/api/apiClient";

/**
 * AI Content Recommendation APIs (ai-service qua gateway).
 * GET /ai/recommendations?interest=&limit= (cần đăng nhập, limit 1-10, mặc định 6).
 * Trả về danh sách Recommendation:
 * [{ type: "BLOG" | "RECIPE", id: number, reason: string, content: JsonNode }]
 */

// ai-service dùng dải mã 60xx. Message gốc của BE là tiếng Anh nên đổi sang tiếng Việt theo `code`.
const VI_MESSAGES = {
  6000: "Yêu cầu gợi ý chưa hợp lệ, vui lòng thử lại",
  6001: "Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại",
  6003: "Hạn mức AI hôm nay đã hết, vui lòng quay lại vào ngày mai",
  6004: "AI đang tạm thời quá tải, vui lòng thử lại sau ít phút",
  6005: "Tính năng AI chưa được cấu hình trên máy chủ",
  6006: "Chưa lấy được dữ liệu bài viết và công thức, vui lòng thử lại sau",
  6007: "AI chưa trả về kết quả hợp lệ, vui lòng thử lại",
  6999: "Máy chủ đang gặp lỗi, vui lòng thử lại sau ít phút",
};

// Lỗi 401/429/503 do Spring Security hoặc gateway trả về có thể không kèm mã 60xx nên dựa thêm vào HTTP status.
function toMessage(res, fallbackMessage) {
  const byCode = VI_MESSAGES[res.data?.code];
  if (byCode) return byCode;
  if (res.status === 401) return VI_MESSAGES[6001];
  if (res.status === 429) return VI_MESSAGES[6003];
  if (res.status === 503) return VI_MESSAGES[6004];
  if (res.status >= 500) return VI_MESSAGES[6999];
  return fallbackMessage;
}

function unwrap(res, fallbackMessage) {
  if (res.status >= 400) {
    throw new Error(toMessage(res, fallbackMessage));
  }
  return res.data?.result;
}

/**
 * Lấy danh sách gợi ý nội dung từ AI.
 * @param {Object} params
 * @param {string} [params.interest] - Chủ đề / sở thích (mặc định BE dùng "ăn chay")
 * @param {number} [params.limit=6] - Số lượng gợi ý (1-10)
 */
export async function getRecommendations({ interest, limit = 6 } = {}) {
  let res;
  try {
    res = await apiClient.get("/ai/recommendations", {
      params: {
        interest: interest?.trim() || undefined,
        limit,
      },
    });
  } catch (error) {
    // validateStatus tắt throw theo status, nên chỉ còn lỗi mạng / máy chủ không phản hồi rơi vào catch.
    throw new Error("Không kết nối được máy chủ, vui lòng thử lại", { cause: error });
  }
  return unwrap(res, "Không lấy được danh sách gợi ý nội dung") ?? [];
}
