import { useMemo } from "react";
import { useInfiniteQuery, useQuery } from "@tanstack/react-query";

import { getVideo, getVideos } from "@/features/video/api/videoApi";
import { videoKeys } from "@/features/video/queryKeys";
import { flattenPages, getNextPageNumber } from "@/shared/utils/paging";

/**
 * Feed video đã xuất bản (GET /videos) có phân trang dạng "Xem thêm".
 * params: { categoryId, size, enabled }.
 */
export function useVideoFeed({ categoryId, size = 12, enabled = true } = {}, options = {}) {
  const isEnabled = options.enabled ?? enabled;
  const query = useInfiniteQuery({
    queryKey: videoKeys.feed({ categoryId, size }),
    queryFn: ({ pageParam }) =>
      getVideos({ categoryId, page: pageParam, size }),
    initialPageParam: 0,
    getNextPageParam: getNextPageNumber,
    staleTime: 60 * 1000,
    enabled: isEnabled,
  });

  const videos = useMemo(() => flattenPages(query.data), [query.data]);

  return {
    ...query,
    videos,
    total: query.data?.pages?.[0]?.totalElements ?? 0,
  };
}

/**
 * Chi tiết video đã xuất bản (GET /videos/:id).
 * BE tăng 1 lượt xem mỗi lần gọi, nên tắt refetch khi focus để không tăng lượt xem ảo.
 */
export function useVideo(id) {
  return useQuery({
    queryKey: videoKeys.detail(id),
    queryFn: () => getVideo(id),
    enabled: id != null,
    staleTime: 5 * 60 * 1000,
    refetchOnWindowFocus: false,
  });
}
