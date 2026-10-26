import { buildHealthUpdateBody } from "@/features/meal-planner/utils/mealPlan";
import apiClient from "@/shared/api/apiClient";

/**
 * Meal plan APIs (ai-service qua api-gateway). Tất cả cần đăng nhập.
 * FE gọi `/ai/...` vì baseURL đã là `.../api` (gateway có route /api/ai/** -> /ai/**).
 *   POST /ai/meal-plans              tạo thực đơn 7 ngày (gọi LLM nên chậm, có thể vài chục giây)
 *   GET  /ai/meal-plans              các thực đơn đã lưu (kèm đủ nội dung), mới nhất trước
 *   POST /ai/meal-plans/:id/replace  đổi một món, trả về cả thực đơn sau khi cập nhật
 *   POST   /ai/meal-plans/:id/favorite  thêm cả thực đơn vào yêu thích (yêu thích theo thực đơn, không theo món)
 *   DELETE /ai/meal-plans/:id/favorite  bỏ yêu thích
 *   POST   /ai/meal-plans/:id/update-from-health  tính lại mục tiêu dinh dưỡng theo chỉ số sức khỏe mới nhất
 *     rồi co giãn lại khẩu phần: confirm=false chỉ xem trước (không lưu), confirm=true lưu bản mới
 *     (BE giữ bản cũ trong lịch sử phiên bản). Trả { confirmed, message, recalculatedTarget, currentPlan,
 *     proposedPlan, updatedMealPlan }; currentPlan / proposedPlan là phần `plan` (có days[].nutritionTotals).
 *   POST /ai/meal-plans/:id/preview-edit  xem trước chỉnh sửa thủ công (không lưu), trả { preview: true, plan }
 *   POST /ai/meal-plans/:id/edit          lưu chỉnh sửa thủ công, trả { preview: false, plan, updatedMealPlan }
 *     body { changeSummary?, edits: [{ day, mealType, action: "REPLACE" | "UPDATE_SERVING", recipeId?, servingMultiplier? }] }
 *     BE tính lại dinh dưỡng từng bữa + tổng ngày + targetMet; chỉ nhận món chay, không chứa dị ứng của người dùng
 *     (6018 / 6019). Bản trước được lưu vào lịch sử phiên bản.
 *   GET /ai/meal-plans/:id                    một thực đơn của tôi (cùng dạng MealPlan trong danh sách)
 *   GET /ai/meal-plans/favorites?page&size    thực đơn yêu thích, mới yêu thích trước: PageResponse { content, page, size,
 *     totalElements, totalPages, first, last } (size tối đa 100)
 *   GET /ai/meal-plans/favorites/:id          một thực đơn yêu thích (6015 khi thực đơn chưa được yêu thích)
 *   GET /ai/meal-plans/:id/versions/:version  một phiên bản cũ (6017 khi không có số phiên bản đó)
 *   GET /ai/meal-plans/:id/versions  các bản cũ đã được thay thế, mới nhất trước:
 *     [{ id, mealPlanId, version, name, goal, plan, changeSummary, createdAt }]. Mỗi lần cập nhật theo sức khỏe hoặc
 *     sửa thủ công, BE lưu bản trước đó ở đây (đổi món bằng AI `/replace` thì không tạo phiên bản). Chưa có API khôi phục.
 *
 *   GET /ai/meal-plans/nutrition-target?goalType=  mục tiêu calo / macro BE tính từ hồ sơ (xem getNutritionTarget)
 *
 * MealPlan: { id, name, goal, goalType, createdAt, updatedAt, version, isFavorite, plan: {
 *   days: [{ day: "MONDAY", meals: [{ mealType: "BREAKFAST"|"LUNCH"|"DINNER", recipeId, note?,
 *     servingMultiplier?, nutrition: { calories, protein, carbohydrate, fat } }], nutritionTotals: { ... },
 *     targetMet?: boolean, targetDeviations?: { calories|protein|carbohydrate|fat: { actual, min?, max? } } }],
 *   constraints: { preferences, availableIngredients, allergies, healthRecord, dailyNutritionTarget } } }
 * nutrition do BE cộng từ nguyên liệu (không phải AI tự bịa) và ĐÃ nhân `servingMultiplier`.
 * servingMultiplier (0.75 - 2.0) chỉ có khi BE co giãn khẩu phần để calo từng bữa chạm ngân sách của bữa đó.
 * goalType ("LOSE" | "MAINTAIN" | "GAIN") là null với thực đơn tạo trước khi BE có trường này.
 * BE luôn trả đủ 7 ngày × 3 bữa; `day` là "MONDAY".."SUNDAY" (vẫn chuẩn hóa ở utils/mealPlan.js).
 * Nếu AI lỗi, BE tự lập thực đơn bằng thuật toán cố định nên FE không phân biệt được hai trường hợp.
 * Mọi thực đơn mới đều có mục tiêu (FE gửi dailyNutritionTarget hoặc BE tự tính theo goalType). Một ngày có calo
 * ngoài [minCalories, maxCalories] (không còn dung sai) thì BE KHÔNG báo lỗi, vẫn trả thực đơn và đánh dấu ngày
 * đó bằng targetMet=false (targetMet chỉ xét calo); targetDeviations liệt kê mọi chất nằm ngoài khoảng, kể cả khi
 * targetMet=true (xem utils/mealPlan.js: dayTargetDeviations).
 * Lỗi cần xử lý riêng: 6010 (chưa có chỉ số sức khỏe), 6011 (không còn món phù hợp), 6020 (hồ sơ thiếu ngày sinh /
 * giới tính / mức vận động) và 6021 (dưới 18 tuổi); hai lỗi sau chỉ có khi BE tự tính mục tiêu và không tốn lượt.
 * Meal chỉ có recipeId, tên/ảnh món lấy qua GET /recipes/:id.
 */

