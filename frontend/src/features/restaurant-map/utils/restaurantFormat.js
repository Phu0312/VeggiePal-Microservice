// Hàm thuần cho trang Bản đồ quán chay. Không import "@/" để test bằng node:test.

/** 0.53 → "530 m", 1.14 → "1.1 km", 2 → "2 km". Rỗng nếu không phải số. */
export function formatDistance(km) {
  if (typeof km !== "number" || !Number.isFinite(km) || km < 0) return "";
  const meters = Math.round(km * 1000);
  if (meters < 1000) return `${meters} m`;
  return `${parseFloat(km.toFixed(1))} km`;
}

/** 4.7 → "4.7"; thiếu rating → "—". */
export function formatRating(rating) {
  return typeof rating === "number" && Number.isFinite(rating)
    ? rating.toFixed(1)
    : "—";
}

/** Nhãn loại quán từ cờ veganOnly của BE. */
export function veganLabel(veganOnly) {
  return veganOnly ? "Thuần chay 100%" : "Quán chay";
}

/** Chữ thường, bỏ dấu tiếng Việt ("Phở Chay" → "pho chay") để tìm không phân biệt dấu. */
export function normalizeText(text) {
  return String(text ?? "")
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .replace(/đ/gi, "d")
    .toLowerCase()
    .trim();
}

/** Lọc quán theo từ khóa trong tên hoặc địa chỉ (không phân biệt dấu). Từ khóa rỗng → giữ nguyên. */
export function filterRestaurants(restaurants, keyword) {
  const needle = normalizeText(keyword);
  if (!needle) return restaurants;
  return restaurants.filter((r) =>
    normalizeText(`${r.name} ${r.address ?? ""}`).includes(needle),
  );
}

export const SORT_NEAREST = "nearest";
export const SORT_RATING = "rating";

/**
 * Sắp xếp bản sao của danh sách. BE đã xếp theo khoảng cách nên "nearest" chỉ giữ thứ tự;
 * "rating" xếp rating giảm dần (không có rating xuống cuối), bằng nhau thì gần hơn trước.
 */
export function sortRestaurants(restaurants, sort) {
  const copy = [...restaurants];
  if (sort !== SORT_RATING) return copy;
  return copy.sort((a, b) => {
    const ra = typeof a.rating === "number" ? a.rating : -Infinity;
    const rb = typeof b.rating === "number" ? b.rating : -Infinity;
    if (rb !== ra) return rb - ra;
    return (a.distanceKm ?? Infinity) - (b.distanceKm ?? Infinity);
  });
}

/** Link chỉ đường của Google Maps tới quán (mở ở tab mới). */
export function buildDirectionsUrl({ latitude, longitude }) {
  return `https://www.google.com/maps/dir/?api=1&destination=${latitude},${longitude}`;
}

/** "028 7309 3899" → "tel:02873093899"; không có số → null. */
export function buildTelUrl(phoneNumber) {
  const digits = String(phoneNumber ?? "").replace(/[^\d+]/g, "");
  return digits ? `tel:${digits}` : null;
}

/**
 * Danh sách quán → GeoJSON FeatureCollection cho Mapbox source.
 * Tọa độ GeoJSON là [kinh độ, vĩ độ] — ngược với latitude/longitude của BE.
 */
export function toGeoJSON(restaurants) {
  return {
    type: "FeatureCollection",
    features: restaurants.map((r) => ({
      type: "Feature",
      id: r.id,
      geometry: { type: "Point", coordinates: [r.longitude, r.latitude] },
      properties: { id: r.id, name: r.name },
    })),
  };
}
