// Đọc `state` mà nơi khác (vd trang thực đơn) gắn vào liên kết sang `/profile/edit` khi cần người dùng bổ sung hồ sơ.
// Chỉ nhận giá trị hợp lệ vì `location.state` có thể bị sửa tay trong lịch sử trình duyệt.

// Các trường hồ sơ được làm nổi (tên field của GET /users/me).
export const HIGHLIGHTABLE_PROFILE_FIELDS = ["dateOfBirth", "gender", "activityLevel"];

/**
 * { missingFields: string[], returnTo: string | null, returnLabel: string }
 * - missingFields: trường hồ sơ cần bổ sung (đã lọc theo HIGHLIGHTABLE_PROFILE_FIELDS).
 * - returnTo: đường dẫn nội bộ để quay lại sau khi lưu; null nếu không có hoặc không phải đường dẫn nội bộ.
 */
export function readProfileFixState(state) {
  const missingFields = Array.isArray(state?.missingFields)
    ? state.missingFields.filter((field) => HIGHLIGHTABLE_PROFILE_FIELDS.includes(field))
    : [];
  const returnTo =
    typeof state?.returnTo === "string" && state.returnTo.startsWith("/") && !state.returnTo.startsWith("//")
      ? state.returnTo
      : null;
  const returnLabel = typeof state?.returnLabel === "string" && state.returnLabel ? state.returnLabel : "Quay lại";
  return { missingFields, returnTo, returnLabel };
}
