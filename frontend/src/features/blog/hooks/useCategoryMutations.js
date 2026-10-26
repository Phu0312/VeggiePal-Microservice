import { useMutation, useQueryClient } from "@tanstack/react-query";

import { createCategory, deleteCategory, updateCategory } from "@/features/blog/api/categoryApi";
import { blogKeys } from "@/features/blog/queryKeys";

// Mọi thay đổi danh mục làm mới toàn bộ cache "blog/categories" (cây ở trang quản trị, chip lọc
// của feed, dropdown trong form viết bài).
function useInvalidateCategories() {
  const queryClient = useQueryClient();
  return () => queryClient.invalidateQueries({ queryKey: blogKeys.categories });
}

/** Tạo danh mục (chỉ ADMIN). mutate(payload) -> Category. */
export function useCreateCategory() {
  const invalidate = useInvalidateCategories();
  return useMutation({ mutationFn: createCategory, onSuccess: invalidate });
}

/** Sửa danh mục (chỉ ADMIN). mutate({ id, payload }) -> Category. */
export function useUpdateCategory() {
  const invalidate = useInvalidateCategories();
  return useMutation({
    mutationFn: ({ id, payload }) => updateCategory(id, payload),
    onSuccess: invalidate,
  });
}

/** Xóa danh mục (chỉ ADMIN). mutate(id). */
export function useDeleteCategory() {
  const invalidate = useInvalidateCategories();
  return useMutation({ mutationFn: deleteCategory, onSuccess: invalidate });
}
