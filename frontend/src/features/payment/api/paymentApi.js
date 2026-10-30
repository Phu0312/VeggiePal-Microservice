import apiClient from "@/shared/api/apiClient";

/**
 * Bảng dịch lỗi dành riêng cho payment-service (mã 7000–7009 của payment-service,
 * không dùng chung với ai-service hay các service khác).
 */
const PAYMENT_ERROR_MESSAGES = {
  1008: "Phiên đăng nhập hết hạn",
  1018: "Dữ liệu chưa hợp lệ, vui lòng kiểm tra lại",
  7000: "Vui lòng chọn gói thành viên",
  7001: "Gói không tồn tại",
  7002: "Gói này không thể mua",
  7003: "Không tìm thấy đơn hàng",
  7004: "Cổng thanh toán đang bận, thử lại sau",
  7005: "Chữ ký thanh toán không hợp lệ",
  7006: "Số tiền thanh toán không khớp với đơn hàng",
  7007: "Thanh toán không thành công",
  7008: "Đơn hàng này không thể huỷ",
  7009: "Chưa huỷ được đơn, vui lòng thử lại",
};

function toPaymentMessage(res, fallbackMessage) {
  const code = res.data?.code;
  if (code && PAYMENT_ERROR_MESSAGES[code]) {
    return PAYMENT_ERROR_MESSAGES[code];
  }
  if (res.status === 401) {
    return PAYMENT_ERROR_MESSAGES[1008];
  }
  if (res.status === 503) {
    return PAYMENT_ERROR_MESSAGES[7004];
  }
  return res.data?.message || fallbackMessage;
}

function networkError(error, timeoutMessage) {
  return new Error(
    error?.code === "ECONNABORTED"
      ? timeoutMessage
      : "Không kết nối được máy chủ thanh toán, vui lòng thử lại",
    { cause: error },
  );
}

function unwrap(res, fallbackMessage) {
  if (res.status >= 400) {
    const error = new Error(toPaymentMessage(res, fallbackMessage));
    error.status = res.status;
    error.code = res.data?.code;
    throw error;
  }
  return res.data?.result;
}

/**
 * GET /payments/plans (Công khai)
 * Danh sách các gói thành viên hiện có:
 * [{ id, code, price, durationDays, chatPerDay, mealPlansPerMonth, videosPerMonth }]
 */
export async function getPlans() {
  let res;
  try {
    res = await apiClient.get("/payments/plans");
  } catch (error) {
    throw networkError(error, "Tải danh sách gói thành viên quá thời gian chờ");
  }
  return unwrap(res, "Không lấy được danh sách gói thành viên") ?? [];
}

/**
 * POST /payments/checkout (Yêu cầu đăng nhập)
 * Body: { planCode: "PLUS" | "PRO" }
 * Trả về: { id, orderCode, planCode, amount, status, checkoutUrl, createdAt, paidAt }
 */
export async function checkout(planCode) {
  let res;
  try {
    res = await apiClient.post("/payments/checkout", { planCode });
  } catch (error) {
    throw networkError(error, "Yêu cầu thanh toán quá thời gian chờ");
  }
  return unwrap(res, "Tạo yêu cầu thanh toán thất bại");
}

/**
 * GET /payments/orders/{id} (Yêu cầu đăng nhập)
 * Lấy chi tiết đơn hàng theo internal ID (không phải orderCode payOS)
 */
export async function getOrder(id) {
  let res;
  try {
    res = await apiClient.get(`/payments/orders/${id}`);
  } catch (error) {
    throw networkError(error, "Lấy thông tin đơn hàng quá thời gian chờ");
  }
  return unwrap(res, "Không tìm thấy đơn hàng");
}

/**
 * POST /payments/orders/{id}/cancel (Yêu cầu đăng nhập)
 * Huỷ đơn PENDING, trả về đơn với status "CANCELLED".
 */
export async function cancelOrder(id) {
  let res;
  try {
    res = await apiClient.post(`/payments/orders/${id}/cancel`);
  } catch (error) {
    throw networkError(error, "Yêu cầu huỷ đơn quá thời gian chờ");
  }
  return unwrap(res, PAYMENT_ERROR_MESSAGES[7009]);
}

/**
 * GET /payments/history (Yêu cầu đăng nhập)
 * Lịch sử thanh toán của người dùng, mới nhất trước
 */
export async function getHistory() {
  let res;
  try {
    res = await apiClient.get("/payments/history");
  } catch (error) {
    throw networkError(error, "Tải lịch sử thanh toán quá thời gian chờ");
  }
  return unwrap(res, "Không lấy được lịch sử thanh toán") ?? [];
}

/**
 * GET /subscriptions/me (Yêu cầu đăng nhập)
 * Gói thành viên hiện tại:
 * { planCode, startedAt, expiresAt, chatPerDay, mealPlansPerMonth, videosPerMonth }
 */
export async function getMySubscription() {
  let res;
  try {
    res = await apiClient.get("/subscriptions/me");
  } catch (error) {
    throw networkError(error, "Tải thông tin gói thành viên quá thời gian chờ");
  }
  return unwrap(res, "Không lấy được thông tin gói thành viên");
}
