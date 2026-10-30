import apiClient from "@/shared/api/apiClient";

/**
 * GET /ai/quotas/me (ai-service, cần đăng nhập): lượt đã dùng / còn lại của gói hiện tại.
 * -> { planCode, expiresAt, mealPlan, chat, video }, mỗi mục
 *    { feature, period: "DAILY" | "MONTHLY", limit, used, remaining, periodStart, resetsAt }.
 */
export async function getMyQuotas() {
  let res;
  try {
    res = await apiClient.get("/ai/quotas/me");
  } catch (error) {
    throw new Error("Không kết nối được máy chủ, vui lòng thử lại", { cause: error });
  }
  if (res.status >= 400) {
    throw new Error(
      res.status === 401 || res.data?.code === 6001
        ? "Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại"
        : "Không tải được hạn mức sử dụng"
    );
  }
  return res.data?.result;
}
