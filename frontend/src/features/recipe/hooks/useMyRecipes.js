import { useInfiniteQuery } from "@tanstack/react-query";

import { flattenPages, getNextPageNumber } from "@/shared/utils/paging";
import { getMyRecipes } from "@/features/recipe/api/recipeApi";
import { recipeKeys } from "@/features/recipe/queryKeys";

/**
 * Công thức của tôi ở mọi trạng thái (GET /recipes/me) dạng "Xem thêm".
 * Trả về query của React Query + `recipes` (mảng phẳng) + `total`.
 * recipe-service trả danh sách ở field `content` (khác blog-service dùng `items`).
 */
export function useMyRecipes({ size = 10 } = {}) {
  const query = useInfiniteQuery({
    queryKey: recipeKeys.mine(size),
    queryFn: ({ pageParam }) => getMyRecipes({ page: pageParam, size }),
    initialPageParam: 0,
    getNextPageParam: getNextPageNumber,
  });

  return {
    ...query,
    recipes: flattenPages(query.data, "content"),
    total: query.data?.pages?.[0]?.totalElements ?? 0,
  };
}
