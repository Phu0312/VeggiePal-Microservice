import { Heart } from "lucide-react";
import { toast } from "sonner";

import { selectIsAuthenticated, useAuthStore } from "@/features/auth/store/authStore";
import { useRequireLogin } from "@/features/auth/hooks/useRequireLogin";
import { useVoteBlog } from "@/features/blog/hooks/useBlogVotes";
import { cn } from "@/lib/utils";

/**
 * Nút tim của một bài. `myVote` là vote hiện tại của tôi (1 | -1 | null | undefined).
 * - Khách bấm -> đá sang /login (useRequireLogin).
 * - Bài của chính mình: BE không cho vote, nên chỉ hiện số tim, không có nút.
 * - Bấm lần nữa khi đã thả tim: BE thu hồi vote.
 */
export default function VoteButton({ blog, myVote, className }) {
  const userId = useAuthStore((s) => s.user?.id);
  const isAuthenticated = useAuthStore(selectIsAuthenticated);
  const { requireLogin } = useRequireLogin();
  const { mutate, isPending } = useVoteBlog();

  const liked = myVote === 1;
  const score = blog.voteScore.toLocaleString("vi-VN");
  const isOwnPost = isAuthenticated && userId === blog.authorId;

  if (isOwnPost) {
    return (
      <span className={cn("flex items-center gap-1.5", className)} title="Số lượt thích bài viết của bạn">
        <Heart className="size-4 text-destructive" />
        {score}
      </span>
    );
  }

  const handleClick = () => {
    if (!requireLogin()) return;
    mutate({ blogId: blog.id }, { onError: (error) => toast.error(error.message) });
  };

  return (
    <button
      type="button"
      onClick={handleClick}
      disabled={isPending}
      aria-pressed={liked}
      aria-label={liked ? "Bỏ thích bài viết" : "Thích bài viết"}
      className={cn(
        "flex items-center gap-1.5 rounded-full transition hover:text-destructive disabled:opacity-60",
        liked && "font-semibold text-destructive",
        className
      )}
    >
      <Heart className={cn("size-4 text-destructive", liked && "fill-current")} />
      {score}
    </button>
  );
}
