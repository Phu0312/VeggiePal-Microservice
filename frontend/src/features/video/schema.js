import { z } from "zod";

import {
  extractYouTubeId,
  VIDEO_DESCRIPTION_MAX,
  VIDEO_TITLE_MAX,
} from "@/features/video/utils/videoForm";

export const videoCreateSchema = z
  .object({
    title: z
      .string()
      .trim()
      .min(1, "Vui lòng nhập tiêu đề video")
      .max(VIDEO_TITLE_MAX, `Tiêu đề tối đa ${VIDEO_TITLE_MAX} ký tự`),
    categoryId: z
      .string()
      .trim()
      .regex(/^[1-9]\d*$/, "Vui lòng chọn danh mục"),
    description: z
      .string()
      .max(VIDEO_DESCRIPTION_MAX, `Mô tả tối đa ${VIDEO_DESCRIPTION_MAX} ký tự`)
      .optional()
      .default(""),
    sourceType: z.enum(["UPLOAD", "YOUTUBE"]),
    youtubeUrl: z.string().optional(),
  })
  .superRefine((data, ctx) => {
    if (data.sourceType === "YOUTUBE") {
      const trimmed = data.youtubeUrl?.trim() ?? "";
      if (!trimmed) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          path: ["youtubeUrl"],
          message: "Vui lòng nhập liên kết YouTube",
        });
      } else if (!extractYouTubeId(trimmed)) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          path: ["youtubeUrl"],
          message: "Liên kết YouTube không hợp lệ (hỗ trợ youtube.com/watch, youtu.be, shorts)",
        });
      }
    }
  });

export const videoEditSchema = z.object({
  title: z
    .string()
    .trim()
    .min(1, "Vui lòng nhập tiêu đề video")
    .max(VIDEO_TITLE_MAX, `Tiêu đề tối đa ${VIDEO_TITLE_MAX} ký tự`),
  categoryId: z
    .string()
    .trim()
    .regex(/^[1-9]\d*$/, "Vui lòng chọn danh mục"),
  description: z
    .string()
    .max(VIDEO_DESCRIPTION_MAX, `Mô tả tối đa ${VIDEO_DESCRIPTION_MAX} ký tự`)
    .optional()
    .default(""),
});

// Dinh dưỡng của video (VideoNutritionRequest): số không âm, nhãn khẩu phần <= 100 ký tự,
// nguyên liệu tên <= 150, lượng <= 80 ký tự. Ô số để trống được.
const optionalAmount = z
  .string()
  .trim()
  .refine((value) => value === "" || /^d+([.,]d+)?$/.test(value), "Nhập số không âm");

export const videoNutritionSchema = z.object({
  servingLabel: z.string().trim().max(100, "Tối đa 100 ký tự"),
  kcal: z
    .string()
    .trim()
    .refine((value) => value === "" || /^d+$/.test(value), "Nhập số nguyên không âm"),
  proteinG: optionalAmount,
  carbsG: optionalAmount,
  fatG: optionalAmount,
  fiberG: optionalAmount,
  ingredients: z.array(
    z.object({
      name: z.string().trim().min(1, "Nhập tên nguyên liệu").max(150, "Tối đa 150 ký tự"),
      amount: z.string().trim().max(80, "Tối đa 80 ký tự"),
    })
  ),
});
