// Chuyển đổi giữa dữ liệu form nguyên liệu (toàn chuỗi) và IngredientRequest / IngredientResponse của BE.
// Không import alias @/ để file test (node --test) chạy được.
import { parseDecimal } from "../schema.js";

export function emptyIngredientForm() {
  return {
    name: "",
    description: "",
    caloriesPer100g: "",
    proteinPer100g: "",
    carbsPer100g: "",
    fatPer100g: "",
    fiberPer100g: "",
    vegan: true,
    allergen: false,
    active: true,
  };
}

const toText = (value) => (value == null ? "" : String(Number(value)));

/** IngredientResponse -> giá trị ban đầu của form sửa. */
export function ingredientToFormValues(ingredient) {
  return {
    name: ingredient.name ?? "",
    description: ingredient.description ?? "",
    caloriesPer100g: toText(ingredient.caloriesPer100g),
    proteinPer100g: toText(ingredient.proteinPer100g),
    carbsPer100g: toText(ingredient.carbsPer100g),
    fatPer100g: toText(ingredient.fatPer100g),
    fiberPer100g: toText(ingredient.fiberPer100g),
    vegan: ingredient.vegan ?? true,
    allergen: ingredient.allergen ?? false,
    active: ingredient.active ?? true,
  };
}

/** Giá trị form (đã qua ingredientSchema) -> IngredientRequest. Chất xơ để trống -> null. */
export function formValuesToPayload(values) {
  return {
    name: values.name.trim(),
    description: values.description.trim() || null,
    caloriesPer100g: parseDecimal(values.caloriesPer100g),
    proteinPer100g: parseDecimal(values.proteinPer100g),
    carbsPer100g: parseDecimal(values.carbsPer100g),
    fatPer100g: parseDecimal(values.fatPer100g),
    fiberPer100g: values.fiberPer100g.trim() === "" ? null : parseDecimal(values.fiberPer100g),
    vegan: values.vegan,
    allergen: values.allergen,
    active: values.active,
  };
}
