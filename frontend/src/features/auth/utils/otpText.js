// Câu báo sau khi yêu cầu mã OTP. BE trả 200 cả khi không gửi mail (email chưa đăng ký, vượt giới hạn)
// nên chỉ được nói "nếu ... sẽ được gửi", không khẳng định đã gửi.
export function otpSentNotice(expiresInSeconds, condition = "Nếu yêu cầu hợp lệ") {
  const minutes = Math.round(Number(expiresInSeconds) / 60);
  const validity = minutes > 0 ? ` Mã có hiệu lực trong ${minutes} phút.` : "";
  return `${condition}, mã gồm 6 chữ số sẽ được gửi tới hộp thư (kiểm tra cả mục Spam).${validity}`;
}
