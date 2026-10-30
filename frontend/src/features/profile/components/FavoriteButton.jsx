import { Bookmark, Loader2 } from "lucide-react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { useRequireLogin } from "@/features/auth/hooks/useRequireLogin";
import { useFavorites, useToggleFavorite } from "@/features/profile/hooks/useProfileExtras";
import { cn } from "@/lib/utils";

/**
 * Nút "Lưu" vào bộ sưu tập yêu thích (POST / DELETE /users/me/favorites) cho công thức, bài viết, video.
 * `targetType`: "RECIPE" | "BLOG" | "VIDEO". Tiêu đề / ảnh được lưu kèm để danh sách ở trang Hồ sơ hiện ngay.
 */
export default function FavoriteButton({ targetType, targetId, title, imageUrl, className }) {
  const { isAuthenticated, requireLogin } = useRequireLogin();
  const { data: favorites } = useFavorites(targetType);
  const toggle = useToggleFavorite();
  const saved = isAuthenticated && Boolean(favorites?.some((item) => item.targetId === targetId));

  const handleClick = async () => {
    if (!requireLogin()) return;
    try {
      await toggle.mutateAsync({ favorite: !saved, targetType, targetId, title, imageUrl });
      toast.success(saved ? "Đã bỏ khỏi yêu thích" : "Đã lưu vào yêu thích");
    } catch (error) {
      toast.error(error.message);
    }
  };

  return (
    <Button
      type="button"
      variant="outline"
      size="sm"
      aria-pressed={saved}
      onClick={handleClick}
      disabled={toggle.isPending}
      className={className}
    >
      {toggle.isPending ? (
        <Loader2 className="size-3.5 animate-spin" />
      ) : (
        <Bookmark className={cn("size-3.5", saved && "fill-brand text-brand")} />
      )}
      {saved ? "Đã lưu" : "Lưu"}
    </Button>
  );
}
