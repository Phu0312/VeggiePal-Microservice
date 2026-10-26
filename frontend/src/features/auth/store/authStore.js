import { create } from "zustand";

import { clearSession, loadSession, saveSession } from "@/features/auth/utils/authStorage";
import { queryClient } from "@/lib/queryClient";

// Khôi phục phiên khi mở app (token hết hạn sẽ bị bỏ ngay ở bước này).
const initial = loadSession();

/**
 * Nguồn sự thật về trạng thái đăng nhập của toàn app.
 * - token / user: lưu để giữ phiên khi F5. Nơi lưu phụ thuộc `remember`:
 *   true -> localStorage (còn sau khi đóng trình duyệt), false -> sessionStorage.
 * - remember: người dùng có tick "Ghi nhớ đăng nhập" ở lần đăng nhập này hay không.
 */
export const useAuthStore = create((set, get) => ({
    token: initial.token,
    user: initial.user,
    remember: initial.remember,

    // gọi sau khi login thành công. Các lần cập nhật sau đó (vd. đồng bộ hồ sơ)
    // không truyền `remember` thì giữ nguyên lựa chọn hiện tại.
    setAuth: ({ token, user, remember = get().remember }) => {
        saveSession({ token, user, remember });
        set({ token, user, remember });
    },

    logout: () => {
        clearSession();
        set({ token: null, user: null, remember: false });
        // Xóa cache React Query để user đăng nhập sau không thấy dữ liệu của user trước.
        queryClient.clear();
    },
}));

// selector tiện dùng: const isAuthenticated = useAuthStore(selectIsAuthenticated)
export const selectIsAuthenticated = (s) => Boolean(s.token);
