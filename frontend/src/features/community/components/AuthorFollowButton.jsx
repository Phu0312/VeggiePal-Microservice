import FollowButton from "@/features/community/components/FollowButton";
import { useMyFollowing } from "@/features/community/hooks/useCommunity";

/** Nút theo dõi cạnh tên tác giả ở trang bài viết / video: trạng thái lấy từ GET /blogs/me/following. */
export default function AuthorFollowButton({ authorId }) {
  const { data: followingIds } = useMyFollowing();
  return <FollowButton authorId={authorId} following={Boolean(followingIds?.includes(authorId))} />;
}
