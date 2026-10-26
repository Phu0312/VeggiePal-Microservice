import { AVATAR_ALLOWED_TYPES, AVATAR_MAX_BYTES } from "@/features/profile/utils/editProfileConstants";

// Phân loại BMI theo ngưỡng của HealthRecordSection; kèm dải chuẩn tương ứng với giá trị thật.
export function bmiInfo(bmi) {
  const n = Number(bmi);
  if (bmi == null || !n || Number.isNaN(n)) {
    return {
      text: "—",
      badge: null,
      range: "Chưa có dữ liệu",
      valueClass: "text-stone-400",
      textClass: "text-stone-400",
      badgeClass: "",
    };
  }
  if (n < 18.5) {
    return {
      text: "Thiếu cân",
      badge: "Cần bổ sung",
      range: "Dưới 18.5",
      valueClass: "text-sky-700 dark:text-sky-400",
      textClass: "text-sky-600 dark:text-sky-300",
      badgeClass: "bg-sky-100 dark:bg-sky-900/60 text-sky-700 dark:text-sky-300",
    };
  }
  if (n < 23) {
    return {
      text: "Bình thường",
      badge: "Lý tưởng",
      range: "18.5 - 22.9",
      valueClass: "text-emerald-700 dark:text-emerald-400",
      textClass: "text-emerald-600 dark:text-emerald-300",
      badgeClass: "bg-emerald-100 dark:bg-emerald-900/60 text-emerald-700 dark:text-emerald-300",
    };
  }
  if (n < 25) {
    return {
      text: "Thừa cân",
      badge: "Cần chú ý",
      range: "23 - 24.9",
      valueClass: "text-amber-700 dark:text-amber-400",
      textClass: "text-amber-600 dark:text-amber-300",
      badgeClass: "bg-amber-100 dark:bg-amber-900/60 text-amber-700 dark:text-amber-300",
    };
  }
  return {
    text: "Béo phì",
    badge: "Cần giảm cân",
    range: "Từ 25 trở lên",
    valueClass: "text-rose-700 dark:text-rose-400",
    textClass: "text-rose-600 dark:text-rose-300",
    badgeClass: "bg-rose-100 dark:bg-rose-900/60 text-rose-700 dark:text-rose-300",
  };
}

export function formatDt(iso) {
  if (!iso) return "—";
  try {
    return new Date(iso).toLocaleString("vi-VN", {
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  } catch {
    return "—";
  }
}

// Nhóm danh sách dị ứng theo `category` của BE (giữ thứ tự BE trả về) -> [[category, items]].
export function groupAllergens(allergens) {
  const map = new Map();
  for (const a of allergens ?? []) {
    const key = a.category || "OTHER";
    if (!map.has(key)) map.set(key, []);
    map.get(key).push(a);
  }
  return [...map.entries()];
}

// Trả về thông báo lỗi tiếng Việt nếu file avatar không hợp lệ, ngược lại trả chuỗi rỗng.
export function validateAvatarFile(file) {
  if (!AVATAR_ALLOWED_TYPES.includes(file.type)) return "Chỉ chấp nhận JPEG, PNG hoặc WEBP";
  if (file.size > AVATAR_MAX_BYTES) return "Ảnh tối đa 2MB";
  return "";
}
