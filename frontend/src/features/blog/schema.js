import { z } from "zod";

// Import tương đối (không dùng alias @/) để `npm test` (node --test) tự resolve được file này.
import { MAX_COMMENT_CHARS, MAX_COMMENT_WORDS, countWords } from "./utils/commentText.js";

// Form viết / sửa bình luận, khớp luật của CommentRequest ở blog-service.
export const commentSchema = z.object({
  content: z
    .string()
    .trim()
    .min(1, "Vui lòng nhập nội dung bình luận")
    .max(MAX_COMMENT_CHARS, `Bình luận tối đa ${MAX_COMMENT_CHARS} ký tự`)
    .refine((text) => countWords(text) <= MAX_COMMENT_WORDS, {
      message: `Bình luận tối đa ${MAX_COMMENT_WORDS} từ`,
    }),
});

export const BLOG_TITLE_MAX = 150;
export const BLOG_CONTENT_MIN = 20;

// Form viết / sửa bài, khớp BlogRequest: tiêu đề tối đa 150 ký tự, nội dung tối thiểu 20 ký tự,
// bắt buộc chọn danh mục. categoryId giữ dạng chuỗi vì lấy từ dropdown, đổi sang số khi gửi.
export const blogSchema = z.object({
  title: z
    .string()
    .trim()
    .min(1, "Vui lòng nhập tiêu đề")
    .max(BLOG_TITLE_MAX, `Tiêu đề tối đa ${BLOG_TITLE_MAX} ký tự`),
  categoryId: z.string().min(1, "Vui lòng chọn danh mục"),
  content: z
    .string()
    .trim()
    .min(1, "Vui lòng nhập nội dung bài viết")
    .min(BLOG_CONTENT_MIN, `Nội dung tối thiểu ${BLOG_CONTENT_MIN} ký tự`),
});

export const CATEGORY_NAME_MAX = 100;

// Form tạo / sửa danh mục của admin, khớp CategoryRequest: tên tối đa 100 ký tự, thứ tự hiển thị
// là số nguyên không âm (BE dùng kiểu short nên tối đa 32767).
export const categorySchema = z.object({
  name: z
    .string()
    .trim()
    .min(1, "Vui lòng nhập tên danh mục")
    .max(CATEGORY_NAME_MAX, `Tên danh mục tối đa ${CATEGORY_NAME_MAX} ký tự`),
  type: z.enum(["FOOD_TYPE", "RECIPE_TYPE"]),
  displayOrder: z
    .string()
    .trim()
    .refine(
      (v) => v === "" || (/^\d{1,5}$/.test(v) && Number(v) <= 32767),
      "Thứ tự là số nguyên từ 0 đến 32767"
    ),
  active: z.boolean(),
});
