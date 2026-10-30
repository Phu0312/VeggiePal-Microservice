import {
  LOGIN_FAILED_MESSAGE,
  NETWORK_ERROR_MESSAGE,
  isRefreshRejected,
  toAuthMessage,
} from "@/features/auth/utils/authErrors";
import apiClient from "@/shared/api/apiClient";

/**
 * LoginResponse của identity-service (dùng chung cho /auth/login, /auth/google và /auth/refresh)
 * -> { token, refreshToken, refreshExpiresAt, user }.
 * `refreshExpiresIn` (giây) đổi thành mốc thời gian để biết lúc mở lại app refresh token còn hạn không.
 */
function toSession(result) {
  const expiresIn = Number(result.refreshExpiresIn);
  return {
    token: result.accessToken,
    refreshToken: result.refreshToken ?? null,
    refreshExpiresAt: Number.isFinite(expiresIn) && expiresIn > 0 ? Date.now() + expiresIn * 1000 : null,
    user: {
      id: result.userId,
      email: result.email,
      fullName: result.fullName,
      role: result.role,
      emailVerified: Boolean(result.emailVerified),
    },
  };
}

// validateStatus tắt throw theo status, nên chỉ còn lỗi mạng / máy chủ không phản hồi rơi vào catch.
async function post(path, body) {
  try {
    return await apiClient.post(path, body);
  } catch (error) {
    throw new Error(NETWORK_ERROR_MESSAGE, { cause: error });
  }
}

// Lỗi kèm `code` của BE để màn hình phân biệt được từng trường hợp (vd 1027 phải làm lại từ đầu).
function authError(res, fallbackMessage, overrides) {
  const error = new Error(toAuthMessage(res, fallbackMessage, overrides));
  error.code = res?.data?.code;
  error.status = res?.status;
  return error;
}

/**
 * Đăng nhập bằng email + mật khẩu (khớp /auth/login của identity-service).
 * Trả về: { token, refreshToken, refreshExpiresAt, user: { id, email, fullName, role, emailVerified } }
 * Ném lỗi (throw) với thông báo tiếng Việt (dịch theo `code` của BE) nếu thất bại.
 */
export async function login({ email, password }) {
  const res = await post("/auth/login", { email, password });

  if (res.status >= 400) {
    // 1008 = UNAUTHENTICATED: BE không phân biệt "không có email" và "sai mật khẩu".
    throw authError(res, "Đăng nhập thất bại", { 1008: LOGIN_FAILED_MESSAGE });
  }

  return toSession(res.data.result);
}

/**
 * Đăng nhập bằng Google (khớp POST /auth/google của identity-service).
 * `idToken` là `credential` của Google Identity Services; BE tự kiểm tra token và liên kết
 * tài khoản theo email (chưa có thì tạo mới). Kết quả giống `login`.
 */
export async function loginWithGoogle(idToken) {
  const res = await post("/auth/google", { idToken });

  if (res.status >= 400) {
    // 1019 = GOOGLE_TOKEN_INVALID (token sai/hết hạn, email chưa xác minh, hoặc BE chưa cấu hình GOOGLE_CLIENT_ID).
    throw authError(res, "Đăng nhập bằng Google thất bại");
  }

  return toSession(res.data.result);
}

/**
 * Đổi refresh token lấy access token mới (POST /auth/refresh). BE xoay vòng: refresh token cũ bị thu hồi,
 * dùng lại sẽ nhận 1030. Kết quả giống `login`.
 * Lỗi ném ra có `rejected = true` khi BE từ chối hẳn (phải đăng xuất); mất mạng / 5xx thì `rejected = false`.
 */
export async function refreshSession(refreshToken) {
  let res;
  try {
    res = await apiClient.post("/auth/refresh", { refreshToken });
  } catch (cause) {
    const error = new Error(NETWORK_ERROR_MESSAGE, { cause });
    error.rejected = false;
    throw error;
  }

  if (res.status >= 400) {
    const error = authError(res, "Không làm mới được phiên đăng nhập");
    error.rejected = isRefreshRejected(res);
    throw error;
  }

  return toSession(res.data.result);
}

/** Thu hồi refresh token phía BE (POST /auth/logout). Lỗi bị bỏ qua: phiên trên máy vẫn bị xóa. */
export async function revokeSession(refreshToken) {
  try {
    await apiClient.post("/auth/logout", { refreshToken });
  } catch {
    // Mất mạng thì thôi, refresh token sẽ tự hết hạn phía BE.
  }
}

/**
 * Đăng ký tài khoản mới (khớp /auth/register của identity-service).
 * Backend không trả token khi đăng ký -> đăng ký xong phải đăng nhập lại.
 * Trả về: { id, email, fullName, phone, avatarUrl, role, status, emailVerified }
 */
export async function register({ email, password, fullName, phone }) {
  const res = await post("/auth/register", {
    email,
    password,
    fullName,
    phone,
  });

  if (res.status >= 400) {
    throw authError(res, "Đăng ký thất bại");
  }

  return res.data.result;
}

/**
 * Bước 1 quên mật khẩu: yêu cầu mã OTP 6 số (POST /auth/forgot-password).
 * BE luôn trả 200 kể cả khi email chưa đăng ký hoặc đã vượt giới hạn gửi (3 mã/giờ/email, 10 lần/giờ/IP),
 * nên kết quả thành công KHÔNG có nghĩa là mail đã được gửi.
 * Trả về: { message, expiresInSeconds }
 */
export async function requestPasswordReset(email) {
  const res = await post("/auth/forgot-password", { email });
  if (res.status >= 400) throw authError(res, "Không gửi được yêu cầu, vui lòng thử lại");
  return res.data.result;
}

/** Bước 2: kiểm tra OTP (POST /auth/verify-otp) -> { verified, resetToken, expiresInSeconds }. */
export async function verifyPasswordResetOtp({ email, otp }) {
  const res = await post("/auth/verify-otp", { email, otp });
  if (res.status >= 400) throw authError(res, "Không xác minh được mã OTP");
  return res.data.result;
}

/** Bước 3: đặt mật khẩu mới bằng resetToken nhận ở bước 2 (POST /auth/reset-password). */
export async function resetPassword({ resetToken, newPassword }) {
  const res = await post("/auth/reset-password", { resetToken, newPassword });
  if (res.status >= 400) throw authError(res, "Không đặt lại được mật khẩu");
}

/**
 * Gửi (lại) mã xác minh email (POST /auth/send-verification). Đã đăng nhập thì BE lấy email từ token;
 * truyền `email` khi chưa đăng nhập. Giống quên mật khẩu, 200 không chắc là mail đã được gửi.
 */
export async function sendEmailVerification(email) {
  const res = await post("/auth/send-verification", email ? { email } : {});
  if (res.status >= 400) throw authError(res, "Không gửi được mã xác minh, vui lòng thử lại");
  return res.data.result;
}

/** Xác minh email bằng OTP (POST /auth/verify-email) -> hồ sơ người dùng (emailVerified = true). */
export async function verifyEmail({ email, otp }) {
  const res = await post("/auth/verify-email", { email, otp });
  if (res.status >= 400) throw authError(res, "Không xác minh được email");
  return res.data.result;
}
