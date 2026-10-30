import { useQuery } from "@tanstack/react-query";
import { Heart, Loader2 } from "lucide-react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { useRequireLogin } from "@/features/auth/hooks/useRequireLogin";
import { getMyRecipeLikes } from "@/features/recipe/api/recipeApi";
import { useToggleRecipeLike } from "@/features/recipe/hooks/useRecipeMutations";
import { recipeKeys } from "@/features/recipe/queryKeys";
import { cn } from "@/lib/utils";

/**
 * Nút thích công thức (POST / DELETE /recipes/:id/like) kèm số lượt thích.
 * Trạng thái "tôi đã thích" lấy qua GET /recipes/me/likes?recipeIds=:id khi đã đăng nhập; khách bấm thì được mời đăng nhập.
 * Chỉ dùng cho công thức đã đăng (BE không cho thích bản nháp).
 */
export default function RecipeLikeButton({ recipe }) {
  const { isAuthenticated, requireLogin } = useRequireLogin();
  const toggle = useToggleRecipeLike();
  const { data } = useQuery({
    queryKey: recipeKeys.likes([recipe.id]),
    queryFn: () => getMyRecipeLikes([recipe.id]),
    enabled: isAuthenticated,
    staleTime: 60 * 1000,
  });

  const status = data?.find((item) => item.recipeId === recipe.id);
  const liked = Boolean(status?.liked);
  const likeCount = status?.likeCount ?? recipe.likeCount ?? 0;

  const handleClick = async () => {
    if (!requireLogin()) return;
    try {
      await toggle.mutateAsync({ id: recipe.id, liked: !liked });
    } catch (error) {
      toast.error(error.message);
    }
  };

  return (
    <Button
      type="button"
      variant="outline"
      size="sm"
      aria-pressed={liked}
      aria-label={liked ? "Bỏ thích công thức" : "Thích công thức"}
      onClick={handleClick}
      disabled={toggle.isPending}
    >
      {toggle.isPending ? (
        <Loader2 className="size-3.5 animate-spin" />
      ) : (
        <Heart className={cn("size-3.5", liked && "fill-destructive text-destructive")} />
      )}
      {likeCount.toLocaleString("vi-VN")}
    </Button>
  );
}
