import {
  LOGIN_FAILED_MESSAGE,
  NETWORK_ERROR_MESSAGE,
  toAuthMessage,
} from "@/features/auth/utils/authErrors";
import apiClient from "@/shared/api/apiClient";

// LoginResponse của identity-service (dùng chung cho /auth/login và /auth/google) -> { token, user }.
function toSession(result) {
  return {
    token: result.accessToken,
    user: {
      id: result.userId,
      email: result.email,
      fullName: result.fullName,
      role: result.role,
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

/**
 * Đăng nhập bằng email + mật khẩu (khớp /auth/login của identity-service).
 * Trả về: { token, user: { id, email, fullName, role } }
 * Ném lỗi (throw) với thông báo tiếng Việt (dịch theo `code` của BE) nếu thất bại.
 */
export async function login({ email, password }) {
  const res = await post("/auth/login", { email, password });

  if (res.status >= 400) {
    // 1008 = UNAUTHENTICATED: BE không phân biệt "không có email" và "sai mật khẩu".
    throw new Error(toAuthMessage(res, "Đăng nhập thất bại", { 1008: LOGIN_FAILED_MESSAGE }));
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
    throw new Error(toAuthMessage(res, "Đăng nhập bằng Google thất bại"));
  }

  return toSession(res.data.result);
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
    throw new Error(toAuthMessage(res, "Đăng ký thất bại"));
  }

  return res.data.result;
}
