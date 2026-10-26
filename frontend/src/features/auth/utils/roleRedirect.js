// Điều hướng theo vai trò (role của BE: "USER" | "ADMIN").

export const ADMIN_HOME_PATH = "/admin";

export const isAdmin = (user) => user?.role === "ADMIN";

/**
 * Trang đích sau khi đăng nhập thành công.
 * - ADMIN luôn vào trang quản trị, trừ khi đang muốn vào một trang con của /admin (vd bị đá ra
 *   từ /admin/categories lúc hết phiên) thì quay lại đúng trang đó.
 * - Người dùng thường quay lại trang họ muốn vào trước khi bị đá sang /login, mặc định là "/".
 * `from` là pathname đã lưu trong location.state.from (có thể undefined).
 */
export function resolvePostLoginPath(user, from) {
  if (isAdmin(user)) {
    return from && (from === ADMIN_HOME_PATH || from.startsWith(`${ADMIN_HOME_PATH}/`))
      ? from
      : ADMIN_HOME_PATH;
  }
  return from || "/";
}
