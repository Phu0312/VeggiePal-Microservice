import { create } from "zustand";

/**
 * Trạng thái popup "viết bài / chia sẻ công thức / đăng video" (tạo mới và sửa).
 * `dialog` là null khi đóng, hoặc `{ kind: "blog" | "recipe" | "video", id?, video? }`:
 * không có `id` là tạo mới; `video` (tuỳ chọn) là bản video đã có sẵn từ danh sách "Nội dung của tôi"
 * để sửa được cả bản nháp / bị từ chối mà GET /videos/:id không trả về.
 * Popup được dựng một lần ở `app/ContentFormHost.jsx`, nên mở từ trang nào cũng không đổi URL.
 */
export const useContentFormStore = create((set) => ({
  dialog: null,
  open: (kind, options = {}) => set({ dialog: { kind, ...options } }),
  close: () => set({ dialog: null }),
}));
