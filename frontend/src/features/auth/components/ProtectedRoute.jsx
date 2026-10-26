import { Navigate, useLocation } from "react-router-dom";
import { useAuthStore, selectIsAuthenticated } from "@/features/auth/store/authStore";

// Bọc quanh route cần đăng nhập. Chưa đăng nhập -> đá về /login,
// nhớ lại trang đang muốn vào để login xong quay lại.
export default function ProtectedRoute({ children }) {
  const isAuthenticated = useAuthStore(selectIsAuthenticated);
  const location = useLocation();

  if (!isAuthenticated) {
    return <Navigate to="/login" replace state={{ from: location }} />;
  }
  return children;
}
