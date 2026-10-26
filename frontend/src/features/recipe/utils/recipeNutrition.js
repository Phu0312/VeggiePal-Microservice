// BE không trả kcal / đạm của cả công thức, nhưng mỗi nguyên liệu trong `recipe.ingredients[]` đã kèm sẵn
// dinh dưỡng trên 100g (caloriesPer100g, proteinPer100g, carbsPer100g, fatPer100g) -> FE chỉ cần cộng lại,
// không phải gọi thêm GET /ingredients/:id cho từng nguyên liệu.

// Hệ số quy đổi về gram. BE lưu đơn vị IN HOA và chỉ quy đổi được các đơn vị khối lượng; ml, muỗng, quả...
// cần biết khối lượng riêng của nguyên liệu nên FE không tự suy ra được.
const GRAMS_PER_UNIT = {
  G: 1,
  GR: 1,
  GAM: 1,
  GRAM: 1,
  GRAMS: 1,
  KG: 1000,
  KILO: 1000,
  KILOGRAM: 1000,
  KILOGRAMS: 1000,
  MG: 0.001,
  MILLIGRAM: 0.001,
  MILLIGRAMS: 0.001,
};

// Tên dễ đọc cho các đơn vị không quy đổi được (dùng trong gợi ý "chưa tính được dinh dưỡng").
const UNIT_LABELS = {
  TBSP: "muỗng canh",
  TABLESPOON: "muỗng canh",
  TSP: "muỗng cà phê",
  TEASPOON: "muỗng cà phê",
  PIECE: "quả / củ / miếng",
  PIECES: "quả / củ / miếng",
  PCS: "quả / củ / miếng",
};

function gramFactor(unit) {
  return GRAMS_PER_UNIT[String(unit ?? "").trim().toUpperCase()] ?? null;
}

/** Số gram của một nguyên liệu trong công thức; null nếu không quy đổi được. */
export function toGrams(quantity, unit) {
  const factor = gramFactor(unit);
  const amount = Number(quantity);
  if (factor == null || !Number.isFinite(amount) || amount <= 0) return null;
  return amount * factor;
}

/** Đơn vị này có quy đổi được ra gram (để tính kcal) không: gram, kg, mg. */
export function isGramUnit(unit) {
  return gramFactor(unit) !== null;
}

const round1 = (value) => Math.round(value * 10) / 10;

function hasNutritionData(item) {
  return [item.caloriesPer100g, item.proteinPer100g, item.carbsPer100g, item.fatPer100g].every(
    (value) => value != null && Number.isFinite(Number(value)),
  );
}

/**
 * Dinh dưỡng MỖI KHẨU PHẦN của công thức: { kcal, protein, carbs, fat } (kcal làm tròn, còn lại 1 số lẻ).
 * Dữ liệu lấy từ chính `recipe.ingredients[]` do BE trả.
 * Trả null nếu có bất kỳ nguyên liệu nào chưa tính được (thiếu dữ liệu hoặc đơn vị không quy đổi được),
 * vì cộng thiếu sẽ ra con số thấp hơn thực tế và gây hiểu nhầm. Lý do xem `nutritionGapHint`.
 */
export function calcRecipeNutrition(recipe) {
  const items = recipe?.ingredients ?? [];
  if (items.length === 0) return null;

  let kcal = 0;
  let protein = 0;
  let carbs = 0;
  let fat = 0;
  for (const item of items) {
    const grams = toGrams(item.quantity, item.unit);
    if (grams == null || !hasNutritionData(item)) return null;

    const per100g = grams / 100;
    kcal += per100g * Number(item.caloriesPer100g);
    protein += per100g * Number(item.proteinPer100g);
    carbs += per100g * Number(item.carbsPer100g);
    fat += per100g * Number(item.fatPer100g);
  }

  const servings = recipe.servings > 0 ? recipe.servings : 1;
  return {
    kcal: Math.round(kcal / servings),
    protein: round1(protein / servings),
    carbs: round1(carbs / servings),
    fat: round1(fat / servings),
  };
}

/**
 * Lý do chưa tính được dinh dưỡng vì đơn vị: liệt kê các đơn vị không quy đổi được ra gram.
 * Trả null nếu mọi nguyên liệu đều quy đổi được (khi đó nếu vẫn không tính được là do thiếu dữ liệu khác).
 */
export function nutritionGapHint(recipe) {
  const units = new Set();
  for (const item of recipe?.ingredients ?? []) {
    if (gramFactor(item.unit) !== null) continue;
    const raw = String(item.unit ?? "").trim();
    units.add(UNIT_LABELS[raw.toUpperCase()] ?? (raw.toLowerCase() || "đơn vị khác"));
  }
  if (units.size === 0) return null;
  return `Chưa tính được dinh dưỡng vì có nguyên liệu tính bằng ${[...units].join(", ")} (hiện chỉ quy đổi được gram, kg, mg).`;
}

/** Tổng thời gian chuẩn bị + nấu (phút); 0 nếu BE không có dữ liệu. */
export function totalMinutes(recipe) {
  return (recipe?.prepTime ?? 0) + (recipe?.cookTime ?? 0);
}
