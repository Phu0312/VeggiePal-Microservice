export { formatVnd, formatDateTime, getPaymentStatusInfo } from "@/features/payment/utils/paymentFormat";

export const STATUS_LABELS = {
  PENDING: "Chưa thanh toán",
  PAID: "Đã thanh toán",
  CANCELLED: "Đã huỷ",
  FAILED: "Thất bại",
};

export const PLAN_LABELS = {
  FREE: "Gói Khám Phá",
  PLUS: "Gói Plus",
  PRO: "Gói Pro",
};

// Màu thanh/thẻ theo khoá (dùng token chart-*).
export const STATUS_BAR_CLASS = {
  PAID: "bg-chart-1",
  PENDING: "bg-chart-4",
  CANCELLED: "bg-chart-3",
  FAILED: "bg-chart-5",
};

export const PLAN_BAR_CLASS = {
  FREE: "bg-chart-3",
  PLUS: "bg-chart-2",
  PRO: "bg-chart-4",
};

export const GROUP_OPTIONS = [
  { value: "DAY", label: "Theo ngày" },
  { value: "MONTH", label: "Theo tháng" },
];

export const toOptions = (labels, allLabel) => [
  { value: "", label: allLabel },
  ...Object.entries(labels).map(([value, label]) => ({ value, label })),
];

/**
 * Chuyển giá trị <input type="date"> ("2026-10-22") thành Instant ISO (UTC) theo giờ địa phương.
 * endOfDay = true -> 23:59:59.999 cuối ngày để bao trọn ngày kết thúc.
 */
export function toInstant(dateValue, endOfDay = false) {
  if (!dateValue) return undefined;
  const [y, m, d] = dateValue.split("-").map(Number);
  const date = endOfDay ? new Date(y, m - 1, d, 23, 59, 59, 999) : new Date(y, m - 1, d, 0, 0, 0, 0);
  return date.toISOString();
}

export function formatNumber(value) {
  return Number(value ?? 0).toLocaleString("vi-VN");
}

/** "2026-10-22" -> "22/10", "2026-10" -> "10/2026" (nhãn trục cho biểu đồ doanh thu). */
export function formatPeriod(period) {
  if (!period) return "";
  const parts = String(period).split("-");
  if (parts.length === 3) return `${parts[2]}/${parts[1]}`;
  if (parts.length === 2) return `${parts[1]}/${parts[0]}`;
  return period;
}
