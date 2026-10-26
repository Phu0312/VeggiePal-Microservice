import { z } from "zod";

// Giới hạn khớp IngredientRequest / cột của recipe-service.
export const INGREDIENT_LIMITS = { name: 150, description: 1000 };

/** "12,5" hoặc "12.5" -> 12.5. NaN nếu không phải số. */
export function parseDecimal(text) {
  return Number(String(text).trim().replace(",", "."));
}

const DECIMAL_PATTERN = /^\d{1,8}([.,]\d{1,2})?$/;
const DECIMAL_MESSAGE = "Nhập số từ 0 trở lên, tối đa 2 số thập phân";

const requiredNutrition = (label) =>
  z.string().trim().min(1, `Vui lòng nhập ${label}`).regex(DECIMAL_PATTERN, DECIMAL_MESSAGE);

// Form tạo / sửa nguyên liệu của admin. Số giữ dạng chuỗi vì lấy từ <input>
// (đổi sang số ở utils/ingredientForm.js). Chất xơ không bắt buộc, khớp BE.
export const ingredientSchema = z.object({
  name: z
    .string()
    .trim()
    .min(1, "Vui lòng nhập tên nguyên liệu")
    .max(INGREDIENT_LIMITS.name, `Tên tối đa ${INGREDIENT_LIMITS.name} ký tự`),
  description: z
    .string()
    .trim()
    .max(INGREDIENT_LIMITS.description, `Mô tả tối đa ${INGREDIENT_LIMITS.description} ký tự`),
  caloriesPer100g: requiredNutrition("năng lượng"),
  proteinPer100g: requiredNutrition("lượng đạm"),
  carbsPer100g: requiredNutrition("lượng tinh bột"),
  fatPer100g: requiredNutrition("lượng béo"),
  fiberPer100g: z
    .string()
    .trim()
    .refine((v) => v === "" || DECIMAL_PATTERN.test(v), DECIMAL_MESSAGE),
  vegan: z.boolean(),
  allergen: z.boolean(),
  active: z.boolean(),
});
