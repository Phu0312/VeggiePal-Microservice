import { z } from "zod";

// Giá trị khớp enum Gender / ActivityLevel của identity-service. Chuỗi rỗng = chưa chọn (BE giữ nguyên giá trị cũ).
const GENDER_VALUES = ["MALE", "FEMALE", "OTHER"];
const ACTIVITY_LEVEL_VALUES = ["SEDENTARY", "LIGHT", "MODERATE", "ACTIVE", "VERY_ACTIVE"];

export const updateProfileSchema = z.object({
  fullName: z.string().trim().min(1, "Vui lòng nhập họ và tên"),
  phone: z
    .string()
    .trim()
    .optional()
    .or(z.literal(""))
    .refine(
      (v) => !v || /^[0-9+\-\s()]{8,20}$/.test(v),
      "Số điện thoại không hợp lệ"
    ),
  dateOfBirth: z
    .string()
    .optional()
    .or(z.literal(""))
    .refine((v) => {
      if (!v) return true;
      const d = new Date(v);
      return !Number.isNaN(d.getTime()) && d < new Date();
    }, "Ngày sinh không hợp lệ"),
  gender: z.enum(GENDER_VALUES).or(z.literal("")).optional(),
  activityLevel: z.enum(ACTIVITY_LEVEL_VALUES).or(z.literal("")).optional(),
});

export const changePasswordSchema = z
  .object({
    currentPassword: z.string().min(1, "Vui lòng nhập mật khẩu hiện tại"),
    newPassword: z.string().min(6, "Mật khẩu mới tối thiểu 6 ký tự"),
    confirmPassword: z.string().min(1, "Vui lòng nhập lại mật khẩu mới"),
  })
  .refine((d) => d.newPassword === d.confirmPassword, {
    message: "Mật khẩu nhập lại không khớp",
    path: ["confirmPassword"],
  });

export const healthRecordSchema = z.object({
  heightCm: z.coerce
    .number({ invalid_type_error: "Chiều cao không hợp lệ" })
    .min(50, "Chiều cao tối thiểu 50 cm")
    .max(250, "Chiều cao tối đa 250 cm"),
  weightKg: z.coerce
    .number({ invalid_type_error: "Cân nặng không hợp lệ" })
    .min(20, "Cân nặng tối thiểu 20 kg")
    .max(300, "Cân nặng tối đa 300 kg"),
});
