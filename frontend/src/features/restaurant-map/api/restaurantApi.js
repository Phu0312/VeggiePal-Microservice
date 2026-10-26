import apiClient from "@/shared/api/apiClient";

/**
 * Restaurant APIs (location-service qua api-gateway). Công khai, không cần token.
 *   GET /restaurants/nearby?lat=&lng=[&radiusKm=5][&veganOnly=false]
 *
 * Restaurant: {
 *   id, name, address, latitude, longitude, phoneNumber, rating,
 *   veganOnly, imageUrl (có thể null), distanceKm
 * }
 * Kết quả xếp theo khoảng cách tăng dần, không phân trang. radiusKm tối đa 10.
 * Lỗi: 1018 thiếu/sai kiểu tham số, 5001 tọa độ ngoài phạm vi, 5002 bán kính ngoài (0, 10].
 */

// BE trả message tiếng Anh theo ErrorCode; đổi sang tiếng Việt theo `code`.
const VI_MESSAGES = {
  1018: "Dữ liệu tìm kiếm không hợp lệ",
  5001: "Tọa độ không hợp lệ",
  5002: "Bán kính tìm kiếm phải lớn hơn 0 và tối đa 10 km",
};

function unwrap(res, fallbackMessage) {
  if (res.status >= 400) {
    throw new Error(
      VI_MESSAGES[res.data?.code] ?? res.data?.message ?? fallbackMessage,
    );
  }
  return res.data?.result;
}

/**
 * GET /restaurants/nearby — quán chay trong bán kính `radiusKm` (tối đa 10), gần nhất trước.
 */
export async function getNearbyRestaurants({
  lat,
  lng,
  radiusKm,
  veganOnly = false,
}) {
  let res;
  try {
    res = await apiClient.get("/restaurants/nearby", {
      params: { lat, lng, radiusKm, veganOnly },
    });
  } catch {
    // validateStatus tắt throw theo status, nên chỉ còn lỗi mạng rơi vào đây.
    throw new Error("Không kết nối được máy chủ, vui lòng thử lại");
  }
  return unwrap(res, "Không lấy được danh sách quán chay") ?? [];
}
