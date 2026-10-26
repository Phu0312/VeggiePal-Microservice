import { useState } from "react";

/**
 * <img> tự chuyển sang `fallback` khi `src` rỗng hoặc tải lỗi (ví dụ URL ảnh cũ trên MinIO đã bị gỡ).
 * Nhớ riêng URL đã lỗi, nên khi `src` đổi sang URL mới thì ảnh được thử lại.
 * Các prop còn lại được chuyển thẳng cho <img>.
 */
export default function FallbackImage({ src, fallback = null, alt = "", ...props }) {
  const [failedSrc, setFailedSrc] = useState(null);

  if (!src || failedSrc === src) return fallback;

  return <img src={src} alt={alt} onError={() => setFailedSrc(src)} {...props} />;
}
