import { useQuery } from "@tanstack/react-query";

import { getPlans } from "@/features/payment/api/paymentApi";
import { paymentKeys } from "@/features/payment/queryKeys";

/**
 * Lấy danh sách các gói thành viên công khai từ BE.
 */
export function usePlans() {
  const query = useQuery({
    queryKey: paymentKeys.plans(),
    queryFn: getPlans,
    staleTime: 5 * 60 * 1000,
  });

  return {
    ...query,
    plans: query.data ?? [],
    loading: query.isLoading,
  };
}
