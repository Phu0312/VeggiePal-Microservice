import { keepPreviousData, useQuery } from "@tanstack/react-query";

import {
  getAiLimits,
  getAiModels,
  getUsageSummary,
  searchUsageLogs,
} from "@/features/admin/monitoring/api/monitoringApi";
import { monitoringKeys } from "@/features/admin/monitoring/queryKeys";

const STALE_MS = 30 * 1000;

/** Tổng hợp usage trong `days` ngày gần nhất. */
export function useUsageSummary(days) {
  return useQuery({
    queryKey: monitoringKeys.summary(days),
    queryFn: () => getUsageSummary(days),
    staleTime: STALE_MS,
  });
}

/**
 * Nhật ký usage có lọc + phân trang. params: { feature, status, userId, from, to, page, size }.
 * `enabled = false` để tạm dừng khi bộ lọc chưa hợp lệ (vd. ngày bắt đầu sau ngày kết thúc).
 */
export function useUsageLogs(params, { enabled = true } = {}) {
  return useQuery({
    queryKey: monitoringKeys.logs(params),
    queryFn: () => searchUsageLogs(params),
    placeholderData: keepPreviousData,
    staleTime: STALE_MS,
    enabled,
  });
}

/** Model đang cấu hình (chỉ đổi khi BE khởi động lại nên cache lâu). */
export function useAiModels() {
  return useQuery({
    queryKey: monitoringKeys.models,
    queryFn: getAiModels,
    staleTime: 10 * 60 * 1000,
  });
}

/** Quota / giới hạn token đang áp dụng. */
export function useAiLimits() {
  return useQuery({
    queryKey: monitoringKeys.limits,
    queryFn: getAiLimits,
    staleTime: 10 * 60 * 1000,
  });
}
