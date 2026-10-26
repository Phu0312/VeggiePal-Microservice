// Hàm thuần cho trang thực đơn: chuẩn hóa dữ liệu ai-service trả về và dựng payload gửi đi.

export const DAY_ORDER = [
  "MONDAY",
  "TUESDAY",
  "WEDNESDAY",
  "THURSDAY",
  "FRIDAY",
  "SATURDAY",
  "SUNDAY",
];

export const DAY_LABELS = {
  MONDAY: { short: "T2", long: "Thứ Hai" },
  TUESDAY: { short: "T3", long: "Thứ Ba" },
  WEDNESDAY: { short: "T4", long: "Thứ Tư" },
  THURSDAY: { short: "T5", long: "Thứ Năm" },
  FRIDAY: { short: "T6", long: "Thứ Sáu" },
  SATURDAY: { short: "T7", long: "Thứ Bảy" },
  SUNDAY: { short: "CN", long: "Chủ Nhật" },
};

// Thứ tự bữa trong ngày; BE chỉ trả 3 bữa này (chưa có bữa phụ).
export const MEAL_ORDER = ["BREAKFAST", "LUNCH", "DINNER"];

export const MEAL_LABELS = {
  BREAKFAST: "Bữa Sáng",
  LUNCH: "Bữa Trưa",
  DINNER: "Bữa Tối",
};

// BE không có giờ ăn, nên gán giờ gợi ý cố định theo loại bữa.
export const MEAL_TIMES = {
  BREAKFAST: "07:30",
  LUNCH: "12:15",
  DINNER: "19:00",
};

/** "Monday" / " monday " -> "MONDAY". BE không đảm bảo chữ hoa/thường của `day`. */
export function normalizeDay(day) {
  return String(day ?? "").trim().toUpperCase();
}

/** Thứ của một ngày (theo giờ máy người dùng) dưới dạng khóa như "MONDAY". */
export function dayKeyOf(date = new Date()) {
  // Date.getDay(): 0 = Chủ nhật. DAY_ORDER bắt đầu từ thứ Hai.
  return DAY_ORDER[(date.getDay() + 6) % 7];
}

function orderIndex(order, key) {
  const index = order.indexOf(key);
  return index === -1 ? order.length : index;
}

/** Các ngày của thực đơn theo thứ tự T2 -> CN (ngày lạ nằm cuối). Không đổi mảng gốc. */
export function sortedDays(plan) {
  const days = Array.isArray(plan?.plan?.days) ? plan.plan.days : [];
  return [...days].sort(
    (a, b) => orderIndex(DAY_ORDER, normalizeDay(a.day)) - orderIndex(DAY_ORDER, normalizeDay(b.day)),
  );
}

/** Các bữa của một ngày theo thứ tự sáng -> trưa -> tối. */
export function sortedMeals(day) {
  const meals = Array.isArray(day?.meals) ? day.meals : [];
  return [...meals].sort(
    (a, b) =>
      orderIndex(MEAL_ORDER, normalizeDay(a.mealType)) - orderIndex(MEAL_ORDER, normalizeDay(b.mealType)),
  );
}

export function dayLabel(day) {
  const key = normalizeDay(day?.day);
  return DAY_LABELS[key] ?? { short: key.slice(0, 2) || "?", long: String(day?.day ?? "") };
}

/** Nhãn bữa ăn tiếng Việt. */
export function mealLabel(mealType) {
  return MEAL_LABELS[normalizeDay(mealType)] ?? String(mealType ?? "");
}

export function mealTime(mealType) {
  return MEAL_TIMES[normalizeDay(mealType)] ?? "";
}

/** Số nguyên không âm làm tròn; undefined/NaN -> 0. */
export function toRounded(value) {
  const n = Number(value);
  return Number.isFinite(n) && n > 0 ? Math.round(n) : 0;
}

