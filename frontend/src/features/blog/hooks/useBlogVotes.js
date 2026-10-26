import { keepPreviousData, useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { getMyVotes, voteBlog } from "@/features/blog/api/blogApi";
import { blogKeys } from "@/features/blog/queryKeys";
import {
  applyVoteToBlog,
  applyVoteToFeed,
  applyVoteToMyVotes,
} from "@/features/blog/utils/voteCache";
import { selectIsAuthenticated, useAuthStore } from "@/features/auth/store/authStore";
import { normalizeIds } from "@/shared/utils/ids";

const toVoteMap = (votes) => new Map(votes.map((v) => [v.blogId, v.myVote]));

/**
 * Vote của tôi trên một danh sách bài (GET /blogs/me/votes) để phủ lên feed công khai.
 * `data` là Map<blogId, 1 | -1 | null>; chưa đăng nhập thì không gọi API (data undefined).
 */
export function useMyVotes(blogIds) {
  const isAuthenticated = useAuthStore(selectIsAuthenticated);
  const ids = normalizeIds(blogIds);

  return useQuery({
    queryKey: blogKeys.myVoteList(ids),
    queryFn: () => getMyVotes(ids),
    select: toVoteMap,
    enabled: isAuthenticated && ids.length > 0,
    // Feed "Xem thêm" làm danh sách id đổi -> giữ vote cũ trong lúc tải để tim không nháy.
    placeholderData: keepPreviousData,
    staleTime: 60 * 1000,
  });
}

/**
 * Bấm tim (POST /blogs/:id/vote, value = 1): chưa vote -> vote, đã vote -> BE thu hồi.
 * Thành công thì ghi thẳng kết quả vào cache (vote của tôi, điểm trong feed, điểm trong chi tiết).
 * Dùng: mutate({ blogId }, { onError }) — lỗi (vd. vote bài của chính mình) là Error tiếng Việt.
 */
export function useVoteBlog() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ blogId }) => voteBlog(blogId, 1),
    onSuccess: (vote) => {
      queryClient.setQueriesData({ queryKey: blogKeys.myVotes }, (old) =>
        applyVoteToMyVotes(old, vote)
      );
      queryClient.setQueriesData({ queryKey: blogKeys.feeds }, (old) =>
        applyVoteToFeed(old, vote)
      );
      queryClient.setQueryData(blogKeys.detail(vote.blogId), (old) =>
        applyVoteToBlog(old, vote)
      );
    },
  });
}
