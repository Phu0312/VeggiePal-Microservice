import { Navigate, Outlet, useLocation } from "react-router-dom";

import { selectIsAuthenticated, useAuthStore } from "@/features/auth/store/authStore";
import { isAdmin } from "@/features/auth/utils/roleRedirect";

// Route layout chỉ dành cho ADMIN. Chưa đăng nhập -> /login (nhớ trang muốn vào để quay lại);
// đã đăng nhập nhưng không phải ADMIN -> về trang chủ.
// Đây chỉ là chặn ở giao diện; BE vẫn tự kiểm tra role ở từng API quản trị.
export default function AdminRoute() {
  const isAuthenticated = useAuthStore(selectIsAuthenticated);
  const user = useAuthStore((s) => s.user);
  const location = useLocation();

  if (!isAuthenticated) {
    return <Navigate to="/login" replace state={{ from: location }} />;
  }
  if (!isAdmin(user)) {
    return <Navigate to="/" replace />;
  }
  return <Outlet />;
}
