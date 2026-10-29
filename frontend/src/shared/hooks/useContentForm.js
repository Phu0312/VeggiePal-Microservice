import { useCallback } from "react";

import { useRequireLogin } from "@/features/auth/hooks/useRequireLogin";
import { useContentFormStore } from "@/shared/store/contentFormStore";

/**
 * Trả `openForm(kind, options)` để mở popup tạo / sửa nội dung (xem contentFormStore).
 * Khách chưa đăng nhập được đưa sang /login và quay lại trang hiện tại sau khi đăng nhập.
 */
export function useContentForm() {
  const open = useContentFormStore((s) => s.open);
  const { requireLogin } = useRequireLogin();

  const openForm = useCallback(
    (kind, options) => {
      if (requireLogin()) open(kind, options);
    },
    [requireLogin, open]
  );

  return { openForm };
}