// Tạo thực đơn gọi LLM (đọc tối đa 45s, thử lại 2 lần) nên cho chờ lâu hơn mặc định.
const CREATE_TIMEOUT_MS = 120_000;

const EMPTY_PAGE = { content: [], page: 0, size: 0, totalElements: 0, totalPages: 0, first: true, last: true };

// ai-service dùng dải mã 60xx. Message gốc của BE là tiếng Anh nên đổi sang tiếng Việt theo `code`.
const VI_MESSAGES = {
  6000: "Thông tin chưa hợp lệ, vui lòng kiểm tra lại các mục đã nhập (ví dụ mục tiêu dinh dưỡng có mức tối thiểu lớn hơn tối đa)",
  6001: "Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại",
  6002: "Không tìm thấy thực đơn này",
  6003: "Bạn đã dùng hết lượt tạo thực đơn trong tháng này. Bạn có thể nâng cấp gói tại /pricing để tiếp tục hoặc quay lại vào tháng sau",
  6004: "AI đang tạm thời quá tải, vui lòng thử lại sau ít phút",
  6005: "Tính năng AI chưa được cấu hình trên máy chủ",
  6006: "Chưa lấy được dữ liệu công thức hoặc sức khỏe của bạn, vui lòng thử lại sau",
  6007: "AI chưa xếp được thực đơn đạt yêu cầu, vui lòng thử lại",
  6010: "Bạn cần cập nhật chiều cao và cân nặng trong hồ sơ sức khỏe trước khi lên thực đơn",
  6011: "Không tìm thấy món chay nào phù hợp với dị ứng và yêu cầu dinh dưỡng của bạn",
  6020: "Bạn cần cập nhật ngày sinh, giới tính và mức độ vận động trong hồ sơ để tính nhu cầu calo",
  6021: "Mục tiêu calo tự tính hiện chỉ dành cho người từ 18 tuổi trở lên. Bạn có thể tự đặt mục tiêu dinh dưỡng riêng",
  6014: "Thực đơn này đã có trong danh sách yêu thích",
  6015: "Thực đơn này chưa có trong danh sách yêu thích",
  6016: "Bạn không có quyền với thực đơn này",
  6017: "Không tìm thấy phiên bản này của thực đơn",
  6018: "Món này không phải món thuần chay, bạn chọn món khác nhé",
  6019: "Món này chứa thành phần gây dị ứng của bạn, bạn chọn món khác nhé",
  6999: "Máy chủ đang gặp lỗi, vui lòng thử lại sau ít phút",
};

// Lỗi 401/403 do Spring Security trả về có thể không kèm mã 60xx nên dựa thêm vào HTTP status.
function toMessage(res, fallbackMessage) {
  const byCode = VI_MESSAGES[res.data?.code];
  if (byCode) return byCode;
  if (res.status === 401) return VI_MESSAGES[6001];
  if (res.status === 429) return VI_MESSAGES[6003];
  if (res.status === 503) return VI_MESSAGES[6004];
  return res.data?.message || fallbackMessage;
}

