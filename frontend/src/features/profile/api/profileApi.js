import apiClient from "@/shared/api/apiClient";

/**
 * Profile + nutrition APIs (identity-service + nutrition-service qua api-gateway).
 * Base: VITE_VEGGIEPAL_API_BASE_URL = http://localhost:8080/api
 *
 * Identity:
 *   GET    /users/me
 *   PATCH  /users/me
 *   PUT    /users/me/password
 *   POST   /users/me/avatar  (multipart)
 *
 * Nutrition:
 *   GET    /nutrition/allergens
 *   GET    /nutrition/me/allergies
 *   PUT    /nutrition/me/allergies
 *   GET    /nutrition/me/health-records
 *   GET    /nutrition/me/health-records/latest
 *   POST   /nutrition/me/health-records
 *   PUT    /nutrition/me/health-records/:id
 */

const INVALID_DATA = "Dữ liệu chưa hợp lệ, vui lòng kiểm tra lại";
const HEIGHT_INVALID = "Chiều cao 50 đến 250 cm, tối đa 1 chữ số thập phân";
const WEIGHT_INVALID = "Cân nặng 20 đến 300 kg, tối đa 1 chữ số thập phân";
const ALLERGY_INVALID = "Danh sách dị ứng không hợp lệ";

// Mã lỗi BE (identity 10xx, nutrition 20xx) -> tiếng Việt. Dịch ở API để mọi màn hình tự hiện đúng tiếng Việt.
const VI_MESSAGES = {
  1001: INVALID_DATA,
  1018: INVALID_DATA,
  1003: "Mật khẩu tối thiểu 6 ký tự",
  1006: "Vui lòng nhập họ tên",
  1007: "Không tìm thấy tài khoản",
  1008: "Phiên đăng nhập đã hết hạn",
  1009: "Bạn không có quyền thực hiện",
  1010: "Vui lòng nhập mật khẩu",
  1011: "Mật khẩu hiện tại không đúng",
  1012: "Mật khẩu mới phải khác mật khẩu hiện tại",
  1013: "Ngày sinh phải ở quá khứ",
  1014: "Vui lòng chọn ảnh đại diện",
  1015: "Ảnh phải là JPEG, PNG hoặc WEBP",
  1016: "Ảnh không được vượt quá 2MB",
  1017: "Không tải được ảnh lên, vui lòng thử lại sau",
  2001: HEIGHT_INVALID,
  2002: HEIGHT_INVALID,
  2003: WEIGHT_INVALID,
  2004: WEIGHT_INVALID,
  2006: ALLERGY_INVALID,
  2007: ALLERGY_INVALID,
};

// Ưu tiên mã lỗi BE; nếu không có mã (Spring Security / gateway trả thẳng) thì dịch theo HTTP status.
function toMessage(res, fallbackMessage) {
  const byCode = VI_MESSAGES[res.data?.code];
  if (byCode) return byCode;
  if (res.status === 401) return "Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại";
  if (res.status === 403) return "Bạn không có quyền thực hiện";
  if (res.status === 413) return "Ảnh không được vượt quá 2MB";
  if (res.status === 429) return "Bạn thao tác quá nhanh, vui lòng thử lại sau";
  if (res.status === 503) return "Hệ thống đang bận, vui lòng thử lại sau";
  return fallbackMessage;
}

function unwrap(res, fallbackMessage) {
  if (res.status >= 400) {
    throw new Error(toMessage(res, fallbackMessage));
  }
  return res.data?.result;
}

/** GET /users/me — thông tin profile hiện tại */
export async function getProfile() {
  const res = await apiClient.get("/users/me");
  return unwrap(res, "Không lấy được thông tin hồ sơ");
}

