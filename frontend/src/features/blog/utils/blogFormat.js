// Tên hiển thị khi không tra được tác giả (đang tải, hoặc user bị khóa/chưa kích hoạt).
export const FALLBACK_AUTHOR_NAME = "Người dùng VeggiePal";

const MINUTE = 60 * 1000;
const HOUR = 60 * MINUTE;
const DAY = 24 * HOUR;

/** "vừa xong" / "5 phút trước" / "2 giờ trước" / "3 ngày trước" / dd/mm/yyyy (từ 30 ngày trở lên). */
export function formatTimeAgo(isoDate, now = Date.now()) {
  const time = new Date(isoDate).getTime();
  if (Number.isNaN(time)) return "";

  const diff = Math.max(0, now - time);
  if (diff < MINUTE) return "Vừa xong";
  if (diff < HOUR) return `${Math.floor(diff / MINUTE)} phút trước`;
  if (diff < DAY) return `${Math.floor(diff / HOUR)} giờ trước`;
  if (diff < 30 * DAY) return `${Math.floor(diff / DAY)} ngày trước`;
  return new Date(time).toLocaleDateString("vi-VN");
}

/** 12400 -> "12.4k"; dưới 1000 giữ nguyên số. */
export function formatCompactNumber(value) {
  const n = Number(value) || 0;
  if (n < 1000) return String(n);
  return `${(Math.round(n / 100) / 10).toString()}k`;
}

/** Lấy tối đa 2 chữ cái đầu của tên để làm avatar dự phòng: "Minh Thuận" -> "MT". */
export function getInitials(name) {
  const words = String(name ?? "").trim().split(/\s+/).filter(Boolean);
  if (words.length === 0) return "?";
  const letters = words.length === 1 ? words[0][0] : words[0][0] + words[words.length - 1][0];
  return letters.toUpperCase();
}
