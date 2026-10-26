import { QueryClient } from "@tanstack/react-query";

// Tách riêng để authStore có thể xóa cache khi đăng xuất (tránh user sau thấy
// dữ liệu cache của user trước).
//
// - retry: false — lỗi 4xx/5xx được ném từ các hàm *Api.js (apiClient tắt
//   validateStatus) là lỗi nghiệp vụ, thử lại không giúp ích mà chỉ làm chậm
//   việc hiện thông báo lỗi.
// - refetchOnWindowFocus: false — không tự gọi lại API khi quay lại tab, giữ
//   hành vi giống code cũ (tự gọi tay khi cần).
export const queryClient = new QueryClient({
  defaultOptions: {
    queries: { retry: false, refetchOnWindowFocus: false },
  },
});
