import { useQuery } from "@tanstack/react-query";

import { useAuthStore, selectIsAuthenticated } from "@/features/auth/store/authStore";
import { getMyQuotas } from "@/features/payment/api/quotaApi";
import { paymentKeys } from "@/features/payment/queryKeys";

/** Hạn mức AI của người dùng (chỉ gọi khi đã đăng nhập). Lượt dùng đổi liên tục nên luôn lấy mới khi mở trang. */
export function useMyQuotas() {
  const isAuthenticated = useAuthStore(selectIsAuthenticated);

  const query = useQuery({
    queryKey: paymentKeys.quotas(),
    queryFn: getMyQuotas,
    enabled: Boolean(isAuthenticated),
  });

  return {
    quotas: query.data ?? null,
    loading: query.isLoading,
    error: query.error ? query.error.message : "",
  };
}
