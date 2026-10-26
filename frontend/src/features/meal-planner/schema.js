import { z } from "zod";

import { GOAL_OPTIONS, TARGET_FIELDS, parseTargetNumber } from "@/features/meal-planner/utils/mealPlan";

// Giới hạn khớp GenerateRequest của ai-service. `healthGoal` của BE tối đa 500 ký tự gồm cả nhãn mục tiêu
// ("Tăng cân: ") nên mô tả thêm của người dùng (`healthNote`) giữ ngắn hơn.
export const MEAL_PLAN_LIMITS = {
  name: 160,
  healthNote: 400,
  ingredients: 30,
};

// Mục tiêu dinh dưỡng là tùy chọn: ô trống hợp lệ; có nhập thì phải là số không âm.
const targetField = z
  .string()
  .trim()
  .refine((v) => v === "" || (Number.isFinite(parseTargetNumber(v)) && parseTargetNumber(v) >= 0), {
    message: "Nhập số từ 0 trở lên",
  });

const targetShape = Object.fromEntries(TARGET_FIELDS.map((field) => [field, targetField]));

// BE từ chối khoảng min > max (mã 6000); báo sớm ngay trên ô "tối thiểu".
function checkTargetRanges(values, ctx) {
  for (const field of TARGET_FIELDS) {
    if (!field.startsWith("min")) continue;
    const max = parseTargetNumber(values[`max${field.slice(3)}`]);
    const min = parseTargetNumber(values[field]);
    if (Number.isFinite(min) && Number.isFinite(max) && min > max) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: [field],
        message: "Tối thiểu không được lớn hơn tối đa",
      });
    }
  }
}

// Ghi chú thay đổi lưu vào lịch sử phiên bản (cột BE tối đa 500 ký tự; FE giữ ngắn hơn cho gọn).
export const HEALTH_UPDATE_LIMITS = { changeSummary: 200 };

// Form "Cập nhật theo chỉ số mới": mục tiêu riêng (tùy chọn) + ghi chú thay đổi (tùy chọn).
export const healthUpdateSchema = z
  .object({
    ...targetShape,
    changeSummary: z
      .string()
      .trim()
      .max(HEALTH_UPDATE_LIMITS.changeSummary, `Ghi chú tối đa ${HEALTH_UPDATE_LIMITS.changeSummary} ký tự`),
  })
  .superRefine(checkTargetRanges);

export const mealPlanSchema = z
  .object({
    name: z
      .string()
      .trim()
      .min(1, "Vui lòng đặt tên cho thực đơn")
      .max(MEAL_PLAN_LIMITS.name, `Tên thực đơn tối đa ${MEAL_PLAN_LIMITS.name} ký tự`),
    // Bắt buộc chọn một mục tiêu (BE yêu cầu goalType). Giá trị rỗng (chưa chọn) cũng rơi vào lỗi này.
    goalType: z.enum(
      GOAL_OPTIONS.map((option) => option.value),
      { errorMap: () => ({ message: "Vui lòng chọn mục tiêu của thực đơn" }) },
    ),
    // Mô tả thêm cho AI (tùy chọn).
    healthNote: z
      .string()
      .trim()
      .max(MEAL_PLAN_LIMITS.healthNote, `Mô tả tối đa ${MEAL_PLAN_LIMITS.healthNote} ký tự`),
    ...targetShape,
  })
  .superRefine(checkTargetRanges);
