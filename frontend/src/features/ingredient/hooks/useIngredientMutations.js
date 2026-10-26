import { useMutation, useQueryClient } from "@tanstack/react-query";

import {
  createIngredient,
  deleteIngredient,
  updateIngredient,
} from "@/features/ingredient/api/ingredientApi";
import { ingredientKeys } from "@/features/ingredient/queryKeys";

// Mọi thay đổi nguyên liệu làm mới toàn bộ cache "ingredients" (danh sách, chi tiết, và dinh dưỡng
// đang dùng để tính kcal công thức).
function useInvalidateIngredients() {
  const queryClient = useQueryClient();
  return () => queryClient.invalidateQueries({ queryKey: ingredientKeys.all });
}

/** Tạo nguyên liệu (chỉ ADMIN). mutate(payload) -> Ingredient. */
export function useCreateIngredient() {
  const invalidate = useInvalidateIngredients();
  return useMutation({ mutationFn: createIngredient, onSuccess: invalidate });
}

/** Sửa nguyên liệu (chỉ ADMIN). mutate({ id, payload }) -> Ingredient. */
export function useUpdateIngredient() {
  const invalidate = useInvalidateIngredients();
  return useMutation({
    mutationFn: ({ id, payload }) => updateIngredient(id, payload),
    onSuccess: invalidate,
  });
}

/** Xóa nguyên liệu (chỉ ADMIN). mutate(id). */
export function useDeleteIngredient() {
  const invalidate = useInvalidateIngredients();
  return useMutation({ mutationFn: deleteIngredient, onSuccess: invalidate });
}
