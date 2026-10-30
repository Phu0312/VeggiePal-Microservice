import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import {
  addFoodLog,
  addWater,
  deleteFoodLog,
  getDailySummary,
  updateDailyActivity,
} from "@/features/diary/api/diaryApi";
import { diaryKeys } from "@/features/diary/queryKeys";

/** Tổng hợp nhật ký một ngày. `errorCode` để màn hình nhận ra 2013 / 2014. */
export function useDailySummary(date, goalType) {
  const query = useQuery({
    queryKey: diaryKeys.summary(date, goalType),
    queryFn: () => getDailySummary({ date, goalType }),
  });
  return {
    summary: query.data ?? null,
    loading: query.isPending,
    error: query.error ? query.error.message : "",
    errorCode: query.error?.code ?? null,
    refetch: query.refetch,
    refetching: query.isRefetching,
  };
}

// Mọi thay đổi trong ngày đều làm mới tổng hợp của ngày đó (mọi goalType).
function useDayMutation(mutationFn) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn,
    onSuccess: (_data, variables) => {
      const date = variables?.date ?? variables?.logDate;
      return queryClient.invalidateQueries({ queryKey: date ? diaryKeys.day(date) : diaryKeys.all });
    },
  });
}

export function useAddFoodLog() {
  return useDayMutation(addFoodLog);
}

/** Biến: { id, date } (date để biết làm mới ngày nào). */
export function useDeleteFoodLog() {
  return useDayMutation(({ id }) => deleteFoodLog(id));
}

export function useAddWater() {
  return useDayMutation(addWater);
}

export function useUpdateDailyActivity() {
  return useDayMutation(updateDailyActivity);
}
