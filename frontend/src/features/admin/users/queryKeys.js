// Khóa cache trang quản lý người dùng (identity-service /admin/users).
export const adminUserKeys = {
  all: ["admin", "users"],
  list: (params) => ["admin", "users", "list", params],
};
