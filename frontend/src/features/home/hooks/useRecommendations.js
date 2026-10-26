import { useQuery } from "@tanstack/react-query";

import { selectIsAuthenticated, useAuthStore } from "@/features/auth/store/authStore";
import { getRecommendations } from "@/features/home/api/recommendationApi";
import { recommendationKeys } from "@/features/home/queryKeys";

const STALE_MS = 5 * 60 * 1000; // 5 phút

/**
 * Hook lấy gợi ý nội dung trực tiếp từ BE qua API `GET /ai/recommendations`.
 * Chỉ gọi khi người dùng đã đăng nhập.
 */
export function useRecommendations({ interest, limit = 6 } = {}) {
  const isAuthenticated = useAuthStore(selectIsAuthenticated);

  return useQuery({
    queryKey: recommendationKeys.list({ interest, limit }),
    queryFn: () => getRecommendations({ interest, limit }),
    enabled: isAuthenticated,
    staleTime: STALE_MS,
  });
}
