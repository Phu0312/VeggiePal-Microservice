import { keepPreviousData, useQuery } from "@tanstack/react-query";

import { getNearbyRestaurants, searchRestaurants } from "@/features/restaurant-map/api/restaurantApi";
import { restaurantKeys } from "@/features/restaurant-map/queryKeys";

/**
 * Quán chay quanh một điểm (GET /restaurants/nearby), gần nhất trước.
 * params: { lat, lng, radiusKm, veganOnly }. Trả về query của React Query + `restaurants`
 * (mảng, luôn có giá trị). Đổi bán kính thì giữ kết quả cũ trong lúc tải để danh sách không nháy trống.
 */
export function useNearbyRestaurants({ lat, lng, radiusKm, veganOnly = false, enabled = true }) {
  const query = useQuery({
    queryKey: restaurantKeys.nearby({ lat, lng, radiusKm, veganOnly }),
    queryFn: () => getNearbyRestaurants({ lat, lng, radiusKm, veganOnly }),
    enabled,
    placeholderData: keepPreviousData,
    staleTime: 60 * 1000,
  });

  return { ...query, restaurants: query.data ?? [] };
}

/**
 * Tìm quán theo từ khóa trên mọi khu vực (GET /restaurants/search), gửi kèm vị trí để BE tính khoảng cách.
 * Chỉ chạy khi có từ khóa.
 */
export function useRestaurantSearch({ keyword, lat, lng, veganOnly = false }) {
  const query = useQuery({
    queryKey: restaurantKeys.search({ keyword, lat, lng, veganOnly }),
    queryFn: () => searchRestaurants({ keyword, lat, lng, veganOnly }),
    enabled: Boolean(keyword),
    placeholderData: keepPreviousData,
    staleTime: 60 * 1000,
  });

  return { ...query, restaurants: query.data ?? [] };
}
