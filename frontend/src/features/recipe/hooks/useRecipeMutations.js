import { useMutation, useQueryClient } from "@tanstack/react-query";

import {
  changeRecipeImage,
  createRecipe,
  deleteRecipe,
  likeRecipe,
  publishRecipe,
  unlikeRecipe,
  updateRecipe,
  uploadRecipeImageFile,
} from "@/features/recipe/api/recipeApi";
import { recipeKeys } from "@/features/recipe/queryKeys";

// Mọi thay đổi công thức làm mới toàn bộ cache "recipes" (danh sách công khai, chi tiết, của tôi).
function useInvalidateRecipes() {
  const queryClient = useQueryClient();
  return () => queryClient.invalidateQueries({ queryKey: recipeKeys.all });
}

/** Tạo công thức (luôn là DRAFT). mutate(payload) -> RecipeResponse. */
export function useCreateRecipe() {
  const invalidate = useInvalidateRecipes();
  return useMutation({ mutationFn: createRecipe, onSuccess: invalidate });
}

/** Sửa công thức. mutate({ id, payload }) -> RecipeResponse. */
export function useUpdateRecipe() {
  const invalidate = useInvalidateRecipes();
  return useMutation({
    mutationFn: ({ id, payload }) => updateRecipe(id, payload),
    onSuccess: invalidate,
  });
}

/** Đăng công thức. mutate(id) -> RecipeResponse. */
export function usePublishRecipe() {
  const invalidate = useInvalidateRecipes();
  return useMutation({ mutationFn: publishRecipe, onSuccess: invalidate });
}

/** Xóa công thức. mutate(id). */
export function useDeleteRecipe() {
  const invalidate = useInvalidateRecipes();
  return useMutation({ mutationFn: deleteRecipe, onSuccess: invalidate });
}

/** Tải ảnh cho form tạo mới. mutate(file) -> imageUrl. */
export function useUploadRecipeImage() {
  return useMutation({ mutationFn: uploadRecipeImageFile });
}

/** Đổi ảnh công thức đã có (lưu ngay). mutate({ id, file }) -> RecipeResponse. */
export function useChangeRecipeImage() {
  const invalidate = useInvalidateRecipes();
  return useMutation({ mutationFn: ({ id, file }) => changeRecipeImage(id, file), onSuccess: invalidate });
}

/**
 * Thích / bỏ thích. mutate({ id, liked }) với liked là trạng thái muốn đặt.
 * Ghi kết quả của BE vào cache trạng thái thích và số lượt thích ở trang chi tiết, không tải lại cả danh sách.
 */
export function useToggleRecipeLike() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, liked }) => (liked ? likeRecipe(id) : unlikeRecipe(id)),
    onSuccess: (result, { id }) => {
      if (!result) return;
      queryClient.setQueryData(recipeKeys.likes([id]), [result]);
      queryClient.setQueryData(recipeKeys.detail(id), (old) => (old ? { ...old, likeCount: result.likeCount } : old));
    },
  });
}
