import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import {
  dismissModerationCase,
  getPendingModerationCases,
  reviewModerationCase,
} from "@/features/admin/moderation/api/moderationApi";
import { moderationKeys } from "@/features/admin/moderation/queryKeys";

const STALE_MS = 15 * 1000;

/** Lấy danh sách hàng đợi các case kiểm duyệt (REVIEW_REQUIRED, cũ nhất trước). */
export function usePendingModerationCases() {
  return useQuery({
    queryKey: moderationKeys.pending,
    queryFn: getPendingModerationCases,
    staleTime: STALE_MS,
  });
}

/** Mutation duyệt hoặc từ chối case kiểm duyệt. */
export function useReviewModeration() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, decision, reason }) =>
      reviewModerationCase(id, { decision, reason }),
    onSuccess: () => {
      // Invalidate để tự động làm mới danh sách hàng đợi
      queryClient.invalidateQueries({ queryKey: moderationKeys.all });
    },
    onError: (error) => {
      // Khi gặp lỗi 6013 (Case đã được xử lý): tự động tải lại hàng đợi kiểm duyệt
      if (error?.code === 6013) {
        queryClient.invalidateQueries({ queryKey: moderationKeys.all });
      }
    },
  });
}

/**
 * Mutation bỏ qua case kiểm duyệt: case rời khỏi hàng đợi nhưng nội dung gốc không đổi trạng thái.
 * Làm mới hàng đợi (và badge ở sidebar, dùng chung moderationKeys.pending) sau khi thành công.
 */
export function useDismissModeration() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, reason }) => dismissModerationCase(id, { reason }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: moderationKeys.all });
    },
    onError: (error) => {
      // 6013: case đã được xử lý -> tải lại hàng đợi để case biến mất khỏi danh sách
      if (error?.code === 6013) {
        queryClient.invalidateQueries({ queryKey: moderationKeys.all });
      }
    },
  });
}
