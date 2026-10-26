// Chuyển đổi giữa dữ liệu form công thức (toàn chuỗi, theo <input>) và payload / RecipeResponse của BE.
// Không import alias @/ để file test (node --test) chạy được.
import { parseQuantity } from "../schema.js";

// Đơn vị cho chọn. BE lưu chuỗi tự do và tự IN HOA. Chỉ GRAM / G / KG quy đổi được ra gram
// để tính kcal (xem recipeNutrition.js), các đơn vị còn lại thì công thức sẽ không có kcal.
export const UNIT_OPTIONS = [
  { value: "GRAM", label: "gram" },
  { value: "KG", label: "kg" },
  { value: "ML", label: "ml" },
  { value: "TBSP", label: "muỗng canh" },
  { value: "TSP", label: "muỗng cà phê" },
  { value: "PIECE", label: "quả / củ / miếng" },
];

export function emptyRecipeForm() {
  return {
    title: "",
    description: "",
    imageUrl: "",
    servings: "2",
    prepTime: "",
    cookTime: "",
    ingredients: [],
    steps: [{ instruction: "" }],
  };
}

/** RecipeResponse (từ GET /recipes/:id) -> giá trị ban đầu của form sửa. */
export function recipeToFormValues(recipe) {
  const steps = [...(recipe.steps ?? [])]
    .sort((a, b) => a.stepNumber - b.stepNumber)
    .map((s) => ({ instruction: s.instruction }));

  return {
    title: recipe.title ?? "",
    description: recipe.description ?? "",
    imageUrl: recipe.imageUrl ?? "",
    servings: String(recipe.servings ?? 1),
    prepTime: recipe.prepTime == null ? "" : String(recipe.prepTime),
    cookTime: recipe.cookTime == null ? "" : String(recipe.cookTime),
    ingredients: (recipe.ingredients ?? []).map((i) => ({
      ingredientId: i.ingredientId,
      ingredientName: i.ingredientName,
      quantity: String(i.quantity),
      unit: i.unit,
      note: i.note ?? "",
    })),
    steps: steps.length > 0 ? steps : [{ instruction: "" }],
  };
}

/**
 * Giá trị form (đã qua recipeSchema) -> RecipeRequest gửi lên BE.
 * - thứ tự bước = vị trí trong danh sách (stepNumber bắt đầu từ 1)
 * - thời gian để trống -> null; quantity đổi dấu phẩy thành dấu chấm rồi ép số
 */
export function formValuesToPayload(values) {
  return {
    title: values.title.trim(),
    description: values.description.trim() || null,
    imageUrl: values.imageUrl.trim() || null,
    servings: Number(values.servings),
    prepTime: values.prepTime.trim() === "" ? null : Number(values.prepTime),
    cookTime: values.cookTime.trim() === "" ? null : Number(values.cookTime),
    ingredients: values.ingredients.map((i) => ({
      ingredientId: i.ingredientId,
      quantity: parseQuantity(i.quantity),
      unit: i.unit.trim(),
      note: i.note.trim() || null,
    })),
    steps: values.steps.map((s, index) => ({
      stepNumber: index + 1,
      instruction: s.instruction.trim(),
    })),
  };
}
