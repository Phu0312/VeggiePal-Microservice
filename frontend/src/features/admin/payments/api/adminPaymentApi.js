import apiClient from "@/shared/api/apiClient";

/**
 * Admin payment APIs (payment-service qua api-gateway). Chỉ ADMIN.
 *   GET /admin/payments/summary?from&to&planCode        thẻ tổng quan
 *   GET /admin/payments/statistics?from&to&planCode     phân bố trạng thái / gói
 *   GET /admin/payments/revenue?from&to&planCode&groupBy=DAY|MONTH   doanh thu theo kỳ
 *   GET /admin/payments/orders?status&planCode&from&to&page&size     danh sách đơn có phân trang
 *   GET /admin/payments/orders/{id}                      chi tiết đơn
 * from / to: Instant ISO-8601 (Date.toISOString()).
 *
 * Summary: { totalRevenue, totalTransactions, paidTransactions, pendingTransactions,
 *   cancelledTransactions, failedTransactions, averagePaidAmount, statusDistribution }
 * Statistics: { statusDistribution: [{ key, count, amount }], planDistribution: [...], transactionTrend: [Point] }
 * Revenue: { totalRevenue, paidTransactions, groupBy, points: [{ period, transactionCount, revenue }] }
 * OrderPage: { items: [Order], page, size, totalElements, totalPages }
 */

const EMPTY_ORDER_PAGE = { items: [], page: 0, size: 20, totalElements: 0, totalPages: 0 };

function toMessage(res, fallbackMessage) {
  if (res.status === 401) return "Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại";
  if (res.status === 403) return "Bạn không có quyền xem dữ liệu thanh toán";
  if (res.status === 400) return "Bộ lọc không hợp lệ, vui lòng kiểm tra lại";
  if (res.status === 404) return "Không tìm thấy đơn hàng";
  return res.data?.message || fallbackMessage;
}

function unwrap(res, fallbackMessage) {
  if (res.status >= 400) throw new Error(toMessage(res, fallbackMessage));
  return res.data?.result;
}

const rangeParams = ({ from, to, planCode } = {}) => ({
  from: from || undefined,
  to: to || undefined,
  planCode: planCode || undefined,
});

export async function getPaymentSummary(filters) {
  const res = await apiClient.get("/admin/payments/summary", { params: rangeParams(filters) });
  return unwrap(res, "Không lấy được số liệu tổng quan");
}

export async function getPaymentStatistics(filters) {
  const res = await apiClient.get("/admin/payments/statistics", { params: rangeParams(filters) });
  return unwrap(res, "Không lấy được thống kê thanh toán");
}

export async function getPaymentRevenue({ groupBy = "DAY", ...filters } = {}) {
  const res = await apiClient.get("/admin/payments/revenue", {
    params: { ...rangeParams(filters), groupBy },
  });
  return unwrap(res, "Không lấy được doanh thu");
}

export async function getAdminOrders({ status, page = 0, size = 20, ...filters } = {}) {
  const res = await apiClient.get("/admin/payments/orders", {
    params: { ...rangeParams(filters), status: status || undefined, page, size },
  });
  return unwrap(res, "Không lấy được danh sách đơn hàng") ?? EMPTY_ORDER_PAGE;
}

export async function getAdminOrder(id) {
  const res = await apiClient.get(`/admin/payments/orders/${id}`);
  return unwrap(res, "Không lấy được chi tiết đơn hàng");
}