/**
 * Tỉ lệ năng lượng (%) của tinh bột / đạm / béo trong một ngày, tổng đúng 100.
 * Quy đổi theo năng lượng: đạm 4 kcal/g, tinh bột 4 kcal/g, béo 9 kcal/g.
 * Trả null khi chưa có dữ liệu (tổng bằng 0).
 */
export function macroPercentages(totals) {
  const energy = {
    carb: Math.max(0, Number(totals?.carbohydrate) || 0) * 4,
    protein: Math.max(0, Number(totals?.protein) || 0) * 4,
    fat: Math.max(0, Number(totals?.fat) || 0) * 9,
  };
  const sum = energy.carb + energy.protein + energy.fat;
  if (sum <= 0) return null;

  const keys = ["carb", "protein", "fat"];
  const exact = keys.map((key) => (energy[key] / sum) * 100);
  const result = exact.map(Math.floor);
  // Chia phần dư còn thiếu để đủ 100, ưu tiên phần thập phân lớn nhất.
  let missing = 100 - result.reduce((a, b) => a + b, 0);
  const byRemainder = exact
    .map((value, index) => ({ index, remainder: value - Math.floor(value) }))
    .sort((a, b) => b.remainder - a.remainder);
  for (const { index } of byRemainder) {
    if (missing <= 0) break;
    result[index] += 1;
    missing -= 1;
  }
  return { carb: result[0], protein: result[1], fat: result[2] };
}

// Nhãn + đơn vị của từng chất trong `targetDeviations` mà BE gắn vào ngày không đạt mục tiêu.
const TARGET_METRICS = [
  { key: "calories", label: "Năng lượng", unit: "kcal" },
  { key: "protein", label: "Đạm", unit: "g" },
  { key: "carbohydrate", label: "Tinh bột", unit: "g" },
  { key: "fat", label: "Chất béo", unit: "g" },
];

function formatAmount(value) {
  return Number(value).toLocaleString("vi-VN", { maximumFractionDigits: 1 });
}

/** Khoảng mục tiêu dạng chữ: "1.500–1.800 kcal", "≥ 80 g" hoặc "≤ 60 g". */
function describeRange(min, max, unit) {
  const hasMin = min != null && Number.isFinite(Number(min));
  const hasMax = max != null && Number.isFinite(Number(max));
  if (hasMin && hasMax) return `${formatAmount(min)}–${formatAmount(max)} ${unit}`;
  if (hasMin) return `≥ ${formatAmount(min)} ${unit}`;
  if (hasMax) return `≤ ${formatAmount(max)} ${unit}`;
  return "";
}

/**
 * Các chất mà ngày này lệch khỏi mục tiêu, lấy từ `day.targetDeviations`.
 * BE không từ chối thực đơn mà chỉ đánh dấu: `targetMet: false` + `targetDeviations: { protein: { actual, min?, max? } }`.
 * `targetMet` chỉ xét calo trong [minCalories, maxCalories] (không dung sai); `targetDeviations` liệt kê mọi chất nằm
 * ngoài khoảng, kể cả khi `targetMet` là true. FE chỉ cảnh báo khi `targetMet` không phải true, nên đạm / tinh bột /
 * béo lệch một mình (calo vẫn đạt) thì không bị coi là ngày lỡ mục tiêu.
 * Trả mảng { key, label, unit, actual, range } theo thứ tự năng lượng, đạm, tinh bột, béo; rỗng khi ngày đạt
 * mục tiêu calo, không đặt mục tiêu hoặc thực đơn cũ chưa có hai trường này.
 */
export function dayTargetDeviations(day) {
  return day?.targetMet === true ? [] : listDeviations(day);
}

/**
 * Ngược lại với dayTargetDeviations: các chất (đạm, tinh bột, béo) lệch khỏi khoảng mục tiêu trong khi calo của ngày
 * vẫn đạt (`targetMet === true`). Chỉ là lưu ý nhẹ, không tính là ngày lỡ mục tiêu. Cùng dạng mảng với
 * dayTargetDeviations; rỗng khi ngày không đạt calo (khi đó mọi chất lệch đã nằm trong cảnh báo chính) hoặc không lệch gì.
 */
