import axios from "axios";

import { useAuthStore } from "@/features/auth/store/authStore";
import { isTokenExpired } from "@/lib/jwt";

const apiClient = axios.create({
    baseURL: import.meta.env.VITE_VEGGIEPAL_API_BASE_URL,
    // axios mặc định throw khi gặp 4xx/5xx. Tắt đi để tự xử lý status trong code,
    // giống hành vi của fetch (chỉ throw khi lỗi mạng).
    validateStatus: () => true,
});

// Làm mới access token trước khi hết hạn chừng này để request không chết giữa đường.
const REFRESH_LEEWAY_MS = 30_000;

// Các endpoint /auth/* tự xử lý phiên của mình (đăng nhập, làm mới, đăng xuất...), không đi qua cơ chế làm mới.
function isAuthPath(url = "") {
    return /^\/?auth\//.test(url);
}

// Lấy token từ store (không đọc thẳng localStorage, vì token có thể nằm ở
// sessionStorage khi người dùng không tick "Ghi nhớ đăng nhập").
function authHeader() {
    const { token } = useAuthStore.getState();
    return token ? { Authorization: `Bearer ${token}` } : {};
}

// Tự động đính token vào mọi request (thay cho việc truyền authHeader() từng chỗ).
// Token sắp/đã hết hạn thì đổi token mới trước khi gửi (máy ngủ dậy, tab bị treo lâu...).
apiClient.interceptors.request.use(async (config) => {
    const { token, refreshToken, refreshSession } = useAuthStore.getState();
    if (token && refreshToken && !isAuthPath(config.url) && isTokenExpired(token, Date.now() + REFRESH_LEEWAY_MS)) {
        await refreshSession();
    }
    Object.assign(config.headers, authHeader());
    return config;
});

// 401 trên request đã gắn token = access token hết hạn / bị từ chối: đổi token mới rồi gửi lại đúng một lần.
// validateStatus luôn true nên 401 không rơi vào nhánh lỗi, phải kiểm tra `res.status` ở nhánh thành công.
apiClient.interceptors.response.use(async (res) => {
    const config = res.config;
    if (res.status !== 401 || !config || config._retried || isAuthPath(config.url)) return res;

    const sent = config.headers?.Authorization;
    const { token, refreshToken, refreshSession } = useAuthStore.getState();
    if (!sent || !refreshToken) return res;

    // Request khác đã đổi token trong lúc request này chờ phản hồi thì chỉ cần gửi lại, không làm mới nữa.
    if (sent === `Bearer ${token}`) {
        const ok = await refreshSession();
        if (!ok) return res;
    }

    config._retried = true;
    return apiClient.request(config);
});

export default apiClient;
