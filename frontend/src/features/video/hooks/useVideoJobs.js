import { useInfiniteQuery, useMutation, useQueryClient } from "@tanstack/react-query";

import { getVideoJobs, processVideo } from "@/features/video/api/videoJobApi";
import { videoKeys } from "@/features/video/queryKeys";
import { hasProcessingJob, VIDEO_JOB_POLL_MS } from "@/features/video/utils/videoJob";
import { flattenPages, getNextPageNumber } from "@/shared/utils/paging";

/**
 * Lịch sử bóc tách công thức từ video (GET /ai/videos) có phân trang "Xem thêm".
 * Còn job PROCESSING thì tự hỏi lại BE mỗi vài giây, hết thì dừng (job mới nhất nằm ở trang đầu).
 */
export function useVideoJobs({ size = 10 } = {}) {
  const query = useInfiniteQuery({
    queryKey: videoKeys.jobs(size),
    queryFn: ({ pageParam }) => getVideoJobs({ page: pageParam, size }),
    initialPageParam: 0,
    getNextPageParam: getNextPageNumber,
    refetchInterval: (q) =>
      hasProcessingJob(flattenPages(q.state.data, "content")) ? VIDEO_JOB_POLL_MS : false,
  });

  return {
    ...query,
    jobs: flattenPages(query.data, "content"),
    total: query.data?.pages?.[0]?.totalElements ?? 0,
  };
}

/**
 * Gửi video đi bóc tách (POST /ai/videos/process).
 * mutate({ file, onUploadProgress }) -> job { id, status: "PROCESSING", ... }.
 */
export function useStartVideoJob() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ file, onUploadProgress }) => processVideo(file, { onUploadProgress }),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: videoKeys.jobsRoot }),
  });
}