// validateStatus tắt throw theo status, nên chỉ còn lỗi mạng / quá thời gian chờ rơi vào catch.
function networkError(error, timeoutMessage) {
  return new Error(
    error?.code === "ECONNABORTED" ? timeoutMessage : "Không kết nối được máy chủ, vui lòng thử lại",
    { cause: error },
  );
}

// Lỗi mang theo `code` của BE để giao diện nhận ra lỗi cần xử lý riêng (vd 6020 -> dẫn tới trang hồ sơ).
function unwrap(res, fallbackMessage) {
  if (res.status >= 400) {
    const error = new Error(toMessage(res, fallbackMessage));
    error.code = res.data?.code;
    throw error;
  }
  return res.data?.result;
}

/**
 * POST /ai/meal-plans
 * Body: { name, healthGoal, goalType, preferences?: string[], availableIngredients?: string[],
 *   dailyNutritionTarget?: { minCalories, maxCalories, minProtein, maxProtein,
 *   minCarbohydrate, maxCarbohydrate, minFat, maxFat } }
 * goalType ("LOSE" | "MAINTAIN" | "GAIN") bắt buộc (thiếu thì BE trả 400 / 6000). healthGoal chỉ là mô tả đưa vào
 * prompt nhưng vẫn không được rỗng. Không gửi dailyNutritionTarget thì BE tự tính theo hồ sơ + goalType; có gửi
 * thì BE dùng nguyên giá trị đó (mọi mốc đều tùy chọn) và không đọc hồ sơ.
 */
export async function createMealPlan(payload) {
  let res;
  try {
    res = await apiClient.post("/ai/meal-plans", payload, { timeout: CREATE_TIMEOUT_MS });
  } catch (error) {
    throw networkError(error, "Bé Bông Cải lên thực đơn hơi lâu, bạn thử lại sau một lát nhé");
  }
  return unwrap(res, "Tạo thực đơn thất bại");
}

/** GET /ai/meal-plans — các thực đơn của tôi, mới nhất trước. */
export async function getMealPlans() {
  const res = await apiClient.get("/ai/meal-plans");
  return unwrap(res, "Không lấy được danh sách thực đơn") ?? [];
}

/**
 * GET /ai/meal-plans/nutrition-target?goalType= — mục tiêu calo / macro BE tính từ chiều cao, cân nặng mới nhất
 * và ngày sinh, giới tính, mức vận động trong hồ sơ (Mifflin-St Jeor).
 * Trả { goalType, bmr, tdee, targetCalories, target: { minCalories, maxCalories, minProtein, ... } };
 * `target` có thể gửi nguyên làm dailyNutritionTarget. Lỗi: 6010 (thiếu chỉ số sức khỏe), 6020 (hồ sơ thiếu thông
 * tin), 6021 (dưới 18 tuổi), kèm `error.code`.
 */
export async function getNutritionTarget(goalType) {
  const res = await apiClient.get("/ai/meal-plans/nutrition-target", { params: { goalType } });
  return unwrap(res, "Không tính được mục tiêu dinh dưỡng");
}

/** GET /ai/meal-plans/:id — một thực đơn của tôi (dùng để lấy bản mới nhất từ server). */
export async function getMealPlan(id) {
  const res = await apiClient.get(`/ai/meal-plans/${id}`);
  return unwrap(res, "Không lấy được thực đơn");
}

/** GET /ai/meal-plans/favorites — các thực đơn yêu thích (phân trang, mới yêu thích trước). */
export async function getFavoriteMealPlans({ page = 0, size = 5 } = {}) {
  const res = await apiClient.get("/ai/meal-plans/favorites", { params: { page, size } });
  return unwrap(res, "Không lấy được danh sách thực đơn yêu thích") ?? EMPTY_PAGE;
}

/** GET /ai/meal-plans/favorites/:id — một thực đơn yêu thích. */
export async function getFavoriteMealPlan(id) {
  const res = await apiClient.get(`/ai/meal-plans/favorites/${id}`);
  return unwrap(res, "Không lấy được thực đơn yêu thích");
}

