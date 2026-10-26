// Đọc thời điểm hết hạn (claim "exp") từ JWT ở phía client. Chỉ để UI biết khi nào
// nên tự đăng xuất — KHÔNG thay cho việc server kiểm tra token.

/** Trả về thời điểm hết hạn (ms, kiểu Date.now()) hoặc null nếu không đọc được. */
export function getTokenExpiryMs(token) {
  try {
    const payload = token.split(".")[1];
    if (!payload) return null;
    const json = atob(payload.replace(/-/g, "+").replace(/_/g, "/"));
    const { exp } = JSON.parse(json);
    return typeof exp === "number" ? exp * 1000 : null;
  } catch {
    return null;
  }
}

/** true nếu token chắc chắn đã hết hạn. Không đọc được hạn thì coi như chưa hết (để server quyết định). */
export function isTokenExpired(token, now = Date.now()) {
  const expiry = getTokenExpiryMs(token);
  return expiry !== null && expiry <= now;
}
