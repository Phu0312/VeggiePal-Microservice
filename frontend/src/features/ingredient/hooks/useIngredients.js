import { keepPreviousData, useQuery } from "@tanstack/react-query";

import { getIngredients } from "@/features/ingredient/api/ingredientApi";
import { ingredientKeys } from "@/features/ingredient/queryKeys";

/**
 * Danh sách nguyên liệu (GET /ingredients). params: { keyword, vegan, allergen, page, size }.
 * Giữ dữ liệu trang cũ trong lúc tải trang/từ khóa mới để danh sách không bị nháy.
 */
export function useIngredients(params = {}) {
  return useQuery({
    queryKey: ingredientKeys.list(params),
    queryFn: () => getIngredients(params),
    placeholderData: keepPreviousData,
    staleTime: 5 * 60 * 1000,
  });
}
