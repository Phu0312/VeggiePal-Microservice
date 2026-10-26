import apiClient from "@/shared/api/apiClient";

/**
 * Ingredient APIs (recipe-service qua api-gateway).
 * GET công khai, không cần token (CHỈ trả nguyên liệu đang hoạt động, kể cả trang quản trị):
 *   GET /ingredients?keyword=&vegan=&allergen=&page=&size=
 *   GET /ingredients/:id
 * Chỉ ADMIN:
 *   POST   /ingredients       body IngredientRequest
 *   PUT    /ingredients/:id
 *   DELETE /ingredients/:id   (xóa hẳn)
 *
 * Ingredient: { id, name, description, caloriesPer100g, proteinPer100g, carbsPer100g,
 *   fatPer100g, fiberPer100g, vegan, allergen, imageUrl, active, createdAt, updatedAt }
 * Page: { content, page, size, totalElements, totalPages, first, last }
 */

const EMPTY_PAGE = {
  content: [],
  page: 0,
  size: 10,
  totalElements: 0,
  totalPages: 0,
  first: true,
  last: true,
};

// BE trả message tiếng Anh theo ErrorCode; các lỗi admin hay gặp khi lưu nguyên liệu được đổi
// sang tiếng Việt theo `code`. Lỗi lạ dùng message của BE.
const VI_MESSAGES = {
  1001: "Dữ liệu không hợp lệ, vui lòng kiểm tra lại các trường đã nhập",
  1008: "Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại",
  1009: "Bạn không có quyền thực hiện thao tác này",
  4000: "Vui lòng nhập tên nguyên liệu",
  4001: "Tên nguyên liệu tối đa 150 ký tự",
  4002: "Mô tả tối đa 1000 ký tự",
  4003: "Nguyên liệu không tồn tại",
  4004: "Đã có nguyên liệu cùng tên",
  4005: "Vui lòng nhập năng lượng",
  4006: "Vui lòng nhập lượng đạm",
  4007: "Vui lòng nhập lượng tinh bột",
  4008: "Vui lòng nhập lượng béo",
  4009: "Giá trị dinh dưỡng phải từ 0 trở lên",
};

function unwrap(res, fallbackMessage) {
  if (res.status >= 400) {
    throw new Error(VI_MESSAGES[res.data?.code] ?? res.data?.message ?? fallbackMessage);
  }
  return res.data?.result;
}

/**
 * GET /ingredients — nguyên liệu đang hoạt động, có phân trang.
 * - keyword: tìm theo tên ("" coi như không lọc)
 * - vegan / allergen: true | false để lọc, undefined để bỏ qua
 */
export async function getIngredients({
  keyword,
  vegan,
  allergen,
  page = 0,
  size = 10,
} = {}) {
  const res = await apiClient.get("/ingredients", {
    params: {
      keyword: keyword?.trim() || undefined,
      vegan,
      allergen,
      page,
      size,
    },
  });
  return unwrap(res, "Không lấy được danh sách nguyên liệu") ?? EMPTY_PAGE;
}

/** GET /ingredients/:id */
export async function getIngredient(id) {
  const res = await apiClient.get(`/ingredients/${id}`);
  return unwrap(res, "Không lấy được thông tin nguyên liệu");
}

// ---- Quản trị nguyên liệu (chỉ ADMIN) --------------------------------------------------------
// IngredientRequest: { name, description?, caloriesPer100g, proteinPer100g, carbsPer100g,
//   fatPer100g, fiberPer100g?, vegan?, allergen?, active? }. Tên không được trùng (không phân biệt
//   hoa thường và dấu). Cột giới hạn: tên 150, mô tả 1000 ký tự.

/** POST /ingredients */
export async function createIngredient(payload) {
  const res = await apiClient.post("/ingredients", payload);
  return unwrap(res, "Tạo nguyên liệu thất bại");
}

/** PUT /ingredients/:id */
export async function updateIngredient(id, payload) {
  const res = await apiClient.put(`/ingredients/${id}`, payload);
  return unwrap(res, "Cập nhật nguyên liệu thất bại");
}

/**
 * DELETE /ingredients/:id — xóa hẳn. Nguyên liệu đang nằm trong công thức nào đó sẽ bị ràng buộc
 * khóa ngoại và BE trả lỗi 500 chung chung, nên lỗi từ server được diễn giải lại cho admin.
 */
export async function deleteIngredient(id) {
  const res = await apiClient.delete(`/ingredients/${id}`);
  if (res.status >= 500) {
    throw new Error(
      "Không xóa được nguyên liệu, có thể nó đang được dùng trong công thức. Hãy tắt “Đang sử dụng” để ẩn thay vì xóa."
    );
  }
  unwrap(res, "Xóa nguyên liệu thất bại");
}