export function dayMacroNotes(day) {
  return day?.targetMet === true ? listDeviations(day) : [];
}

function listDeviations(day) {
  const deviations = day?.targetDeviations;
  if (!deviations || typeof deviations !== "object") return [];

  return TARGET_METRICS.filter(({ key }) => deviations[key] && typeof deviations[key] === "object").map(
    ({ key, label, unit }) => {
      const { actual, min, max } = deviations[key];
      return { key, label, unit, actual: Number(actual) || 0, range: describeRange(min, max, unit) };
    },
  );
}

/** Số ngày của thực đơn không đạt mục tiêu dinh dưỡng. */
export function countMissedDays(plan) {
  return sortedDays(plan).filter((day) => dayTargetDeviations(day).length > 0).length;
}

// Bốn chất hiển thị trong các bảng so sánh (key khớp `nutritionTotals` của BE).
export const MACRO_ROWS = [
  { key: "calories", label: "Năng lượng", unit: "kcal" },
  { key: "protein", label: "Đạm", unit: "g" },
  { key: "carbohydrate", label: "Tinh bột", unit: "g" },
  { key: "fat", label: "Chất béo", unit: "g" },
];

// Các mức khẩu phần cho chọn khi sửa thủ công (BE chỉ cần > 0).
export const SERVING_OPTIONS = [0.5, 0.75, 1, 1.25, 1.5, 2];

/** 1.25 -> "×1,25"; 1 -> "×1". */
export function formatServing(value) {
  return `×${Number(value).toLocaleString("vi-VN", { maximumFractionDigits: 2 })}`;
}

/** Ngày có thứ `key` trong phần `plan` (có days[]), không phân biệt hoa thường. Không có thì null. */
export function findDayByKey(planBody, key) {
  const days = Array.isArray(planBody?.days) ? planBody.days : [];
  return days.find((day) => normalizeDay(day.day) === normalizeDay(key)) ?? null;
}

/**
 * Dựng `edits` gửi BE cho một bữa: đổi món thì REPLACE (kèm khẩu phần chọn, vì BE mặc định giữ khẩu phần cũ),
 * chỉ đổi khẩu phần thì UPDATE_SERVING. Không đổi gì thì trả mảng rỗng.
 */
export function buildMealEdits({ day, mealType, currentRecipeId, currentMultiplier = 1, recipeId, multiplier }) {
  if (recipeId !== currentRecipeId) {
    return [{ day, mealType, action: "REPLACE", recipeId, servingMultiplier: multiplier }];
  }
  if (Math.abs(multiplier - currentMultiplier) > 0.001) {
    return [{ day, mealType, action: "UPDATE_SERVING", servingMultiplier: multiplier }];
  }
  return [];
}

const TARGET_SUFFIX ={ calories: "Calories", protein: "Protein", carbohydrate: "Carbohydrate", fat: "Fat" };

/**
 * Các mốc mục tiêu (dailyNutritionTarget) thành dòng chữ cho từng chất, bỏ chất không đặt mốc nào.
 * Trả mảng { key, label, unit, range }, ví dụ { label: "Đạm", range: "≥ 80 g" }.
 */
export function targetRangeLines(target) {
  if (!target) return [];
  return TARGET_METRICS.map(({ key, label, unit }) => ({
    key,
    label,
    unit,
    range: describeRange(target[`min${TARGET_SUFFIX[key]}`], target[`max${TARGET_SUFFIX[key]}`], unit),
  })).filter((line) => line.range);
}

/**
 * Năng lượng / đạm / tinh bột / béo trung bình mỗi ngày của phần `plan` (có days[].nutritionTotals),
 * làm tròn số nguyên. Trả null khi chưa có ngày nào có nutritionTotals.
 */
