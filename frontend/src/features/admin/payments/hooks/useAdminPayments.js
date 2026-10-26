import { keepPreviousData, useQuery } from "@tanstack/react-query";

import {
  getAdminOrder,
  getAdminOrders,
  getPaymentRevenue,
  getPaymentStatistics,
  getPaymentSummary,
} from "@/features/admin/payments/api/adminPaymentApi";
import { adminPaymentKeys } from "@/features/admin/payments/queryKeys";

const STALE_MS = 30 * 1000;

// filters: { from, to, planCode }. `enabled = false` để tạm dừng khi bộ lọc chưa hợp lệ (from > to).
export function usePaymentSummary(filters, { enabled = true } = {}) {
  return useQuery({
    queryKey: adminPaymentKeys.summary(filters),
    queryFn: () => getPaymentSummary(filters),
    staleTime: STALE_MS,
    placeholderData: keepPreviousData,
    enabled,
  });
}

export function usePaymentStatistics(filters, { enabled = true } = {}) {
  return useQuery({
    queryKey: adminPaymentKeys.statistics(filters),
    queryFn: () => getPaymentStatistics(filters),
    staleTime: STALE_MS,
    placeholderData: keepPreviousData,
    enabled,
  });
}

export function usePaymentRevenue(filters, groupBy, { enabled = true } = {}) {
  return useQuery({
    queryKey: adminPaymentKeys.revenue(filters, groupBy),
    queryFn: () => getPaymentRevenue({ ...filters, groupBy }),
    staleTime: STALE_MS,
    placeholderData: keepPreviousData,
    enabled,
  });
}

// params: { status, planCode, from, to, page, size }
export function useAdminOrders(params, { enabled = true } = {}) {
  return useQuery({
    queryKey: adminPaymentKeys.orders(params),
    queryFn: () => getAdminOrders(params),
    staleTime: STALE_MS,
    placeholderData: keepPreviousData,
    enabled,
  });
}

export function useAdminOrder(id) {
  return useQuery({
    queryKey: adminPaymentKeys.order(id),
    queryFn: () => getAdminOrder(id),
    enabled: id != null,
  });
}
