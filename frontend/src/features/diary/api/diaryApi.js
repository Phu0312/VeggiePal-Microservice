import apiClient from "@/shared/api/apiClient";

/**
 * Nhật ký dinh dưỡng hằng ngày (nutrition-service qua api-gateway, cần đăng nhập):
 *   GET    /nutrition/me/daily-summary?date=YYYY-MM-DD&goalType=LOSE|MAINTAIN|GAIN
 *   POST   /nutrition/me/food-logs
 *   DELETE /nutrition/me/food-logs/:id
 *   POST   /nutrition/me/water           { date, amountMl }
 *   PUT    /nutrition/me/daily-activity  (chỉ trường được gửi mới bị ghi đè)
 */

// Mã lỗi nutrition-service (20xx) liên quan tới nhật ký -> tiếng Việt.
const VI_MESSAGES = {
  1008: "Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại",
  1018: "Mục tiêu không hợp lệ, vui lòng chọn lại",
  2008: "Vui lòng nhập tên món",
  2009: "Giá trị dinh dưỡng hoặc vận động không được âm",
  2010: "Không tìm thấy món này trong nhật ký (có thể đã được xóa)",
  2011: "Lượng nước mỗi lần thêm phải từ 1 đến 5000 ml",
  2012: "Chưa tính được mục tiêu calo lúc này, vui lòng thử lại",
  2013: "Hồ sơ chưa đủ để tính mục tiêu calo: cần chiều cao, cân nặng, ngày sinh, giới tính và mức độ vận động",
  2014: "Mục tiêu calo chỉ dành cho người từ 18 tuổi trở lên",
};

function toMessage(res, fallbackMessage) {
  const byCode = VI_MESSAGES[res.data?.code];
  if (byCode) return byCode;
  if (res.status === 401) return VI_MESSAGES[1008];
  if (res.status === 503) return "Hệ thống đang bận, vui lòng thử lại sau";
  return fallbackMessage;
}

// Lỗi mang theo `code` để màn hình xử lý riêng 2013 / 2014 (hướng dẫn bổ sung hồ sơ thay vì chỉ báo lỗi).
function unwrap(res, fallbackMessage) {
  if (res.status >= 400) {
    const error = new Error(toMessage(res, fallbackMessage));
    error.code = res.data?.code;
    error.status = res.status;
    throw error;
  }
  return res.data?.result;
}

async function send(request) {
  try {
    return await request();
  } catch (error) {
    throw new Error("Không kết nối được máy chủ, vui lòng thử lại", { cause: error });
  }
}

/**
 * Tổng hợp một ngày: đã nạp so với mục tiêu calo (BE tính theo hồ sơ + goalType), macro, nước, vận động và các món.
 * -> { date, consumedCalories, targetCalories, remainingCalories, caloriesBurned, proteinG, targetProteinG, carbsG,
 *      targetCarbsG, fatG, targetFatG, fiberG, waterMl, waterTargetMl, waterGlasses, exerciseMinutes, steps,
 *      activityNote, entries: [{ id, logDate, mealType, foodName, recipeId, calories, proteinG, carbsG, fatG, fiberG }] }
 */
export async function getDailySummary({ date, goalType }) {
  const res = await send(() => apiClient.get("/nutrition/me/daily-summary", { params: { date, goalType } }));
  return unwrap(res, "Không tải được nhật ký dinh dưỡng");
}

/** Ghi một món: { logDate, mealType, foodName, recipeId?, calories?, proteinG?, carbsG?, fatG?, fiberG? } */
export async function addFoodLog(payload) {
  const res = await send(() => apiClient.post("/nutrition/me/food-logs", payload));
  return unwrap(res, "Không ghi được món vào nhật ký");
}

export async function deleteFoodLog(id) {
  const res = await send(() => apiClient.delete(`/nutrition/me/food-logs/${id}`));
  return unwrap(res, "Không xóa được món");
}

/** Cộng thêm nước (1 – 5000 ml mỗi lần) -> hoạt động trong ngày sau khi cộng. */
export async function addWater({ date, amountMl }) {
  const res = await send(() => apiClient.post("/nutrition/me/water", { date, amountMl }));
  return unwrap(res, "Không ghi được lượng nước");
}

/** { date, waterMl?, waterTargetMl?, exerciseMinutes?, steps?, caloriesBurned?, activityNote? } */
export async function updateDailyActivity(payload) {
  const res = await send(() => apiClient.put("/nutrition/me/daily-activity", payload));
  return unwrap(res, "Không cập nhật được vận động");
}