export function averageDailyTotals(planBody) {
  const days = Array.isArray(planBody?.days) ? planBody.days.filter((day) => day?.nutritionTotals) : [];
  if (days.length === 0) return null;
  const average = (key) =>
    Math.round(days.reduce((sum, day) => sum + (Number(day.nutritionTotals[key]) || 0), 0) / days.length);
  return {
    calories: average("calories"),
    protein: average("protein"),
    carbohydrate: average("carbohydrate"),
    fat: average("fat"),
  };
}

// Các mốc mục tiêu dinh dưỡng mỗi ngày, đúng tên field của GenerateRequest.dailyNutritionTarget.
export const TARGET_FIELDS = [
  "minCalories",
  "maxCalories",
  "minProtein",
  "maxProtein",
  "minCarbohydrate",
  "maxCarbohydrate",
  "minFat",
  "maxFat",
];

// Số có dấu phân cách hàng nghìn: nhóm đúng 3 chữ số, nhóm đầu 1-3 chữ số không bắt đầu bằng 0 (nên "0,500" vẫn là 0,5).
const EN_GROUPED_NUMBER = /^[1-9]\d{0,2}(,\d{3})+(\.\d+)?$/; // 1,500 / 1,500.5
const VI_GROUPED_NUMBER = /^[1-9]\d{0,2}(\.\d{3})+(,\d+)?$/; // 1.500 / 1.500,5

/**
 * Chuỗi người dùng nhập -> số. Hiểu cả kiểu có dấu phân cách hàng nghìn ("1,500" / "1.500" -> 1500) lẫn dấu phẩy
 * thập phân kiểu Việt ("1500,5" / "1500.5" -> 1500,5). Chuỗi rỗng hoặc không phải số -> NaN.
 */
export function parseTargetNumber(text) {
  const clean = String(text ?? "").trim();
  if (clean === "") return Number.NaN;
  if (EN_GROUPED_NUMBER.test(clean)) return Number(clean.replaceAll(",", ""));
  if (VI_GROUPED_NUMBER.test(clean)) return Number(clean.replaceAll(".", "").replace(",", "."));
  return Number(clean.replace(",", "."));
}

/**
 * Dựng dailyNutritionTarget từ các ô nhập (chuỗi). Ô trống bị bỏ qua; không có ô nào thì
 * trả undefined để KHÔNG gửi mục tiêu riêng (BE tự tính theo hồ sơ khi tạo thực đơn).
 */
export function buildNutritionTarget(values) {
  const target = {};
  for (const field of TARGET_FIELDS) {
    const n = parseTargetNumber(values?.[field]);
    if (Number.isFinite(n)) target[field] = n;
  }
  return Object.keys(target).length > 0 ? target : undefined;
}

/** Hai mục tiêu (kết quả của buildNutritionTarget) có giống nhau không; undefined = không đặt mục tiêu riêng. */
export function sameTarget(a, b) {
  const left = a ?? {};
  const right = b ?? {};
  return TARGET_FIELDS.every((field) => left[field] === right[field]);
}

/**
 * Body cho POST /ai/meal-plans/:id/update-from-health. `customTarget` (mục tiêu tự đặt, thay hẳn mục tiêu BE
 * tính từ chỉ số sức khỏe) và `changeSummary` (ghi chú lưu vào lịch sử phiên bản) chỉ được gửi khi có.
 */
export function buildHealthUpdateBody({ confirm, customTarget, changeSummary }) {
  const body = { confirm: Boolean(confirm) };
  if (customTarget && Object.keys(customTarget).length > 0) body.customTarget = customTarget;
  const summary = String(changeSummary ?? "").trim();
  if (summary) body.changeSummary = summary;
  return body;
}

