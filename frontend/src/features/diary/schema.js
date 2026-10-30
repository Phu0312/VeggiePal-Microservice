import { z } from "zod";

// Ô số tùy chọn (để trống được), chấp nhận "12,5". BE từ chối số âm (2009).
const optionalAmount = z
    .string()
    .trim()
    .refine((value) => value === "" || /^\d+([.,]\d+)?$/.test(value), "Nhập số không âm");

const optionalInteger = z
    .string()
    .trim()
    .refine((value) => value === "" || /^\d+$/.test(value), "Nhập số nguyên không âm");

// Ghi một món vào nhật ký (FoodLogRequest: tên tối đa 200 ký tự).
export const foodLogSchema = z.object({
    mealType: z.enum(["BREAKFAST", "LUNCH", "DINNER", "SNACK"]),
    foodName: z.string().trim().min(1, "Vui lòng nhập tên món").max(200, "Tên món tối đa 200 ký tự"),
    calories: optionalInteger,
    proteinG: optionalAmount,
    carbsG: optionalAmount,
    fatG: optionalAmount,
    fiberG: optionalAmount,
});

// Thêm nước một lần: 1 – 5000 ml (AddWaterRequest).
export const waterSchema = z.object({
    amountMl: z
        .string()
        .trim()
        .regex(/^\d+$/, "Nhập số ml")
        .refine((value) => Number(value) >= 1 && Number(value) <= 5000, "Mỗi lần từ 1 đến 5000 ml"),
});

// Vận động trong ngày (DailyActivityRequest). Mục tiêu nước tối thiểu 1 ml.
export const activitySchema = z.object({
    exerciseMinutes: optionalInteger,
    steps: optionalInteger,
    caloriesBurned: optionalInteger,
    waterTargetMl: optionalInteger.refine(
        (value) => value === "" || Number(value) >= 1,
        "Mục tiêu nước tối thiểu 1 ml"
    ),
    activityNote: z.string().trim().max(200, "Ghi chú tối đa 200 ký tự"),
});
