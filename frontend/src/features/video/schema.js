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
