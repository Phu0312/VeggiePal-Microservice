import apiClient from "@/shared/api/apiClient";

/**
 * AI monitoring APIs (ai-service qua api-gateway). Chỉ ADMIN.
 * FE gọi `/ai/admin/monitoring/...` vì baseURL đã là `.../api` (gateway có route /api/ai/** -> /ai/**).
 *   GET /ai/admin/monitoring/summary?days=       tổng hợp N ngày gần nhất (BE giới hạn 1-90)
 *   GET /ai/admin/monitoring/logs/search?...     usage log có lọc + phân trang (size tối đa 100)
 *   GET /ai/admin/monitoring/models              model đang cấu hình cho từng tác vụ
 *   GET /ai/admin/monitoring/limits              quota / giới hạn token đang áp dụng
 * (GET .../logs chỉ trả 100 log mới nhất, không lọc được nên không dùng; đã có logs/search.)
 *
 * Summary: { periodDays, requests, promptTokens, completionTokens, averageLatencyMs, failedRequests }
 * UsageLog: { id, userId (null = khách), principalKey ("user:7" | "guest:<uuid>"), feature, model,
 *   status ("SUCCESS" | "FAILED"), promptTokens, completionTokens, latencyMs, errorMessage, createdAt }
 * LogPage: { items, page, size, totalElements, totalPages }
 * feature: CHAT | MEAL_PLAN | MODERATION | RECOMMENDATION | TRANSCRIPTION | VIDEO
 * Models: { chat, moderation, recommendation, mealPlan, videoExtraction, transcription }
 * Limits: { guestChatRequestsPerDay, memberChatRequestsPerDay, dailyTokenLimit, maxHistoryMessages, maxInputCharacters }
 */

const EMPTY_LOG_PAGE = { items: [], page: 0, size: 20, totalElements: 0, totalPages: 0 };

// ai-service dùng dải mã 60xx; 403 và 404 đều mang mã 6002 nên phải xét thêm HTTP status.
function toMessage(res, fallbackMessage) {
  if (res.status === 401) return "Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại";
  if (res.status === 403) return "Bạn không có quyền xem dữ liệu giám sát AI";
  if (res.status === 400) return "Bộ lọc không hợp lệ, vui lòng kiểm tra lại";
  return res.data?.message || fallbackMessage;
}

function unwrap(res, fallbackMessage) {
  if (res.status >= 400) throw new Error(toMessage(res, fallbackMessage));
  return res.data?.result;
}

/** GET /ai/admin/monitoring/summary */
export async function getUsageSummary(days = 7) {
  const res = await apiClient.get("/ai/admin/monitoring/summary", { params: { days } });
  return unwrap(res, "Không lấy được số liệu tổng hợp");
}

/**
 * GET /ai/admin/monitoring/logs/search
 * from / to: chuỗi ISO không múi giờ ("2026-10-01T00:00:00"). userId: số, bỏ trống = tất cả.
 */
export async function searchUsageLogs({ feature, status, userId, from, to, page = 0, size = 20 } = {}) {
  const res = await apiClient.get("/ai/admin/monitoring/logs/search", {
    params: {
      feature: feature || undefined,
      status: status || undefined,
      userId: userId || undefined,
      from: from || undefined,
      to: to || undefined,
      page,
      size,
    },
  });
  return unwrap(res, "Không lấy được nhật ký sử dụng AI") ?? EMPTY_LOG_PAGE;
}

/** GET /ai/admin/monitoring/models */
export async function getAiModels() {
  const res = await apiClient.get("/ai/admin/monitoring/models");
  return unwrap(res, "Không lấy được danh sách model");
}

/** GET /ai/admin/monitoring/limits */
export async function getAiLimits() {
  const res = await apiClient.get("/ai/admin/monitoring/limits");
  return unwrap(res, "Không lấy được giới hạn sử dụng");
}
