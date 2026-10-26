import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import {
  createHealthRecord,
  getHealthRecords,
  getLatestHealthRecord,
  updateHealthRecord,
} from "@/features/profile/api/profileApi";
import { profileKeys } from "@/features/profile/queryKeys";

/** Chỉ số sức khỏe mới nhất (null nếu chưa có bản ghi nào). */
export function useLatestHealthRecord() {
  return useQuery({
    queryKey: profileKeys.latestHealthRecord,
    queryFn: getLatestHealthRecord,
  });
}

/** Lịch sử gần đây — trả về mảng bản ghi (đã bóc từ trang phân trang). */
export function useHealthRecordHistory({ size = 5 } = {}) {
  return useQuery({
    queryKey: profileKeys.healthHistory(size),
    queryFn: () => getHealthRecords({ page: 0, size }),
    select: (page) => page?.items ?? [],
  });
}

/**
 * Ghi nhận chỉ số mới. Xong thì làm mới cả "latest" lẫn "history"
 * (cùng tiền tố khóa); trả Promise nên mutation chờ refetch xong mới kết thúc.
 */
export function useCreateHealthRecord() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: createHealthRecord,
    onSuccess: () =>
      queryClient.invalidateQueries({ queryKey: profileKeys.healthRecords }),
  });
}

/**
 * Sửa một bản ghi chỉ số cũ (PUT /nutrition/me/health-records/:id). Xong thì làm mới cả "latest" lẫn
 * "history" (kèm biểu đồ BMI) bằng cùng tiền tố khóa, giống useCreateHealthRecord.
 * mutate({ id, heightCm, weightKg })
 */
export function useUpdateHealthRecord() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, heightCm, weightKg }) => updateHealthRecord(id, { heightCm, weightKg }),
    onSuccess: () =>
      queryClient.invalidateQueries({ queryKey: profileKeys.healthRecords }),
  });
}