/**
 * PATCH /users/me
 * Body: { fullName?, phone?, dateOfBirth?, gender?, activityLevel? }
 * - null / bỏ field: giữ nguyên
 * - phone: "" để xóa số điện thoại
 * - gender: "MALE" | "FEMALE" | "OTHER"; activityLevel: "SEDENTARY" | "LIGHT" | "MODERATE" | "ACTIVE" | "VERY_ACTIVE".
 *   Giá trị lạ (kể cả "") bị BE từ chối (400 / 1018) và không có cách xóa về trống, nên chỉ gửi khi đã chọn.
 *   Hai trường này cùng ngày sinh là dữ liệu BE dùng để tính nhu cầu calo của thực đơn.
 * GET /users/me trả thêm gender, activityLevel (null khi chưa nhập).
 */
export async function updateProfile(payload) {
  const res = await apiClient.patch("/users/me", payload);
  return unwrap(res, "Cập nhật hồ sơ thất bại");
}

/** PUT /users/me/password — { currentPassword, newPassword } */
export async function changePassword({ currentPassword, newPassword }) {
  const res = await apiClient.put("/users/me/password", {
    currentPassword,
    newPassword,
  });
  unwrap(res, "Đổi mật khẩu thất bại");
}

/** POST /users/me/avatar — multipart field "file" (JPEG/PNG/WEBP, max 2MB) */
export async function uploadAvatar(file) {
  const formData = new FormData();
  formData.append("file", file);
  const res = await apiClient.post("/users/me/avatar", formData, {
    headers: { "Content-Type": "multipart/form-data" },
  });
  return unwrap(res, "Upload ảnh đại diện thất bại");
}

/** GET /nutrition/allergens — danh mục dị ứng */
export async function getAllergens() {
  const res = await apiClient.get("/nutrition/allergens");
  return unwrap(res, "Không lấy được danh mục dị ứng") ?? [];
}

/** GET /nutrition/me/allergies */
export async function getMyAllergies() {
  const res = await apiClient.get("/nutrition/me/allergies");
  return unwrap(res, "Không lấy được danh sách dị ứng") ?? [];
}

/** PUT /nutrition/me/allergies — { allergenIds: number[] } ([] để xóa hết) */
export async function replaceMyAllergies(allergenIds) {
  const res = await apiClient.put("/nutrition/me/allergies", { allergenIds });
  return unwrap(res, "Cập nhật dị ứng thất bại") ?? [];
}

/** GET /nutrition/me/health-records/latest */
export async function getLatestHealthRecord() {
  const res = await apiClient.get("/nutrition/me/health-records/latest");
  // BE có thể trả 404 / null nếu chưa có bản ghi
  if (res.status === 404 || res.data?.code === 2005) {
    return null;
  }
  if (res.status >= 400) {
    // Một số implement trả 200 + result null
    if (res.data?.result == null) return null;
    throw new Error(toMessage(res, "Không lấy được chỉ số sức khỏe"));
  }
  return res.data?.result ?? null;
}

/** GET /nutrition/me/health-records?page&size */
export async function getHealthRecords({ page = 0, size = 10 } = {}) {
  const res = await apiClient.get("/nutrition/me/health-records", {
    params: { page, size },
  });
  return (
    unwrap(res, "Không lấy được lịch sử sức khỏe") ?? {
      items: [],
      page: 0,
      size,
      totalElements: 0,
      totalPages: 0,
    }
  );
}

/** POST /nutrition/me/health-records — { heightCm, weightKg } */
export async function createHealthRecord({ heightCm, weightKg }) {
  const res = await apiClient.post("/nutrition/me/health-records", {
    heightCm,
    weightKg,
  });
  return unwrap(res, "Ghi nhận chỉ số thất bại");
}

/** PUT /nutrition/me/health-records/:id */
export async function updateHealthRecord(id, { heightCm, weightKg }) {
  const res = await apiClient.put(`/nutrition/me/health-records/${id}`, {
    heightCm,
    weightKg,
  });
  return unwrap(res, "Cập nhật chỉ số thất bại");
}
