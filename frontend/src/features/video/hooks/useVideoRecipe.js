import { useIsMutating, useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";

import { selectIsAuthenticated, useAuthStore } from "@/features/auth/store/authStore";
import { useMySubscription } from "@/features/payment/hooks/useMySubscription";
import { getVideoRecipe, processExistingVideo } from "@/features/video/api/videoJobApi";
import { videoKeys } from "@/features/video/queryKeys";
import { recipeStateFromJob, VIDEO_JOB_POLL_MS } from "@/features/video/utils/videoJob";

/**
 * Công thức AI của một video đã đăng, dùng chung cho nút ở tiêu đề và thẻ "AI Summary" (cùng queryKey nên chỉ
 * gọi BE một lần). `video` là kết quả GET /videos/:id (undefined khi đang tải).
 *
 * status:
 * - "loading"     đang tải video hoặc đang hỏi BE
 * - "unsupported" video YouTube (BE chỉ bóc tách video tải lên, mã 6026)
 * - "login"       chưa đăng nhập (chỉ áp dụng khi video chưa có công thức và cần đăng nhập để bóc tách)
 * - "none"        chưa có kết quả, có thể bóc tách (trừ 1 lượt của gói)
 * - "processing"  AI đang bóc tách (kể cả đang gửi yêu cầu), tự hỏi lại mỗi vài giây
 * - "failed"      lần trước thất bại (lượt đã hoàn lại), có thể thử lại
 * - "ready"       đã có `extraction` { title, ingredients, steps }
 * - "error"       không hỏi được BE (`error` là chuỗi tiếng Việt, `refetch` để thử lại)
 * `noQuota` = gói hiện tại không có lượt bóc tách (vd FREE): vẫn xem được kết quả có sẵn nhưng không tạo mới.
 * `run()` gửi yêu cầu bóc tách, tự báo toast khi gửi xong hoặc lỗi.
 */
export function useVideoRecipe(video) {
  const queryClient = useQueryClient();
  const isAuthenticated = useAuthStore(selectIsAuthenticated);
  const { subscription } = useMySubscription();

  const videoId = video?.id;
  const unsupported = Boolean(video) && video.sourceType !== "UPLOAD";
  const enabled = Boolean(videoId) && !unsupported;

  const query = useQuery({
    queryKey: videoKeys.recipe(videoId),
    queryFn: () => getVideoRecipe(videoId),
    enabled,
    refetchInterval: (q) => (q.state.data?.state === "processing" ? VIDEO_JOB_POLL_MS : false),
  });

  const extract = useMutation({
    mutationKey: videoKeys.recipeRun(videoId),
    mutationFn: () => processExistingVideo(videoId),
    onSuccess: (job) => {
      const next = recipeStateFromJob(job);
      queryClient.setQueryData(videoKeys.recipe(videoId), next);
      queryClient.invalidateQueries({ queryKey: videoKeys.jobsList });
      if (next.state === "ready") toast.success("Video này đã có công thức AI");
      else toast.info("Đã gửi video, AI đang bóc tách công thức. Kết quả sẽ tự hiện ở trang này.");
    },
    onError: (error) => toast.error(error.message),
  });

  // Đếm theo khóa chung (không dùng extract.isPending) vì nút ở tiêu đề và thẻ AI là hai nơi gọi hook này.
  const starting = useIsMutating({ mutationKey: videoKeys.recipeRun(videoId) }) > 0;

  let status;
  if (!video) status = "loading";
  else if (unsupported) status = "unsupported";
  else if (starting) status = "processing";
  else if (query.isPending) status = "loading";
  else if (query.isError) status = "error";
  else if (query.data.state === "ready") status = "ready";
  else if (query.data.state === "processing") status = "processing";
  else if (query.data.state === "unsupported") status = "unsupported";
  else if (!isAuthenticated) status = "login";
  else status = query.data.state;

  return {
    status,
    extraction: query.data?.extraction ?? null,
    error: query.error?.message ?? "",
    refetch: query.refetch,
    noQuota: subscription?.videosPerMonth === 0,
    run: () => extract.mutate(),
  };
}