/**
 * POST /ai/meal-plans/:id/favorite — thêm thực đơn vào yêu thích. Đã có sẵn (6014) coi như đã xong,
 * vì ý người dùng là "thực đơn này đang được yêu thích".
 */
export async function favoriteMealPlan(id) {
  const res = await apiClient.post(`/ai/meal-plans/${id}/favorite`);
  if (res.data?.code === 6014) return;
  unwrap(res, "Không thêm được vào danh sách yêu thích");
}

/** DELETE /ai/meal-plans/:id/favorite — bỏ yêu thích. Chưa có trong yêu thích (6015) coi như đã xong. */
export async function unfavoriteMealPlan(id) {
  const res = await apiClient.delete(`/ai/meal-plans/${id}/favorite`);
  if (res.data?.code === 6015) return;
  unwrap(res, "Không bỏ được khỏi danh sách yêu thích");
}

/**
 * Chỉnh sửa thủ công thực đơn. `preview` = true chỉ xem trước (không lưu), false thì lưu.
 * edits: [{ day, mealType, action: "REPLACE" | "UPDATE_SERVING", recipeId?, servingMultiplier? }]
 */
export async function editMealPlan(id, { edits, changeSummary, preview = false }) {
  const res = await apiClient.post(`/ai/meal-plans/${id}/${preview ? "preview-edit" : "edit"}`, {
    preview,
    changeSummary: changeSummary || undefined,
    edits,
  });
  return unwrap(res, preview ? "Không xem trước được thay đổi" : "Lưu thay đổi thất bại");
}

/** GET /ai/meal-plans/:id/versions/:version — nội dung đầy đủ của một phiên bản cũ. */
export async function getMealPlanVersion(id, version) {
  const res = await apiClient.get(`/ai/meal-plans/${id}/versions/${version}`);
  return unwrap(res, "Không lấy được phiên bản này");
}

/** GET /ai/meal-plans/:id/versions — các phiên bản cũ của một thực đơn, mới nhất trước. */
export async function getMealPlanVersions(id) {
  const res = await apiClient.get(`/ai/meal-plans/${id}/versions`);
  return unwrap(res, "Không lấy được lịch sử phiên bản") ?? [];
}

/**
 * POST /ai/meal-plans/:id/update-from-health — cập nhật thực đơn theo chỉ số sức khỏe mới nhất.
 * confirm=false: chỉ xem trước (không lưu gì). confirm=true: lưu, kết quả có `updatedMealPlan`.
 * Chưa có hồ sơ sức khỏe thì BE báo 6010 (đã có bản dịch ở VI_MESSAGES).
 * customTarget (tùy chọn, cùng dạng dailyNutritionTarget): mục tiêu tự đặt, BE dùng thay hẳn mục tiêu tự tính.
 * Không gửi thì BE tính lại theo goalType đã lưu của thực đơn (thực đơn cũ chưa có goalType thì BE đoán từ `goal`)
 * và có thể báo 6020 / 6021 giống getNutritionTarget. changeSummary (tùy chọn, tối đa 500 ký tự): ghi chú lưu cùng phiên bản cũ, mặc định BE ghi
 * "Cập nhật từ chỉ số sức khỏe". Bản xem trước và bản lưu phải dùng cùng customTarget thì kết quả mới giống nhau.
 */
export async function updatePlanFromHealth(id, { confirm = false, customTarget, changeSummary } = {}) {
  const res = await apiClient.post(
    `/ai/meal-plans/${id}/update-from-health`,
    buildHealthUpdateBody({ confirm, customTarget, changeSummary }),
  );
  return unwrap(res, confirm ? "Cập nhật thực đơn thất bại" : "Không xem trước được thực đơn cập nhật");
}

/**
 * POST /ai/meal-plans/:id/replace — đổi một bữa sang món khác.
 * Body: { day, mealType, currentRecipeId } (day lấy đúng chuỗi BE đã trả trong plan.days[].day).
 */
export async function replaceMeal(id, { day, mealType, currentRecipeId }) {
  let res;
  try {
    res = await apiClient.post(
      `/ai/meal-plans/${id}/replace`,
      { day, mealType, currentRecipeId },
      { timeout: CREATE_TIMEOUT_MS },
    );
  } catch (error) {
    throw networkError(error, "Đổi món hơi lâu, bạn thử lại sau một lát nhé");
  }
  return unwrap(res, "Đổi món thất bại");
}
