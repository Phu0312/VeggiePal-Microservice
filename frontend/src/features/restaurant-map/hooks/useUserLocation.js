import { useCallback, useEffect, useState } from "react";

import { DEFAULT_LOCATION } from "@/features/restaurant-map/utils/mapConfig";

const GEO_OPTIONS = { enableHighAccuracy: false, timeout: 10000, maximumAge: 60000 };

const isSupported = () =>
  typeof navigator !== "undefined" && "geolocation" in navigator;

// Gọi định vị và báo kết quả qua `update`. Lỗi giữ lại vị trí cũ (nếu có) để lần thử lại
// thất bại không đẩy người dùng về tâm mặc định.
function readPosition(update) {
  navigator.geolocation.getCurrentPosition(
    (pos) =>
      update({
        status: "granted",
        position: { lat: pos.coords.latitude, lng: pos.coords.longitude },
      }),
    (err) =>
      update((prev) => ({
        status: err.code === 1 ? "denied" : "unavailable",
        position: prev.position,
      })),
    GEO_OPTIONS,
  );
}

/**
 * Vị trí người dùng từ `navigator.geolocation`, tự xin quyền khi trang mở.
 * Trả về:
 * - location: { lat, lng } — luôn có giá trị, là tâm TP.HCM khi chưa có vị trí thật
 * - isDefaultLocation: true khi đang dùng tâm mặc định
 * - status: "loading" | "granted" | "denied" | "unavailable" | "unsupported"
 * - request(): xin định vị lại (nút "Vị trí của tôi")
 * - resetToDefault(): quay về tâm mặc định
 */
export function useUserLocation() {
  const [state, setState] = useState(() => ({
    status: isSupported() ? "loading" : "unsupported",
    position: null,
  }));

  useEffect(() => {
    if (isSupported()) readPosition(setState);
  }, []);

  const request = useCallback(() => {
    if (!isSupported()) return;
    setState((prev) => ({ ...prev, status: "loading" }));
    readPosition(setState);
  }, []);

  // Bỏ vị trí thật để xem quán quanh tâm mặc định (người dùng đang ở xa khu vực có quán).
  const resetToDefault = useCallback(
    () => setState((prev) => ({ ...prev, position: null })),
    [],
  );

  return {
    location: state.position ?? DEFAULT_LOCATION,
    isDefaultLocation: state.position == null,
    status: state.status,
    request,
    resetToDefault,
  };
}
