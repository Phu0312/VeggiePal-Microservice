import { Loader2, UserCheck, UserPlus } from "lucide-react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { useRequireLogin } from "@/features/auth/hooks/useRequireLogin";
import { useAuthStore } from "@/features/auth/store/authStore";
import { useToggleFollow } from "@/features/community/hooks/useCommunity";

/**
 * Theo dõi / bỏ theo dõi một tác giả (POST / DELETE /blogs/authors/:id/follow).
 * Không hiện với chính mình (BE trả 3070). `following` lấy từ dữ liệu của BE (bảng vàng, kênh video, danh sách đang theo dõi).
 */
export default function FollowButton({ authorId, following }) {
  const currentUserId = useAuthStore((s) => s.user?.id);
  const { requireLogin } = useRequireLogin();
  const toggle = useToggleFollow();

  if (authorId == null || authorId === currentUserId) return null;

  const handleClick = async () => {
    if (!requireLogin()) return;
    try {
      await toggle.mutateAsync({ authorId, follow: !following });
    } catch (error) {
      toast.error(error.message);
    }
  };

  return (
    <Button
      type="button"
      variant={following ? "outline" : "soft"}
      size="xs"
      aria-pressed={Boolean(following)}
      onClick={handleClick}
      disabled={toggle.isPending}
    >
      {toggle.isPending ? (
        <Loader2 className="size-3.5 animate-spin" />
      ) : following ? (
        <UserCheck className="size-3.5" />
      ) : (
        <UserPlus className="size-3.5" />
      )}
      {following ? "Đang theo dõi" : "Theo dõi"}
    </Button>
  );
}
