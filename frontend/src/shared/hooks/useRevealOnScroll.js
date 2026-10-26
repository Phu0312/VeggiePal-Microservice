import { useEffect, useRef, useState } from "react";

/**
 * Trả về [ref, visible]: gắn `ref` vào phần tử cần hiện dần; `visible` chuyển
 * sang true (và giữ nguyên) khi phần tử lần đầu cuộn vào màn hình.
 * Dùng chung cho Reveal và AppFooter.
 */
export function useRevealOnScroll({ threshold = 0.15 } = {}) {
  const ref = useRef(null);
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    const node = ref.current;
    if (!node) return;

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setVisible(true);
          observer.unobserve(node);
        }
      },
      { threshold, rootMargin: "0px 0px -60px 0px" }
    );

    observer.observe(node);
    return () => observer.disconnect();
  }, [threshold]);

  return [ref, visible];
}
