import { useMutation } from "@tanstack/react-query";

import { checkout } from "@/features/payment/api/paymentApi";

/**
 * Mutation tạo đơn thanh toán payOS cho gói PLUS hoặc PRO.
 */
export function useCheckout() {
  return useMutation({
    mutationFn: (planCode) => checkout(planCode),
  });
}
