// Khung bọc nội dung. Trước đây hiện dần khi cuộn tới; nay hiện ngay, chỉ giữ lại div để bố cục không đổi.
export default function Reveal({ children, className }) {
  return <div className={className}>{children}</div>;
}
