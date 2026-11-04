// Khóa cache React Query của khu admin: thanh toán.
export const adminPaymentKeys = {
  all: ["admin-payments"],
  summary: (filters) => ["admin-payments", "summary", filters],
  statistics: (filters) => ["admin-payments", "statistics", filters],
  orders: (params) => ["admin-payments", "orders", params],
  order: (id) => ["admin-payments", "order", id],
};
