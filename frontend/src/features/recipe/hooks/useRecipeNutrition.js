import { useMemo } from "react";

import { calcRecipeNutrition, nutritionGapHint } from "@/features/recipe/utils/recipeNutrition";

/**
 * Dinh dưỡng mỗi khẩu phần của danh sách công thức.
 * BE đã nhúng dinh dưỡng trên 100g vào từng nguyên liệu của công thức (cả danh sách lẫn chi tiết) nên chỉ cần
 * cộng lại tại chỗ, không còn gọi API riêng cho từng nguyên liệu.
 *
 * Trả về:
 * - nutritionById: Map<recipeId, { kcal, protein, carbs, fat } | null>, null nghĩa là chưa tính được
 * - gapById: Map<recipeId, string> chỉ có với công thức chưa tính được vì đơn vị (ml, muỗng, quả...), kèm lý do
 */
export function useRecipeNutrition(recipes) {
  return useMemo(() => {
    const nutritionById = new Map();
    const gapById = new Map();
    for (const recipe of recipes ?? []) {
      const nutrition = calcRecipeNutrition(recipe);
      nutritionById.set(recipe.id, nutrition);
      const gap = nutrition ? null : nutritionGapHint(recipe);
      if (gap) gapById.set(recipe.id, gap);
    }
    return { nutritionById, gapById };
  }, [recipes]);
}
