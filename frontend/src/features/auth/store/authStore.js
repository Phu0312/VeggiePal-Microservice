import { toast } from "sonner";
import { create } from "zustand";

import { refreshSession as refreshSessionApi, revokeSession } from "@/features/auth/api/authApi";
import { SESSION_EXPIRED_MESSAGE } from "@/features/auth/utils/authErrors";
import { canRefresh, clearSession, loadSession, saveSession } from "@/features/auth/utils/authStorage";
import { isTokenExpired } from "@/lib/jwt";
import { queryClient } from "@/lib/queryClient";

// Khôi phục phiên khi mở app (access token lẫn refresh token đều hết hạn thì bị bỏ ngay ở bước này).
const initial = loadSession();

// Chỉ một lần làm mới chạy tại một thời điểm: BE xoay vòng refresh token, hai request cùng dùng token cũ
// thì request sau nhận 1030 và người dùng bị đăng xuất oan. Các request 401 khác chờ chung promise này.
let refreshing = null;

/**
 * Nguồn sự thật về trạng thái đăng nhập của toàn app.
 * - token / refreshToken / refreshExpiresAt / user: lưu để giữ phiên khi F5. Nơi lưu phụ thuộc `remember`:
 *   true -> localStorage (còn sau khi đóng trình duyệt), false -> sessionStorage.
 * - remember: người dùng có tick "Ghi nhớ đăng nhập" ở lần đăng nhập này hay không.
 */
export const useAuthStore = create((set, get) => ({
    token: initial.token,
    refreshToken: initial.refreshToken,
    refreshExpiresAt: initial.refreshExpiresAt,
    user: initial.user,
    remember: initial.remember,

    // Gọi sau khi login thành công. Các lần cập nhật sau đó (vd. đồng bộ hồ sơ, làm mới token)
    // chỉ truyền phần thay đổi, phần còn lại (refresh token, `remember`) giữ nguyên.
    setAuth: (next) => {
        const current = get();
        const session = {
            token: next.token ?? current.token,
            refreshToken: next.refreshToken !== undefined ? next.refreshToken : current.refreshToken,
            refreshExpiresAt:
                next.refreshExpiresAt !== undefined ? next.refreshExpiresAt : current.refreshExpiresAt,
            user: next.user ?? current.user,
            remember: next.remember ?? current.remember,
        };
        saveSession(session);
        set(session);
    },

    /**
     * Đổi refresh token lấy access token mới. Trả `true` nếu đã có token mới.
     * BE từ chối (refresh token hết hạn / bị thu hồi / tài khoản bị khóa) thì đăng xuất;
     * mất mạng hoặc máy chủ lỗi tạm thời thì giữ phiên trên máy và trả `false`.
     */
    refreshSession: () => {
        refreshing ??= doRefresh(get, set).finally(() => {
            refreshing = null;
        });
        return refreshing;
    },

    // Phiên hết hạn hẳn: xóa phiên và báo người dùng đăng nhập lại.
    expireSession: () => {
        if (!get().token) return;
        get().logout({ revoke: false });
        toast.info(SESSION_EXPIRED_MESSAGE);
    },

    // `revoke: false` khi BE đã từ chối refresh token (không cần thu hồi nữa).
    logout: ({ revoke = true } = {}) => {
        const { refreshToken } = get();
        // Gửi yêu cầu thu hồi trước rồi mới xóa phiên; không chờ kết quả, lỗi bị bỏ qua.
        if (revoke && refreshToken) void revokeSession(refreshToken);
        clearSession();
        set({ token: null, refreshToken: null, refreshExpiresAt: null, user: null, remember: false });
        // Xóa cache React Query để user đăng nhập sau không thấy dữ liệu của user trước.
        queryClient.clear();
    },
}));

/**
 * Tab khác (cùng localStorage) có thể đã xoay vòng refresh token: refresh token trong bộ nhớ tab này
 * lúc đó đã bị thu hồi. Nhận lại phiên mới từ storage thay vì gọi BE (sẽ bị 1030 và đăng xuất oan).
 */
function adoptStoredSession(get, set, staleRefreshToken) {
    const stored = loadSession();
    if (
        stored.refreshToken &&
        stored.refreshToken !== staleRefreshToken &&
        stored.token &&
        !isTokenExpired(stored.token)
    ) {
        set(stored);
        return true;
    }
    return false;
}

async function doRefresh(get, set) {
    const { refreshToken, refreshExpiresAt } = get();
    if (!refreshToken) return false;
    if (adoptStoredSession(get, set, refreshToken)) return true;
    if (!canRefresh({ refreshToken, refreshExpiresAt })) {
        get().expireSession();
        return false;
    }

    try {
        const fresh = await refreshSessionApi(refreshToken);
        // Đã đăng xuất / đổi tài khoản trong lúc chờ thì bỏ kết quả.
        if (get().refreshToken !== refreshToken) return false;
        get().setAuth({ ...fresh, user: { ...get().user, ...fresh.user } });
        return true;
    } catch (error) {
        if (!error.rejected) return false;
        if (adoptStoredSession(get, set, refreshToken)) return true;
        if (get().refreshToken === refreshToken) get().expireSession();
        return false;
    }
}

// selector tiện dùng: const isAuthenticated = useAuthStore(selectIsAuthenticated)
export const selectIsAuthenticated = (s) => Boolean(s.token);
