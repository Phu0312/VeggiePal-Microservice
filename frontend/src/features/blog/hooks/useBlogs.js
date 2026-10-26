import { useInfiniteQuery, useQuery } from "@tanstack/react-query";

import { getBlog, getBlogs, getRelatedBlogs } from "@/features/blog/api/blogApi";
import { blogKeys } from "@/features/blog/queryKeys";
import { flattenPages, getNextPageNumber } from "@/shared/utils/paging";

/**
 * Feed bài viết (GET /blogs) dạng "Tải thêm". params: { categoryId, keyword, sort, size }.
 * Trả về query của React Query + `posts` (mảng phẳng các bài đã tải).
 */
export function useBlogFeed({ categoryId, keyword, sort, size = 10 } = {}) {
  const query = useInfiniteQuery({
    queryKey: blogKeys.feed({ categoryId, keyword, sort, size }),
    queryFn: ({ pageParam }) =>
      getBlogs({ categoryId, keyword, sort, page: pageParam, size }),
    initialPageParam: 0,
    getNextPageParam: getNextPageNumber,
    staleTime: 60 * 1000,
  });

  return { ...query, posts: flattenPages(query.data) };
}

/**
 * Chi tiết một bài (GET /blogs/:id). BE tính 1 lượt xem mỗi lần gọi, nên tắt refetch
 * khi mount lại để không đếm xem trùng chỉ vì người dùng quay lại trang.
 */
export function useBlog(id) {
  return useQuery({
    queryKey: blogKeys.detail(id),
    queryFn: () => getBlog(id),
    enabled: id != null,
    staleTime: 5 * 60 * 1000,
  });
}

/** Tối đa 5 bài cùng danh mục (GET /blogs/:id/related). */
export function useRelatedBlogs(id) {
  return useQuery({
    queryKey: blogKeys.related(id),
    queryFn: () => getRelatedBlogs(id),
    enabled: id != null,
    staleTime: 5 * 60 * 1000,
  });
}