// Mục tiêu của thực đơn, giá trị khớp enum GoalType của BE. `label` cũng là mô tả mặc định gửi vào `healthGoal`.
export const GOAL_OPTIONS = [
  { value: "LOSE", label: "Giảm cân", hint: "Ăn ít hơn nhu cầu khoảng 15%" },
  { value: "MAINTAIN", label: "Duy trì", hint: "Ăn đúng nhu cầu mỗi ngày" },
  { value: "GAIN", label: "Tăng cân", hint: "Ăn nhiều hơn nhu cầu khoảng 15%" },
];

/** Nhãn tiếng Việt của goalType; thực đơn cũ chưa có goalType (null) hoặc giá trị lạ thì trả chuỗi rỗng. */
export function goalLabel(goalType) {
  return GOAL_OPTIONS.find((option) => option.value === goalType)?.label ?? "";
}

/**
 * Mô tả thêm nằm trong `goal` của một thực đơn: "Giảm cân: ăn thanh đạm" -> "ăn thanh đạm". Thực đơn cũ chưa có
 * goalType (hoặc `goal` không theo dạng trên) thì trả nguyên `goal`; rỗng khi không có mô tả thêm.
 */
export function planGoalNote(plan) {
  const goal = String(plan?.goal ?? "").trim();
  const label = goalLabel(plan?.goalType);
  if (!label) return goal;
  if (goal === label) return "";
  return goal.startsWith(`${label}: `) ? goal.slice(label.length + 2) : goal;
}

/** Mục tiêu của thực đơn trên một dòng: "Giảm cân · ăn thanh đạm", "Duy trì", hoặc nguyên `goal` với thực đơn cũ. */
export function planGoalSummary(plan) {
  const label = goalLabel(plan?.goalType);
  const note = planGoalNote(plan);
  if (!label) return note;
  return note ? `${label} · ${note}` : label;
}

// BE chỉ tự tính mục tiêu calo cho người từ 18 tuổi trở lên (lỗi 6021).
const ADULT_AGE = 18;

/**
 * Các trường hồ sơ BE cần để tự tính calo mà đang trống, theo tên field của `GET /users/me`
 * ("dateOfBirth" | "gender" | "activityLevel"). Chưa có hồ sơ thì trả mảng rỗng (chưa kết luận được).
 */
export function missingProfileFields(profile) {
  if (!profile) return [];
  return ["dateOfBirth", "gender", "activityLevel"].filter((field) => !profile[field]);
}

/**
 * `state` của liên kết sang `/profile/edit` khi hồ sơ thiếu thông tin cho thực đơn: trang hồ sơ dùng nó để mở sẵn và
 * làm nổi các ô còn thiếu, rồi cho người dùng quay lại thực đơn sau khi lưu (xem profile/utils/profileFixState.js).
 */
export function profileFixState(missingFields = []) {
  return { missingFields, returnTo: "/meal-planner", returnLabel: "Quay lại thực đơn" };
}

/**
 * Hồ sơ có đủ điều kiện để BE tự tính mục tiêu calo không (cùng điều kiện với lỗi 6020 / 6021 của BE):
 * "incomplete" khi thiếu ngày sinh / giới tính / mức vận động, "underage" khi dưới 18 tuổi, null khi ổn
 * (hoặc chưa có hồ sơ để kiểm tra: khi đó để BE quyết định). `profile.dateOfBirth` dạng "YYYY-MM-DD".
 */
export function profileTargetIssue(profile, today = new Date()) {
  if (!profile) return null;
  if (!profile.dateOfBirth || !profile.gender || !profile.activityLevel) return "incomplete";

  const [year, month, day] = String(profile.dateOfBirth).slice(0, 10).split("-").map(Number);
  if (![year, month, day].every(Number.isFinite)) return "incomplete";

  const hadBirthday = today.getMonth() + 1 > month || (today.getMonth() + 1 === month && today.getDate() >= day);
  const age = today.getFullYear() - year - (hadBirthday ? 0 : 1);
  return age < ADULT_AGE ? "underage" : null;
}

/**
 * `healthGoal` gửi BE (bắt buộc không rỗng): nhãn của mục tiêu, kèm mô tả thêm của người dùng nếu có,
 * ví dụ "Giảm cân: ăn thanh đạm".
 */
