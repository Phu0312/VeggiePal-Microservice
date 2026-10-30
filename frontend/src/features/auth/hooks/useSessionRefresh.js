import { useEffect } from "react";

import { useAuthStore } from "@/features/auth/store/authStore";
import { getTokenExpiryMs } from "@/lib/jwt";

// setTimeout chỉ nhận tối đa ~24,8 ngày; quá hạn đó thì hẹn lại theo từng đoạn.
const MAX_TIMEOUT_MS = 2 ** 31 - 1;
// Làm mới trước khi access token hết hạn chừng này (JWT sống 30 phút).
const REFRESH_LEEWAY_MS = 30_000;
// Mất mạng / máy chủ lỗi lúc làm mới thì giữ phiên và thử lại sau chừng này.
const RETRY_MS = 30_000;

/**
 * Giữ phiên đăng nhập: làm mới access token chủ động trước khi hết hạn ~30 giây (đọc claim "exp" của JWT).
 * Chỉ đăng xuất khi BE từ chối refresh token (store tự xử lý trong `refreshSession`).
 * Phiên cũ không có refresh token (đăng nhập trước khi có cơ chế này) thì đăng xuất khi token hết hạn như trước.
 * Gọi một lần ở gốc app. Token không phải JWT / không có "exp" thì không làm gì,
 * lúc đó việc hết hạn do server từ chối request quyết định.
 */
export function useSessionRefresh() {
  const token = useAuthStore((s) => s.token);
  const hasRefreshToken = useAuthStore((s) => Boolean(s.refreshToken));
  const refreshSession = useAuthStore((s) => s.refreshSession);
  const expireSession = useAuthStore((s) => s.expireSession);

  useEffect(() => {
    const expiry = token ? getTokenExpiryMs(token) : null;
    if (!expiry) return;

    let timer;
    let cancelled = false;
    const schedule = (delay) => {
      timer = setTimeout(check, Math.min(Math.max(delay, 0), MAX_TIMEOUT_MS));
    };

    async function check() {
      const remaining = expiry - Date.now();
      if (!hasRefreshToken) {
        if (remaining <= 0) expireSession();
        else schedule(remaining);
        return;
      }
      if (remaining > REFRESH_LEEWAY_MS) {
        schedule(remaining - REFRESH_LEEWAY_MS);
        return;
      }
      // Thành công thì token đổi và effect chạy lại với hạn mới; BE từ chối thì store đã đăng xuất.
      const ok = await refreshSession();
      if (!ok && !cancelled && useAuthStore.getState().token === token) schedule(RETRY_MS);
    }

    check();
    return () => {
      cancelled = true;
      clearTimeout(timer);
    };
  }, [token, hasRefreshToken, refreshSession, expireSession]);
}
