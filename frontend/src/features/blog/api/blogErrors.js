// BE trả message tiếng Anh theo ErrorCode. Với các lỗi người dùng có thể gặp khi thao tác
// (vote, bình luận...) ta đổi sang tiếng Việt theo `code`; code lạ thì dùng message của BE.
const VI_MESSAGES = {
  1002: "Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại",
  1008: "Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại",
  1009: "Bạn không có quyền thực hiện thao tác này",
  1017: "Không tải được tệp lên, vui lòng thử lại sau",
  1018: "Dữ liệu không hợp lệ",
  3001: "Tên danh mục không được để trống và tối đa 100 ký tự",
  3002: "Vui lòng chọn loại danh mục",
  3003: "Danh mục không tồn tại",
  3004: "Đã có danh mục cùng tên ở cùng cấp",
  3005: "Không xóa được: danh mục đang có bài viết hoặc danh mục con. Hãy tắt hiển thị thay vì xóa",
  3006: "Danh mục chỉ có tối đa 2 cấp",
  3007: "Danh mục này đã ngừng hoạt động, vui lòng chọn danh mục khác",
  3008: "Vui lòng chọn danh mục",
  3010: "Vui lòng nhập tiêu đề bài viết",
  3011: "Tiêu đề tối đa 150 ký tự",
  3012: "Vui lòng nhập nội dung bài viết",
  3013: "Nội dung bài viết tối thiểu 20 ký tự",
  3014: "Bài viết không tồn tại hoặc chưa được đăng",
  3015: "Bài viết đang ở trạng thái không cho phép thao tác này",
  3020: "Vui lòng chọn ảnh bìa",
  3021: "Ảnh bìa phải là JPEG, PNG hoặc WEBP",
  3022: "Ảnh bìa không được vượt quá 5MB",
  3030: "Vui lòng nhập nội dung bình luận",
  3031: "Bình luận tối đa 500 từ",
  3032: "Bình luận không tồn tại hoặc đã bị xóa",
  3033: "Chỉ có thể phản hồi bình luận gốc, không phản hồi lồng nhau",
  3034: "Bình luận gốc không thuộc bài viết này",
  3035: "Bài viết này không còn tồn tại hoặc đã bị gỡ",
  3036: "Loại nội dung này chưa được hỗ trợ",
  3037: "Bình luận quá dài (tối đa 5000 ký tự)",
  3040: "Giá trị bình chọn không hợp lệ",
  3041: "Bạn không thể bình chọn bài viết của chính mình",
  3050: "Hệ thống kiểm duyệt tạm thời không khả dụng, vui lòng thử lại sau",
  3051: "Kết quả kiểm duyệt không hợp lệ, vui lòng thử lại sau",
  3052: "Dữ liệu kiểm duyệt không khớp tác giả",
};

/** Trả `res.data.result`, hoặc ném Error với thông báo tiếng Việt nếu status >= 400. */
export function unwrapBlogResponse(res, fallbackMessage) {
  if (res.status >= 400) {
    throw new Error(VI_MESSAGES[res.data?.code] ?? res.data?.message ?? fallbackMessage);
  }
  return res.data?.result;
}
