import { useCallback } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { toast } from "sonner";

import { selectIsAuthenticated, useAuthStore } from "@/features/auth/store/authStore";

/**
 * Dùng cho nút/hành động chỉ thành viên mới làm được (vote, bình luận...) trên trang công khai.
 * `requireLogin()` trả true nếu đã đăng nhập; nếu chưa thì báo, đá sang /login
 * (nhớ trang hiện tại để login xong quay lại, giống ProtectedRoute) và trả false.
 */
export function useRequireLogin() {
  const isAuthenticated = useAuthStore(selectIsAuthenticated);
  const navigate = useNavigate();
  const location = useLocation();

  const requireLogin = useCallback(() => {
    if (isAuthenticated) return true;
    toast.info("Vui lòng đăng nhập để tiếp tục");
    navigate("/login", { state: { from: location } });
    return false;
  }, [isAuthenticated, navigate, location]);

  return { isAuthenticated, requireLogin };
}
