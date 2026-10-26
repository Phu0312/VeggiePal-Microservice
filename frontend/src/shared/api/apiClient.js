import axios from "axios";

import { useAuthStore } from "@/features/auth/store/authStore";

const apiClient = axios.create({
    baseURL: import.meta.env.VITE_VEGGIEPAL_API_BASE_URL,
    // axios mặc định throw khi gặp 4xx/5xx. Tắt đi để tự xử lý status trong code,
    // giống hành vi của fetch (chỉ throw khi lỗi mạng).
    validateStatus: () => true,
});

// Lấy token từ store (không đọc thẳng localStorage, vì token có thể nằm ở
// sessionStorage khi người dùng không tick "Ghi nhớ đăng nhập").
function authHeader() {
    const { token } = useAuthStore.getState();
    return token ? { Authorization: `Bearer ${token}` } : {};
}

// Tự động đính token vào mọi request (thay cho việc truyền authHeader() từng chỗ)
apiClient.interceptors.request.use((config) => {
    Object.assign(config.headers, authHeader());
    return config;
});

export default apiClient;
