// identity-service trả message tiếng Anh theo ErrorCode; đổi sang tiếng Việt theo `code`.
const VI_MESSAGES = {
  1001: "Dữ liệu chưa hợp lệ, vui lòng kiểm tra lại",
  1002: "Email này đã được đăng ký, vui lòng dùng email khác hoặc đăng nhập",
  1003: "Mật khẩu phải có ít nhất 6 ký tự",
  1004: "Email không hợp lệ",
  1005: "Vui lòng nhập email",
  1006: "Vui lòng nhập họ và tên",
  1010: "Vui lòng nhập mật khẩu",
  1018: "Dữ liệu chưa hợp lệ, vui lòng kiểm tra lại",
  1019: "Không xác thực được tài khoản Google. Vui lòng thử lại.",
  1021: "Tài khoản đã bị khóa hoặc chưa được kích hoạt",
  1024: "Vui lòng nhập mã OTP",
  1025: "Mã OTP không đúng hoặc đã hết hạn",
  1026: "Bạn đã nhập sai quá nhiều lần, vui lòng yêu cầu mã mới",
  1027: "Phiên đặt lại mật khẩu đã hết hạn, vui lòng làm lại từ đầu",
  1028: "Email này đã được xác minh",
  1033: "Bạn đã yêu cầu gửi mã quá nhiều lần, vui lòng thử lại sau",
  1034: "Máy chủ chưa gửi được email, vui lòng thử lại sau",
};

// BE dùng chung mã 1008 (UNAUTHENTICATED) cho cả "không có email" lẫn "sai mật khẩu" nên chỉ có một câu chung.
export const LOGIN_FAILED_MESSAGE = "Email hoặc mật khẩu không đúng";
export const NETWORK_ERROR_MESSAGE = "Không kết nối được máy chủ, vui lòng thử lại";
export const SESSION_EXPIRED_MESSAGE = "Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại.";
const SERVER_ERROR_MESSAGE = "Máy chủ đang gặp sự cố, vui lòng thử lại sau";

/**
 * Thông báo tiếng Việt cho một phản hồi lỗi (status >= 400) của /auth/*.
 * `overrides` là bảng riêng của từng hàm (vd login dịch 1008 thành "sai email hoặc mật khẩu").
 * Mã lạ thì dùng `fallbackMessage`, không dùng message của BE vì nó là tiếng Anh.
 */
export function toAuthMessage(res, fallbackMessage, overrides = {}) {
  const code = res?.data?.code;
  const byCode = overrides[code] ?? VI_MESSAGES[code];
  if (byCode) return byCode;
  if (res?.status >= 500) return SERVER_ERROR_MESSAGE;
  return fallbackMessage;
}

/**
 * true nếu BE từ chối hẳn refresh token: 401 / 1030 (sai, hết hạn hoặc đã thu hồi, kể cả token cũ
 * đã bị xoay vòng), 1029 (thiếu token), 1021 (tài khoản bị khóa). Lúc đó phải đăng xuất.
 * Lỗi 5xx không tính: máy chủ trục trặc tạm thời thì giữ phiên để thử lại.
 */
export function isRefreshRejected(res) {
  const code = res?.data?.code;
  return res?.status === 401 || code === 1029 || code === 1030 || code === 1021;
}
