import { keepPreviousData, useInfiniteQuery, useQuery } from "@tanstack/react-query";

import { getRecipe, getRecipes } from "@/features/recipe/api/recipeApi";
import { recipeKeys } from "@/features/recipe/queryKeys";
import { flattenPages, getNextPageNumber } from "@/shared/utils/paging";

/**
 * Danh sách công thức đã publish (GET /recipes). params: { keyword, page, size }.
 * Giữ dữ liệu trang cũ trong lúc tải trang/từ khóa mới để danh sách không bị nháy.
 */
export function useRecipes(params = {}) {
  return useQuery({
    queryKey: recipeKeys.list(params),
    queryFn: () => getRecipes(params),
    placeholderData: keepPreviousData,
    staleTime: 60 * 1000,
  });
}

/** Chi tiết công thức (GET /recipes/:id). */
export function useRecipe(id) {
  return useQuery({
    queryKey: recipeKeys.detail(id),
    queryFn: () => getRecipe(id),
    enabled: id != null,
    staleTime: 60 * 1000,
  });
}

/**
 * Feed công thức đã đăng dạng "Xem thêm" (GET /recipes), lọc theo từ khóa.
 * Trả về query của React Query + `recipes` (mảng phẳng) + `total`.
 * recipe-service trả danh sách ở field `content` (khác blog-service dùng `items`).
 */
export function useRecipeFeed({ keyword, size = 12 } = {}) {
  const query = useInfiniteQuery({
    queryKey: recipeKeys.feed({ keyword, size }),
    queryFn: ({ pageParam }) => getRecipes({ keyword, page: pageParam, size }),
    initialPageParam: 0,
    getNextPageParam: getNextPageNumber,
    staleTime: 60 * 1000,
  });

  return {
    ...query,
    recipes: flattenPages(query.data, "content"),
    total: query.data?.pages?.[0]?.totalElements ?? 0,
  };
}
