import { keepPreviousData, useQuery } from "@tanstack/react-query";

import { getNearbyRestaurants } from "@/features/restaurant-map/api/restaurantApi";
import { restaurantKeys } from "@/features/restaurant-map/queryKeys";

/**
 * Quán chay quanh một điểm (GET /restaurants/nearby), gần nhất trước.
 * params: { lat, lng, radiusKm, veganOnly }. Trả về query của React Query + `restaurants`
 * (mảng, luôn có giá trị). Đổi bán kính thì giữ kết quả cũ trong lúc tải để danh sách không nháy trống.
 */
export function useNearbyRestaurants({ lat, lng, radiusKm, veganOnly = false }) {
  const query = useQuery({
    queryKey: restaurantKeys.nearby({ lat, lng, radiusKm, veganOnly }),
    queryFn: () => getNearbyRestaurants({ lat, lng, radiusKm, veganOnly }),
    placeholderData: keepPreviousData,
    staleTime: 60 * 1000,
  });

  return { ...query, restaurants: query.data ?? [] };
}
