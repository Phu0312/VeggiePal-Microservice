// Hằng số dùng chung cho các component của trang chỉnh sửa hồ sơ.
// Gom vào một chỗ để component không phải chứa chuỗi/class lặp lại.

// Nhãn + mô tả tiếng Việt cho từng nhóm `category` mà BE trả về (enum AllergenCategory).
export const ALLERGY_CATEGORY_META = {
  GRAIN: { name: "Ngũ cốc & Tinh bột", note: "Chọn các loại ngũ cốc gây mẫn cảm hoặc dị ứng:" },
  LEGUME: { name: "Các loại Đậu & Chế phẩm", note: "Tùy chọn đậu nành, lạc/đậu phộng và đậu khác:" },
  NUT_SEED: { name: "Hạt dinh dưỡng & Quả hạch", note: "Các loại hạt khô thường gây kích ứng:" },
  VEGETABLE: { name: "Rau củ", note: "Rau củ tính hàn hoặc nhạy cảm:" },
  FRUIT: { name: "Trái cây", note: "Các loại trái cây có thể gây dị ứng:" },
  MUSHROOM: { name: "Nấm & Nấm men", note: "Các loại nấm mỡ, nấm men bia:" },
  SPICE: { name: "Gia vị", note: "Các loại gia vị có thể gây kích ứng:" },
  ADDITIVE: { name: "Phụ gia thực phẩm", note: "Các phụ gia cần tránh trong thực đơn:" },
};
export const OTHER_CATEGORY_META = { name: "Khác", note: "Các thành phần khác cần tránh:" };

// Giới tính và mức độ vận động (enum Gender / ActivityLevel của identity-service). BE dùng hai trường này cùng ngày
// sinh để tính nhu cầu calo khi lên thực đơn.
export const GENDER_OPTIONS = [
  { value: "MALE", label: "Nam" },
  { value: "FEMALE", label: "Nữ" },
  { value: "OTHER", label: "Khác" },
];
// Nhãn giữ ngắn (tối đa khoảng 34 ký tự) để hiện đủ trong ô chọn của form chỉ số sức khỏe mà không bị cắt.
export const ACTIVITY_LEVEL_OPTIONS = [
  { value: "SEDENTARY", label: "Ít vận động (ngồi nhiều)" },
  { value: "LIGHT", label: "Vận động nhẹ (1–3 buổi/tuần)" },
  { value: "MODERATE", label: "Vận động vừa (3–5 buổi/tuần)" },
  { value: "ACTIVE", label: "Vận động nhiều (6–7 buổi/tuần)" },
  { value: "VERY_ACTIVE", label: "Vận động rất nhiều (lao động nặng)" },
];

// Ràng buộc ảnh đại diện (khớp BE: JPEG/PNG/WEBP, tối đa 2MB).
export const AVATAR_ALLOWED_TYPES = ["image/jpeg", "image/png", "image/webp"];
export const AVATAR_MAX_BYTES = 2 * 1024 * 1024;

// Class dùng lặp lại (dùng token chuẩn của VeggiePal).
export const cardClass =
  "rounded-3xl border border-border bg-card shadow-sm";
export const accordionHeaderClass =
  "flex w-full items-center justify-between p-4.5 text-left hover:bg-surface/50 transition-colors";
export const accordionBodyClass =
  "p-4.5 pt-1 border-t border-border space-y-3.5 text-xs";
export const iconBoxClass =
  "flex h-8 w-8 items-center justify-center rounded-xl bg-brand-soft text-brand";
export const labelClass = "block font-semibold text-body mb-1.5";
export const inputClass =
  "w-full rounded-2xl border border-border bg-surface px-3.5 py-2.5 text-xs text-ink focus:outline-none focus:border-brand aria-[invalid=true]:border-destructive/50";
export const healthInputClass =
  "w-full rounded-2xl border border-border bg-surface px-3.5 py-2 text-xs text-ink focus:outline-none focus:border-brand aria-[invalid=true]:border-destructive/50";
export const errorTextClass = "mt-1 block text-[11px] text-destructive";
export const errorBoxClass = "rounded-xl bg-destructive/10 px-3 py-2 text-xs text-destructive";
export const successBoxClass =
  "rounded-xl bg-brand-soft px-3 py-2 text-xs text-brand font-medium";
