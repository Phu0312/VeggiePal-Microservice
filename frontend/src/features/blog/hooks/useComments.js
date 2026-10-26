import { useInfiniteQuery } from "@tanstack/react-query";

import { getComments, getReplies } from "@/features/blog/api/commentApi";
import { blogKeys } from "@/features/blog/queryKeys";
import { flattenPages, getNextPageNumber } from "@/shared/utils/paging";

/**
 * Comment cấp 1 của một bài (GET /comments) dạng "Xem thêm".
 * Trả về query của React Query + `comments` (mảng phẳng) + `total` (tổng số comment cấp 1).
 */
export function useComments(blogId, { size = 20 } = {}) {
  const query = useInfiniteQuery({
    queryKey: blogKeys.commentList(blogId, { size }),
    queryFn: ({ pageParam }) =>
      getComments({ targetType: "BLOG", targetId: blogId, page: pageParam, size }),
    initialPageParam: 0,
    getNextPageParam: getNextPageNumber,
    enabled: blogId != null,
  });

  return {
    ...query,
    comments: flattenPages(query.data),
    total: query.data?.pages?.[0]?.totalElements ?? 0,
  };
}

/**
 * Reply của một comment (GET /comments/:id/replies). Chỉ truyền `enabled: true`
 * khi người dùng bấm "Xem phản hồi" để khỏi gọi API cho mọi comment ngay từ đầu.
 */
export function useReplies(commentId, { size = 20, enabled = true } = {}) {
  const query = useInfiniteQuery({
    queryKey: blogKeys.replies(commentId, { size }),
    queryFn: ({ pageParam }) => getReplies(commentId, { page: pageParam, size }),
    initialPageParam: 0,
    getNextPageParam: getNextPageNumber,
    enabled: enabled && commentId != null,
  });

  return { ...query, replies: flattenPages(query.data) };
}
