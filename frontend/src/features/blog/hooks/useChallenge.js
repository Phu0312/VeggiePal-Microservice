import { useCallback, useEffect, useMemo, useState, useSyncExternalStore } from "react";

import { useAuthStore } from "@/features/auth/store/authStore";
import {
  CHALLENGE_DAYS,
  applyCheckIn,
  challengeStorageKey,
  parseRecord,
  readProgress,
  toDateKey,
} from "@/features/blog/utils/challenge";

// Tiến độ thử thách lưu ở localStorage (chưa có API). Truy cập storage có thể ném lỗi (chế độ
// riêng tư, bị chặn dữ liệu), nên mọi lần đọc/ghi đều bọc try/catch và rơi về "chưa tham gia".
const listeners = new Set();

function subscribe(listener) {
  listeners.add(listener);
  // Sự kiện "storage" chỉ bắn ở tab khác, nên tab hiện tại tự thông báo qua `listeners`.
  window.addEventListener("storage", listener);
  return () => {
    listeners.delete(listener);
    window.removeEventListener("storage", listener);
  };
}

function readRaw(key) {
  try {
    return key ? window.localStorage.getItem(key) : null;
  } catch {
    return null;
  }
}

function writeRaw(key, value) {
  try {
    window.localStorage.setItem(key, value);
  } catch {
    // Không lưu được thì tiến độ chỉ còn trong phiên này; bỏ qua để không làm hỏng trang.
  }
  listeners.forEach((listener) => listener());
}

/**
 * Tiến độ thử thách 7 ngày của user đang đăng nhập.
 * Trả { days, total, checkedToday, completed, broken, checkIn }.
 * `checkIn()` trả true khi lần check-in này vừa hoàn thành thử thách (để mở popup phần thưởng).
 * Khách chưa đăng nhập luôn ở 0 ngày.
 */
export function useChallenge() {
  const userId = useAuthStore((s) => s.user?.id ?? null);
  const key = userId == null ? null : challengeStorageKey(userId);

  const raw = useSyncExternalStore(
    subscribe,
    () => readRaw(key),
    () => null
  );
  const record = useMemo(() => parseRecord(raw), [raw]);

  // Ngày hôm nay luôn cập nhật: qua nửa đêm hoặc quay lại tab sau lúc ngủ thì nút check-in tự mở lại.
  const [today, setToday] = useState(() => toDateKey(new Date()));
  useEffect(() => {
    const refresh = () => setToday(toDateKey(new Date()));
    const timer = window.setInterval(refresh, 60_000);
    document.addEventListener("visibilitychange", refresh);
    return () => {
      window.clearInterval(timer);
      document.removeEventListener("visibilitychange", refresh);
    };
  }, []);

  const progress = readProgress(record, today);

  const checkIn = useCallback(() => {
    if (!key) return false;
    // Đọc lại từ storage ngay lúc bấm để không ghi đè dữ liệu mới hơn từ tab khác.
    const current = parseRecord(readRaw(key));
    const todayKey = toDateKey(new Date());
    const next = applyCheckIn(current, todayKey);
    if (next === current) return false;
    writeRaw(key, JSON.stringify(next));
    return next.completedAt === todayKey;
  }, [key]);

  return { ...progress, total: CHALLENGE_DAYS, checkIn };
}
