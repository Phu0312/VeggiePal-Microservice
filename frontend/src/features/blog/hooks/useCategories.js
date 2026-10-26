import { useQuery } from "@tanstack/react-query";

import { getCategories } from "@/features/blog/api/categoryApi";
import { blogKeys } from "@/features/blog/queryKeys";

/** Cây danh mục (GET /categories) — ít thay đổi nên cache 10 phút. */
export function useCategories({ type, activeOnly = true } = {}) {
  return useQuery({
    queryKey: blogKeys.categoryTree(type, activeOnly),
    queryFn: () => getCategories({ type, activeOnly }),
    staleTime: 10 * 60 * 1000,
  });
}
