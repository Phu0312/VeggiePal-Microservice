import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { getVideoNutrition, updateVideoNutrition } from "@/features/video/api/videoApi";
import { videoKeys } from "@/features/video/queryKeys";

/** Dinh dưỡng của một video (GET /videos/:id/nutrition, công khai). `data` = null khi video chưa có thông tin. */
export function useVideoNutrition(videoId) {
  return useQuery({
    queryKey: videoKeys.nutrition(videoId),
    queryFn: () => getVideoNutrition(videoId),
    enabled: videoId != null,
    staleTime: 60 * 1000,
  });
}

/** Lưu dinh dưỡng (chủ video hoặc ADMIN). mutate({ videoId, payload }); ghi kết quả thẳng vào cache. */
export function useUpdateVideoNutrition() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ videoId, payload }) => updateVideoNutrition(videoId, payload),
    onSuccess: (result, { videoId }) => queryClient.setQueryData(videoKeys.nutrition(videoId), result ?? null),
  });
}
