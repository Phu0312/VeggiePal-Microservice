import { unwrapBlogResponse as unwrap } from "@/features/blog/api/blogErrors";
import apiClient from "@/shared/api/apiClient";

/**
 * Category APIs (blog-service qua api-gateway).
 * GET công khai, không cần token:
 *   GET /categories?type=&activeOnly=
 *   GET /categories/:id
 * Chỉ ADMIN:
 *   POST   /categories       body { name, type?, parentId?, displayOrder?, active? }
 *   PUT    /categories/:id   body { name, displayOrder?, active? } (không đổi được cha và loại)
 *   DELETE /categories/:id   (lỗi 3005 nếu còn bài viết hoặc danh mục con)
 *
 * Category: { id, parentId, type, name, displayOrder, active, children: Category[] }
 * type: "FOOD_TYPE" | "RECIPE_TYPE"
 */

/**
 * GET /categories — cây danh mục 2 cấp (cha có `children`).
 * - type: lọc theo loại, bỏ trống để lấy tất cả
 * - activeOnly: mặc định true (chỉ danh mục đang hiển thị); trang quản trị truyền false
 */
export async function getCategories({ type, activeOnly = true } = {}) {
  const res = await apiClient.get("/categories", {
    params: { type: type || undefined, activeOnly },
  });
  return unwrap(res, "Không lấy được danh mục") ?? [];
}

/** GET /categories/:id */
export async function getCategory(id) {
  const res = await apiClient.get(`/categories/${id}`);
  return unwrap(res, "Không lấy được danh mục");
}

// ---- Quản trị danh mục (chỉ ADMIN) -----------------------------------------------------------
// Cây tối đa 2 cấp. Danh mục gốc bắt buộc có `type`; danh mục con gửi parentId và tự kế thừa loại.

/** POST /categories */
export async function createCategory(payload) {
  const res = await apiClient.post("/categories", payload);
  return unwrap(res, "Tạo danh mục thất bại");
}

/** PUT /categories/:id — chỉ đổi được tên, thứ tự hiển thị và trạng thái. */
export async function updateCategory(id, payload) {
  const res = await apiClient.put(`/categories/${id}`, payload);
  return unwrap(res, "Cập nhật danh mục thất bại");
}

/** DELETE /categories/:id — chỉ xóa được danh mục không còn bài viết và không có danh mục con. */
export async function deleteCategory(id) {
  const res = await apiClient.delete(`/categories/${id}`);
  unwrap(res, "Xóa danh mục thất bại");
}
