import { useCallback, useEffect, useState } from "react";

// Chờ chừng này giây mới cho bấm "Gửi lại" (BE giới hạn 3 mã/giờ/email, 10 lần/giờ/IP).
export const RESEND_COOLDOWN_SECONDS = 60;

/** Đếm ngược cho nút "Gửi lại mã". `start()` sau mỗi lần gửi; `remaining` = 0 là bấm được. */
export function useResendCountdown(seconds = RESEND_COOLDOWN_SECONDS) {
  const [remaining, setRemaining] = useState(0);

  useEffect(() => {
    if (remaining <= 0) return;
    const timer = setTimeout(() => setRemaining((value) => value - 1), 1000);
    return () => clearTimeout(timer);
  }, [remaining]);

  const start = useCallback(() => setRemaining(seconds), [seconds]);
  return { remaining, start };
}
