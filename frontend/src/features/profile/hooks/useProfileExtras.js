import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { selectIsAuthenticated, useAuthStore } from "@/features/auth/store/authStore";
import { addFavorite, getFavorites, getMyBadges, removeFavorite } from "@/features/profile/api/profileExtrasApi";
import { profileKeys } from "@/features/profile/queryKeys";

/** Danh sách yêu thích (theo loại hoặc tất cả). Chỉ tải khi đã đăng nhập. */
export function useFavorites(type) {
  const isAuthenticated = useAuthStore(selectIsAuthenticated);
  return useQuery({
    queryKey: profileKeys.favorites(type ?? "ALL"),
    queryFn: () => getFavorites(type),
    enabled: isAuthenticated,
    staleTime: 60 * 1000,
  });
}

/** Lưu / bỏ yêu thích. mutate({ favorite, targetType, targetId, title?, imageUrl? }). */
export function useToggleFavorite() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ favorite, ...item }) => (favorite ? addFavorite(item) : removeFavorite(item)),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: profileKeys.favoritesRoot }),
  });
}

/** Huy hiệu của tôi (GET /users/me/badges). Luôn lấy mới khi mở trang vì BE tự cấp huy hiệu. */
export function useMyBadges({ enabled = true } = {}) {
  return useQuery({
    queryKey: profileKeys.badges,
    queryFn: getMyBadges,
    enabled,
  });
}
