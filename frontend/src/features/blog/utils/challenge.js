// Thử thách "7 Ngày Sống Thuần Chay Tươi Mới". Chưa có API nên tiến độ lưu ở localStorage theo từng
// user (xem useChallenge). File này chỉ chứa logic thuần để test được; khi BE có API thì thay phần lưu.
//
// Luật: người dùng tự bắt đầu ở lần check-in đầu tiên. Mỗi ngày check-in được một lần, cần 7 ngày
// liên tiếp. Bỏ lỡ một ngày thì đứt chuỗi và lần check-in kế tiếp bắt đầu lại từ ngày 1.

export const CHALLENGE_DAYS = 7;
export const CHALLENGE_BADGE_NAME = "Trái Tim Xanh Veggie";

const STORAGE_PREFIX = "veggiepal.challenge.v1.";

/** Khóa localStorage của một user. */
export const challengeStorageKey = (userId) => `${STORAGE_PREFIX}${userId}`;

/** Date -> "YYYY-MM-DD" theo giờ địa phương (ngày của người dùng, không phải ngày UTC). */
export function toDateKey(date) {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, "0");
  const d = String(date.getDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

const DATE_KEY = /^\d{4}-\d{2}-\d{2}$/;

/** Số ngày từ `from` đến `to` (cả hai là "YYYY-MM-DD"). Tính qua UTC nên không lệch vì giờ mùa hè. */
export function daysBetween(from, to) {
  const [fy, fm, fd] = from.split("-").map(Number);
  const [ty, tm, td] = to.split("-").map(Number);
  return Math.round((Date.UTC(ty, tm - 1, td) - Date.UTC(fy, fm - 1, fd)) / 86_400_000);
}

export const emptyRecord = () => ({ checkIns: [], completedAt: null });

/** Đọc chuỗi JSON từ localStorage; dữ liệu hỏng hoặc bị sửa tay thì coi như chưa tham gia. */
export function parseRecord(raw) {
  if (!raw) return emptyRecord();
  try {
    const data = JSON.parse(raw);
    const checkIns = Array.isArray(data?.checkIns)
      ? data.checkIns.filter((k) => typeof k === "string" && DATE_KEY.test(k))
      : [];
    const completedAt =
      typeof data?.completedAt === "string" && DATE_KEY.test(data.completedAt)
        ? data.completedAt
        : null;
    return { checkIns, completedAt };
  } catch {
    return emptyRecord();
  }
}

/**
 * Tiến độ hiển thị tại ngày `today`.
 * - completed: đã đủ 7 ngày (huy hiệu giữ mãi)
 * - broken: từng check-in nhưng đã lỡ ít nhất một ngày -> hiện 0, lần check-in sau bắt đầu lại
 */
export function readProgress(record, today) {
  if (record.completedAt) {
    return { days: CHALLENGE_DAYS, checkedToday: false, completed: true, broken: false };
  }

  const last = record.checkIns.at(-1);
  if (!last) return { days: 0, checkedToday: false, completed: false, broken: false };

  const gap = daysBetween(last, today);
  if (gap <= 1) {
    return {
      days: record.checkIns.length,
      checkedToday: gap === 0,
      completed: false,
      broken: false,
    };
  }
  return { days: 0, checkedToday: false, completed: false, broken: true };
}

/** Check-in ngày `today`. Đã check-in rồi hoặc đã hoàn thành thì giữ nguyên. */
export function applyCheckIn(record, today) {
  const progress = readProgress(record, today);
  if (progress.completed || progress.checkedToday) return record;

  // Đứt chuỗi (hoặc chưa có gì) thì bắt đầu lại từ hôm nay.
  const checkIns = progress.days === 0 ? [today] : [...record.checkIns, today];
  return { checkIns, completedAt: checkIns.length >= CHALLENGE_DAYS ? today : null };
}
