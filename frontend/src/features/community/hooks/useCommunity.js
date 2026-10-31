import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { selectIsAuthenticated, useAuthStore } from "@/features/auth/store/authStore";
import {
  checkInChallenge,
  followAuthor,
  getLeaderboard,
  getMyChallenge,
  getMyFollowing,
  getTrendingTopics,
  getVideoChannels,
  unfollowAuthor,
} from "@/features/community/api/communityApi";
import { communityKeys } from "@/features/community/queryKeys";
import { profileKeys } from "@/features/profile/queryKeys";

const STALE_MS = 60 * 1000;

export function useTrendingTopics(limit = 8) {
  return useQuery({
    queryKey: communityKeys.topics(limit),
    queryFn: () => getTrendingTopics(limit),
    staleTime: STALE_MS,
  });
}

// Bảng vàng / kênh video trả cờ `following` theo token, nên khóa cache phân biệt khách và thành viên.
export function useLeaderboard(limit = 5) {
  const isAuthenticated = useAuthStore(selectIsAuthenticated);
  return useQuery({
    queryKey: [...communityKeys.leaderboard(limit), isAuthenticated],
    queryFn: () => getLeaderboard(limit),
    staleTime: STALE_MS,
  });
}

export function useVideoChannels(limit = 6) {
  const isAuthenticated = useAuthStore(selectIsAuthenticated);
  return useQuery({
    queryKey: [...communityKeys.channels(limit), isAuthenticated],
    queryFn: () => getVideoChannels(limit),
    staleTime: STALE_MS,
  });
}

/** Id các tác giả tôi đang theo dõi (chỉ khi đã đăng nhập). */
export function useMyFollowing() {
  const isAuthenticated = useAuthStore(selectIsAuthenticated);
  return useQuery({
    queryKey: communityKeys.following,
    queryFn: getMyFollowing,
    enabled: isAuthenticated,
    staleTime: STALE_MS,
  });
}

/** Theo dõi / bỏ theo dõi. mutate({ authorId, follow }). */
export function useToggleFollow() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ authorId, follow }) => (follow ? followAuthor(authorId) : unfollowAuthor(authorId)),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: communityKeys.authors }),
  });
}

/** Tiến độ thử thách 7 ngày của tôi (chỉ khi đã đăng nhập). */
export function useMyChallenge() {
  const isAuthenticated = useAuthStore(selectIsAuthenticated);
  return useQuery({
    queryKey: communityKeys.challenge,
    queryFn: getMyChallenge,
    enabled: isAuthenticated,
  });
}

/**
 * Điểm danh hôm nay. Thành công thì ghi tiến độ mới vào cache; lỗi 3053 (điểm danh đã lưu nhưng cấp huy hiệu lỗi)
 * thì tải lại tiến độ. Cả hai trường hợp đều làm mới danh sách huy hiệu.
 */
export function useChallengeCheckIn() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: checkInChallenge,
    onSuccess: (progress) => queryClient.setQueryData(communityKeys.challenge, progress),
    onError: (error) => {
      if (error.code === 3053) queryClient.invalidateQueries({ queryKey: communityKeys.challenge });
    },
    onSettled: () => queryClient.invalidateQueries({ queryKey: profileKeys.badges }),
  });
}
