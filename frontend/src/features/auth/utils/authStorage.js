// Import tương đối (không dùng "@/") để file này chạy được cả trong `npm test` của Node.
import { isTokenExpired } from "../../../lib/jwt.js";

const TOKEN_KEY = "token";
const USER_KEY = "user";
const REFRESH_TOKEN_KEY = "refreshToken";
// Thời điểm (ms) refresh token hết hạn, tính từ `refreshExpiresIn` lúc nhận token.
const REFRESH_EXPIRES_AT_KEY = "refreshExpiresAt";
const KEYS = [TOKEN_KEY, USER_KEY, REFRESH_TOKEN_KEY, REFRESH_EXPIRES_AT_KEY];

const EMPTY_SESSION = {
  token: null,
  refreshToken: null,
  refreshExpiresAt: null,
  user: null,
  remember: false,
};

// "Ghi nhớ đăng nhập" = lưu phiên ở localStorage (còn sau khi đóng trình duyệt).
// Không ghi nhớ = sessionStorage (mất khi đóng tab/trình duyệt, F5 vẫn còn).
// Tham số storage truyền vào được để test; mặc định là storage của trình duyệt.

function parseUser(raw) {
  try {
    return JSON.parse(raw ?? "null");
  } catch {
    return null;
  }
}

function parseTime(raw) {
  const value = Number(raw);
  return raw && Number.isFinite(value) ? value : null;
}

/** true nếu còn đổi được access token mới: có refresh token và nó chưa hết hạn (không rõ hạn thì để BE quyết định). */
export function canRefresh({ refreshToken, refreshExpiresAt }, now = Date.now()) {
  return Boolean(refreshToken) && (refreshExpiresAt == null || refreshExpiresAt > now);
}

export function clearSession(local = localStorage, session = sessionStorage) {
  for (const storage of [local, session]) {
    for (const key of KEYS) storage.removeItem(key);
  }
}

/**
 * Đọc phiên đã lưu. Access token hết hạn mà refresh token còn hạn thì vẫn giữ phiên
 * (app sẽ đổi token mới ngay); cả hai đều hết hạn thì xóa và coi như chưa đăng nhập.
 */
export function loadSession(local = localStorage, session = sessionStorage, now = Date.now()) {
  for (const [storage, remember] of [[local, true], [session, false]]) {
    const token = storage.getItem(TOKEN_KEY);
    if (!token) continue;

    const stored = {
      token,
      refreshToken: storage.getItem(REFRESH_TOKEN_KEY) || null,
      refreshExpiresAt: parseTime(storage.getItem(REFRESH_EXPIRES_AT_KEY)),
      user: parseUser(storage.getItem(USER_KEY)),
      remember,
    };
    if (isTokenExpired(token, now) && !canRefresh(stored, now)) {
      clearSession(local, session);
      break;
    }
    return stored;
  }
  return { ...EMPTY_SESSION };
}

/** Lưu phiên vào đúng nơi theo `remember`, đồng thời xóa bản ở nơi còn lại. */
export function saveSession(
  { token, refreshToken, refreshExpiresAt, user, remember },
  local = localStorage,
  session = sessionStorage
) {
  const [target, other] = remember ? [local, session] : [session, local];
  for (const key of KEYS) other.removeItem(key);
  target.setItem(TOKEN_KEY, token);
  target.setItem(USER_KEY, JSON.stringify(user));
  if (refreshToken) target.setItem(REFRESH_TOKEN_KEY, refreshToken);
  else target.removeItem(REFRESH_TOKEN_KEY);
  if (refreshExpiresAt != null) target.setItem(REFRESH_EXPIRES_AT_KEY, String(refreshExpiresAt));
  else target.removeItem(REFRESH_EXPIRES_AT_KEY);
}
