import { useQuery } from "@tanstack/react-query";

import { useAuthStore, selectIsAuthenticated } from "@/features/auth/store/authStore";
import { getMySubscription } from "@/features/payment/api/paymentApi";
import { paymentKeys } from "@/features/payment/queryKeys";

/**
 * Lấy gói thành viên hiện tại của người dùng (chỉ gọi khi đã đăng nhập).
 */
export function useMySubscription() {
  const isAuthenticated = useAuthStore(selectIsAuthenticated);

  const query = useQuery({
    queryKey: paymentKeys.subscription(),
    queryFn: getMySubscription,
    enabled: Boolean(isAuthenticated),
    staleTime: 60 * 1000,
  });

  return {
    ...query,
    subscription: query.data ?? null,
    loading: query.isLoading,
  };
}
