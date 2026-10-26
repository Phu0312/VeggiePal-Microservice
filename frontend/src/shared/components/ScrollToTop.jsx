import { useLayoutEffect } from "react";
import { useLocation, useNavigationType } from "react-router-dom";

// Đổi trang (bấm link/navigate) thì đưa thanh cuộn về đầu trang, nếu không trang mới sẽ giữ
// vị trí cuộn của trang cũ. Chỉ theo dõi pathname để đổi bộ lọc/tìm kiếm trên URL không bị nhảy.
// Bỏ qua Back/Forward (POP) để trình duyệt tự khôi phục vị trí cũ, và bỏ qua link có #anchor.
export default function ScrollToTop() {
  const { pathname, hash } = useLocation();
  const navigationType = useNavigationType();

  useLayoutEffect(() => {
    if (navigationType === "POP" || hash) return;
    window.scrollTo({ top: 0, left: 0, behavior: "instant" });
    // hash chỉ để đọc, không cần chạy lại khi nó đổi
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [pathname]);

  return null;
}
