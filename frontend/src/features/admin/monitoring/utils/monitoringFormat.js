// Khoảng thời gian tổng hợp (BE cho phép 1-90 ngày).
export const DAY_OPTIONS = [
  { value: 7, label: "7 ngày" },
  { value: 30, label: "30 ngày" },
  { value: 90, label: "90 ngày" },
];

// Nhãn tiếng Việt cho các giá trị của ai-service (khóa theo đúng chuỗi BE trả).
export const FEATURE_LABELS = {
  CHAT: "Chatbot",
  MEAL_PLAN: "Thực đơn",
  MODERATION: "Kiểm duyệt",
  RECOMMENDATION: "Gợi ý nội dung",
  TRANSCRIPTION: "Chuyển giọng nói",
  VIDEO: "Xử lý video",
};

export const STATUS_LABELS = {
  SUCCESS: "Thành công",
  FAILED: "Thất bại",
};

// Model theo tác vụ: khóa của GET /models -> tên hiển thị.
export const MODEL_LABELS = {
  chat: "Chatbot",
  moderation: "Kiểm duyệt",
  recommendation: "Gợi ý nội dung",
  mealPlan: "Thực đơn",
  videoExtraction: "Bóc tách công thức từ video",
  transcription: "Chuyển giọng nói",
};

// Giới hạn: khóa của GET /limits -> [tên hiển thị, đơn vị].
export const LIMIT_LABELS = {
  guestChatRequestsPerDay: ["Khách chat mỗi ngày", "lượt"],
  memberChatRequestsPerDay: ["Thành viên chat mỗi ngày", "lượt"],
  dailyTokenLimit: ["Giới hạn token mỗi ngày", "token"],
  maxHistoryMessages: ["Số tin nhắn lịch sử gửi kèm", "tin"],
  maxInputCharacters: ["Độ dài tin nhắn tối đa", "ký tự"],
};

export const formatNumber = (value) =>
  value == null ? "—" : Number(value).toLocaleString("vi-VN", { maximumFractionDigits: 0 });

/** Tỉ lệ lỗi (%) làm tròn 1 chữ số; chưa có request nào thì trả null. */
export function failureRate(summary) {
  if (!summary?.requests) return null;
  const rate = (summary.failedRequests / summary.requests) * 100;
  return `${rate.toLocaleString("vi-VN", { maximumFractionDigits: 1 })}%`;
}

/** "2026-10-16T12:30:00" -> "16/10/2026 12:30:00" (BE trả giờ máy chủ, không kèm múi giờ). */
export function formatDateTime(value) {
  if (!value) return "—";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "—";
  return date.toLocaleString("vi-VN", { hour12: false });
}

/** Giá trị <input type="date"> ("2026-10-01") -> tham số ISO của BE; `endOfDay` lấy cuối ngày. */
export function toIsoDateTime(dateValue, endOfDay = false) {
  if (!dateValue) return undefined;
  return `${dateValue}T${endOfDay ? "23:59:59" : "00:00:00"}`;
}

/** Người gọi của một log: userId nếu là thành viên, "Khách" nếu là guest. */
export function describeCaller(log) {
  if (log.userId != null) return `#${log.userId}`;
  return log.principalKey?.startsWith("guest:") ? "Khách" : "—";
}
