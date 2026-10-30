// Hàm thuần của nhật ký dinh dưỡng (ngày, mục tiêu, số liệu), không phụ thuộc React nên test được bằng node:test.

export const MEAL_TYPES = [
  { value: "BREAKFAST", label: "Bữa sáng" },
  { value: "LUNCH", label: "Bữa trưa" },
  { value: "DINNER", label: "Bữa tối" },
  { value: "SNACK", label: "Bữa phụ" },
];

// Bữa mặc định khi mở form "Thêm món" theo giờ hiện tại.
export function mealForHour(hour) {
  if (hour < 10) return "BREAKFAST";
  if (hour < 15) return "LUNCH";
  if (hour < 21) return "DINNER";
  return "SNACK";
}

/** Ngày theo giờ máy người dùng dạng YYYY-MM-DD (không dùng toISOString vì nó đổi sang UTC). */
export function toIsoDate(date) {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, "0");
  const d = String(date.getDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

export function parseIsoDate(value) {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value ?? "");
  if (!match) return null;
  const date = new Date(Number(match[1]), Number(match[2]) - 1, Number(match[3]));
  return toIsoDate(date) === value ? date : null;
}

export function shiftIsoDate(value, days) {
  const date = parseIsoDate(value) ?? new Date();
  date.setDate(date.getDate() + days);
  return toIsoDate(date);
}

const WEEKDAYS = ["Chủ nhật", "Thứ Hai", "Thứ Ba", "Thứ Tư", "Thứ Năm", "Thứ Sáu", "Thứ Bảy"];

/** "Hôm nay", "Hôm qua" hoặc "Thứ Năm, 15/10/2026". */
export function dayLabel(value, today = toIsoDate(new Date())) {
  if (value === today) return "Hôm nay";
  if (value === shiftIsoDate(today, -1)) return "Hôm qua";
  const date = parseIsoDate(value);
  if (!date) return value;
  const dd = String(date.getDate()).padStart(2, "0");
  const mm = String(date.getMonth() + 1).padStart(2, "0");
  return `${WEEKDAYS[date.getDay()]}, ${dd}/${mm}/${date.getFullYear()}`;
}

// Mục tiêu calo (Giảm cân / Duy trì / Tăng cân) lưu ở localStorage để lần sau mở lại vẫn giữ.
const GOAL_KEY = "diary_goal_type";
export const GOAL_TYPES = ["LOSE", "MAINTAIN", "GAIN"];

export function loadGoalType(storage = globalThis.localStorage) {
  try {
    const saved = storage?.getItem(GOAL_KEY);
    return GOAL_TYPES.includes(saved) ? saved : "MAINTAIN";
  } catch {
    return "MAINTAIN";
  }
}

export function saveGoalType(goalType, storage = globalThis.localStorage) {
  try {
    storage?.setItem(GOAL_KEY, goalType);
  } catch {
    // Trình duyệt chặn storage thì chỉ không nhớ được lựa chọn.
  }
}

/** Phần trăm đã đạt (0 – 100) cho thanh tiến độ; không có mục tiêu thì 0. */
export function percentOf(value, target) {
  const v = Number(value);
  const t = Number(target);
  if (!Number.isFinite(v) || !Number.isFinite(t) || t <= 0) return 0;
  return Math.min(100, Math.max(0, Math.round((v / t) * 100)));
}

/** Số gram gọn: 12 -> "12", 12.345 -> "12,3"; không có -> "0". */
export function formatGram(value) {
  const n = Number(value);
  if (value == null || !Number.isFinite(n)) return "0";
  return n.toLocaleString("vi-VN", { maximumFractionDigits: 1 });
}

export function formatNumber(value) {
  const n = Number(value);
  return value != null && Number.isFinite(n) ? n.toLocaleString("vi-VN") : "0";
}

/** Ô nhập số tùy chọn -> số (chấp nhận dấu phẩy thập phân) hoặc undefined khi để trống. */
export function optionalNumber(text) {
  const trimmed = String(text ?? "").trim();
  if (!trimmed) return undefined;
  const n = Number(trimmed.replace(",", "."));
  return Number.isFinite(n) ? n : undefined;
}

/** Gom món theo bữa, giữ đúng thứ tự MEAL_TYPES; món không rõ bữa xếp vào bữa phụ. */
export function groupByMeal(entries = []) {
  const groups = Object.fromEntries(MEAL_TYPES.map(({ value }) => [value, []]));
  for (const entry of entries ?? []) {
    (groups[entry.mealType] ?? groups.SNACK).push(entry);
  }
  return groups;
}
