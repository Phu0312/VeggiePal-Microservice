// Ánh xạ mã lỗi từ blog-service sang tiếng Việt cho feature video.
const VI_VIDEO_MESSAGES = {
  1002: "Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại",
  1008: "Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại",
  1009: "Bạn không có quyền thực hiện thao tác này",
  1017: "Không tải được video lên, vui lòng thử lại sau",
  1018: "Dữ liệu không hợp lệ",
  3003: "Danh mục không tồn tại",
  3007: "Danh mục này đã ngừng hoạt động, vui lòng chọn danh mục khác",
  3008: "Vui lòng chọn danh mục",
  3050: "Hệ thống kiểm duyệt tạm thời không khả dụng, vui lòng thử lại sau",
  3051: "Kết quả kiểm duyệt không hợp lệ",
  3052: "Dữ liệu kiểm duyệt không khớp tác giả",
  3060: "Video không tồn tại hoặc chưa được đăng",
  3061: "Vui lòng nhập tiêu đề video",
  3062: "Tiêu đề video tối đa 150 ký tự",
  3063: "Mô tả video tối đa 5000 ký tự",
  3064: "Chỉ được chọn đúng một nguồn video: tệp video hoặc liên kết YouTube",
  3065: "Video phải là tệp định dạng .mp4",
  3066: "Tệp video vượt quá dung lượng cho phép (tối đa 30MB)",
  3067: "Liên kết YouTube không hợp lệ",
  3068: "Video đang ở trạng thái không cho phép thao tác này",
};

/** Trả `res.data.result`, hoặc ném Error với thông báo tiếng Việt nếu status >= 400. */
export function unwrapVideoResponse(res, fallbackMessage) {
  if (res.status >= 400) {
    throw new Error(VI_VIDEO_MESSAGES[res.data?.code] ?? res.data?.message ?? fallbackMessage);
  }
  return res.data?.result;
}
