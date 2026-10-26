import { useInfiniteQuery } from "@tanstack/react-query";

import { getMyVideos } from "@/features/video/api/videoApi";
import { videoKeys } from "@/features/video/queryKeys";
import { flattenPages, getNextPageNumber } from "@/shared/utils/paging";

/**
 * Video của tôi ở mọi trạng thái (GET /videos/me) có phân trang dạng "Xem thêm".
 * status: "DRAFT" | "PENDING" | "PUBLISHED" | "REJECTED" | "BANNED", bỏ trống = tất cả.
 */
export function useMyVideos({ status, size = 10 } = {}) {
  const query = useInfiniteQuery({
    queryKey: videoKeys.mine(status, size),
    queryFn: ({ pageParam }) => getMyVideos({ status, page: pageParam, size }),
    initialPageParam: 0,
    getNextPageParam: getNextPageNumber,
  });

  return {
    ...query,
    videos: flattenPages(query.data),
    total: query.data?.pages?.[0]?.totalElements ?? 0,
  };
}
