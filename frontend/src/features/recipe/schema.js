import { z } from "zod";

// Giới hạn khớp cột của recipe-service (BE không tự kiểm tra, vượt sẽ lỗi 500).
export const RECIPE_LIMITS = {
  title: 200,
  description: 2000,
  imageUrl: 500,
  unit: 30,
  note: 300,
  instruction: 2000,
};

const nonNegativeInt = (label) =>
  z
    .string()
    .trim()
    .refine((v) => v === "" || /^\d{1,4}$/.test(v), `${label} phải là số nguyên không âm`);

/** "0,5" hoặc "0.5" -> 0.5 (người dùng Việt hay gõ dấu phẩy). NaN nếu không phải số. */
export function parseQuantity(text) {
  return Number(String(text).trim().replace(",", "."));
}

// Số lượng: tối đa 2 chữ số thập phân (cột decimal(10,2)) và tối thiểu 0,01 (@DecimalMin của BE).
const quantityField = z
  .string()
  .trim()
  .refine(
    (v) => /^\d{1,8}([.,]\d{1,2})?$/.test(v) && parseQuantity(v) >= 0.01,
    "Số lượng tối thiểu 0,01 và tối đa 2 số thập phân"
  );

// Form tạo / sửa công thức. Số giữ dạng chuỗi vì lấy từ <input>, đổi sang số khi gửi
// (xem formValuesToPayload ở utils/recipeForm.js).
export const recipeSchema = z.object({
  title: z
    .string()
    .trim()
    .min(1, "Vui lòng nhập tên công thức")
    .max(RECIPE_LIMITS.title, `Tên công thức tối đa ${RECIPE_LIMITS.title} ký tự`),
  description: z
    .string()
    .trim()
    .max(RECIPE_LIMITS.description, `Mô tả tối đa ${RECIPE_LIMITS.description} ký tự`),
  imageUrl: z
    .string()
    .trim()
    .max(RECIPE_LIMITS.imageUrl, `Link ảnh tối đa ${RECIPE_LIMITS.imageUrl} ký tự`)
    .refine((v) => v === "" || /^https?:\/\/\S+$/i.test(v), "Link ảnh phải bắt đầu bằng http:// hoặc https://"),
  servings: z.string().trim().regex(/^[1-9]\d{0,3}$/, "Số khẩu phần phải là số nguyên từ 1 trở lên"),
  prepTime: nonNegativeInt("Thời gian chuẩn bị"),
  cookTime: nonNegativeInt("Thời gian nấu"),
  ingredients: z
    .array(
      z.object({
        ingredientId: z.number().int().positive(),
        ingredientName: z.string(),
        quantity: quantityField,
        unit: z.string().trim().min(1, "Chọn đơn vị").max(RECIPE_LIMITS.unit),
        note: z.string().trim().max(RECIPE_LIMITS.note, `Ghi chú tối đa ${RECIPE_LIMITS.note} ký tự`),
      })
    )
    .min(1, "Thêm ít nhất 1 nguyên liệu"),
  steps: z
    .array(
      z.object({
        instruction: z
          .string()
          .trim()
          .min(1, "Vui lòng nhập nội dung bước")
          .max(RECIPE_LIMITS.instruction, `Mỗi bước tối đa ${RECIPE_LIMITS.instruction} ký tự`),
      })
    )
    .min(1, "Thêm ít nhất 1 bước thực hiện"),
});
