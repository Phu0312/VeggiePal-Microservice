// Định dạng dữ liệu công thức để hiển thị. BE trả số lượng dạng BigDecimal ("200.00") và đơn vị IN HOA ("GRAM").

/** "200.00" -> "200", "1.50" -> "1,5", "0.25" -> "0,25" (tối đa 2 số lẻ, theo kiểu Việt Nam). */
export function formatQuantity(quantity) {
  const amount = Number(quantity);
  if (!Number.isFinite(amount)) return "";
  return amount.toLocaleString("vi-VN", { maximumFractionDigits: 2 });
}

/** "GRAM" -> "gram": chữ thường dễ đọc hơn chữ in hoa BE lưu. */
export function formatUnit(unit) {
  return String(unit ?? "").trim().toLowerCase();
}

/** Nguyên liệu dạng một dòng: "200 gram" (thiếu đơn vị thì chỉ có số lượng). */
export function formatIngredientAmount(item) {
  return [formatQuantity(item?.quantity), formatUnit(item?.unit)].filter(Boolean).join(" ");
}

/** Các bước làm theo thứ tự `stepNumber` (BE có thể trả không đúng thứ tự). Không đổi mảng gốc. */
export function sortSteps(steps) {
  return [...(steps ?? [])].sort((a, b) => (a.stepNumber ?? 0) - (b.stepNumber ?? 0));
}
