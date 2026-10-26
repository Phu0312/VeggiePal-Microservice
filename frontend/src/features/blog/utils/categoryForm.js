// Chuyển đổi giữa dữ liệu form danh mục và CategoryRequest / CategoryResponse của BE.

export const CATEGORY_TYPE_OPTIONS = [
  { value: "FOOD_TYPE", label: "Loại món ăn" },
  { value: "RECIPE_TYPE", label: "Loại công thức" },
];

export const categoryTypeLabel = (type) =>
  CATEGORY_TYPE_OPTIONS.find((o) => o.value === type)?.label ?? type;

export function emptyCategoryForm(type = "FOOD_TYPE") {
  return { name: "", type, displayOrder: "", active: true };
}

/** CategoryResponse -> giá trị ban đầu của form sửa. */
export function categoryToFormValues(category) {
  return {
    name: category.name ?? "",
    type: category.type,
    displayOrder: category.displayOrder == null ? "" : String(category.displayOrder),
    active: category.active ?? true,
  };
}

/**
 * Giá trị form (đã qua categorySchema) -> CategoryRequest.
 * - tạo danh mục gốc: gửi `type` (BE bắt buộc); không gửi parentId
 * - tạo danh mục con: gửi parentId, không gửi type (con luôn kế thừa loại của cha)
 * - sửa: chỉ gửi name / displayOrder / active (BE không cho đổi cha và loại)
 * displayOrder để trống thì không gửi để BE giữ giá trị hiện tại (mặc định 0 khi tạo).
 */
export function formValuesToCategoryPayload(values, { parentId, isEdit } = {}) {
  const payload = {
    name: values.name.trim(),
    active: values.active,
  };
  if (values.displayOrder.trim() !== "") payload.displayOrder = Number(values.displayOrder);
  if (!isEdit) {
    if (parentId) payload.parentId = parentId;
    else payload.type = values.type;
  }
  return payload;
}