export function buildHealthGoalText(goalType, note) {
  const label = goalLabel(goalType);
  const extra = String(note ?? "").trim();
  return extra ? `${label}: ${extra}` : label;
}

/**
 * Payload cho POST /ai/meal-plans từ giá trị form + nguyên liệu/khẩu vị đã chọn.
 * `healthNote` là mô tả thêm (tùy chọn). Không có ô mục tiêu nào được điền thì không gửi dailyNutritionTarget,
 * BE sẽ tự tính theo hồ sơ + goalType.
 */
export function buildGeneratePayload({ name, goalType, healthNote, preferences, ingredients, target }) {
  const payload = {
    name: name.trim(),
    goalType,
    healthGoal: buildHealthGoalText(goalType, healthNote),
    preferences: preferences.map((p) => p.trim()).filter(Boolean),
    availableIngredients: ingredients.map((i) => i.trim()).filter(Boolean),
  };
  const dailyNutritionTarget = buildNutritionTarget(target);
  if (dailyNutritionTarget) payload.dailyNutritionTarget = dailyNutritionTarget;
  return payload;
}

/** "dd/MM" của một ngày, ví dụ "07/10". */
export function formatDayMonth(date) {
  const day = String(date.getDate()).padStart(2, "0");
  const month = String(date.getMonth() + 1).padStart(2, "0");
  return `${day}/${month}`;
}

/** Thứ Hai của tuần (T2 -> CN) chứa `date`, lúc 00:00 giờ máy người dùng. */
export function weekStart(date = new Date()) {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate() - ((date.getDay() + 6) % 7));
}

/**
 * Tên gợi ý cho thực đơn mới: cả tuần T2 -> CN chứa ngày tạo, ví dụ tạo ngày 17/10 -> "Thực đơn 12/10 - 18/10".
 * BE chỉ lưu thứ (MONDAY..SUNDAY) chứ không lưu ngày cụ thể, nên lấy tuần lịch là khớp nhất với dữ liệu.
 */
export function defaultPlanName(date = new Date()) {
  const start = weekStart(date);
  const end = new Date(start.getFullYear(), start.getMonth(), start.getDate() + 6);
  return `Thực đơn ${formatDayMonth(start)} - ${formatDayMonth(end)}`;
}

/**
 * Ngày cụ thể của một thứ trong thực đơn, tính theo tuần chứa ngày tạo (`plan.createdAt`).
 * Trả null khi thiếu createdAt / thứ lạ.
 */
export function planDayDate(plan, dayKey) {
  const index = DAY_ORDER.indexOf(normalizeDay(dayKey));
  const created = new Date(plan?.createdAt);
  if (index === -1 || Number.isNaN(created.getTime())) return null;
  const start = weekStart(created);
  return new Date(start.getFullYear(), start.getMonth(), start.getDate() + index);
}

/** Hai ngày có cùng ngày-tháng-năm (bỏ qua giờ) không. */
export function isSameDate(a, b) {
  return (
    a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate()
  );
}

/** Đặt cờ yêu thích của một thực đơn trong danh sách đã cache (theo id); thực đơn khác giữ nguyên. */
export function setPlanFavorite(list, planId, favorite) {
  if (!Array.isArray(list)) return list;
  return list.map((plan) => (plan.id === planId ? { ...plan, isFavorite: favorite } : plan));
}

/** "21/10/2026 15:06" từ chuỗi ISO của BE; chuỗi rỗng khi không đọc được. */
export function formatDateTime(iso) {
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return "";
  return date.toLocaleString("vi-VN", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

/** Thay một thực đơn trong danh sách đã cache bằng bản mới (theo id). */
export function replacePlanInList(list, updated) {
  if (!Array.isArray(list)) return list;
  return list.map((plan) => (plan.id === updated.id ? updated : plan));
}
