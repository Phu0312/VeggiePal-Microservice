import { useEffect } from "react";
import { toast } from "sonner";

import { useAuthStore } from "@/features/auth/store/authStore";
import { getTokenExpiryMs } from "@/lib/jwt";

// setTimeout chỉ nhận tối đa ~24,8 ngày; quá hạn đó thì hẹn lại theo từng đoạn.
const MAX_TIMEOUT_MS = 2 ** 31 - 1;

/**
 * Tự đăng xuất khi token hết hạn (đọc từ claim "exp" của JWT).
 * Gọi một lần ở gốc app. Token không phải JWT / không có "exp" thì không làm gì,
 * lúc đó việc hết hạn do server từ chối request quyết định.
 */
export function useAutoLogout() {
  const token = useAuthStore((s) => s.token);
  const logout = useAuthStore((s) => s.logout);

  useEffect(() => {
    const expiry = token ? getTokenExpiryMs(token) : null;
    if (!expiry) return;

    let timer;
    const check = () => {
      const remaining = expiry - Date.now();
      if (remaining <= 0) {
        logout();
        toast.info("Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại.");
        return;
      }
      timer = setTimeout(check, Math.min(remaining, MAX_TIMEOUT_MS));
    };

    check();
    return () => clearTimeout(timer);
  }, [token, logout]);
}
