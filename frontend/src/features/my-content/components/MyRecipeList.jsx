import { useState } from "react";
import { Link } from "react-router-dom";
import { ChefHat, Clock, Loader2, Users } from "lucide-react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { buttonVariants } from "@/components/ui/variants/button-variants";
import { formatTimeAgo } from "@/features/blog/utils/blogFormat";
import StatusBadge from "@/features/my-content/components/StatusBadge";
import { canPublishRecipe, getRecipeStatusInfo } from "@/features/my-content/utils/statusInfo";
import { useDeleteRecipe, usePublishRecipe } from "@/features/recipe/hooks/useRecipeMutations";
import { useMyRecipes } from "@/features/recipe/hooks/useMyRecipes";
import { totalMinutes } from "@/features/recipe/utils/recipeNutrition";
import ConfirmDialog from "@/shared/components/ConfirmDialog";
import FallbackImage from "@/shared/components/FallbackImage";

// Tab "Công thức": công thức của tôi ở mọi trạng thái (GET /recipes/me), "Xem thêm".
export default function MyRecipeList() {
  const { recipes, total, isPending, isError, error, hasNextPage, fetchNextPage, isFetchingNextPage } =
    useMyRecipes();

  if (isError) {
    return (
      <p className="rounded-xl bg-destructive/10 px-3 py-2 text-sm text-destructive">
        {error.message}
      </p>
    );
  }

  if (isPending) {
    return (
      <div aria-hidden className="flex flex-col gap-3">
        {[0, 1, 2].map((i) => (
          <div
            key={i}
            className="flex animate-pulse gap-4 rounded-3xl border border-border bg-card p-4 shadow-sm"
          >
            <div className="size-20 shrink-0 rounded-2xl bg-surface" />
            <div className="flex-1 space-y-2.5 py-1">
              <div className="h-4 w-20 rounded-full bg-surface" />
              <div className="h-4 w-3/5 rounded bg-surface" />
              <div className="h-3 w-1/3 rounded bg-surface" />
            </div>
          </div>
        ))}
      </div>
    );
  }

  if (recipes.length === 0) {
    return (
      <p className="rounded-3xl border border-border bg-card p-6 text-sm text-subtle">
        Bạn chưa có công thức nào.
      </p>
    );
  }

  return (
    <div className="flex flex-col gap-4">
      <p className="text-xs text-subtle">{total} công thức</p>
      <ul className="flex flex-col gap-3">
        {recipes.map((recipe) => (
          <RecipeRow key={recipe.id} recipe={recipe} />
        ))}
      </ul>
      {hasNextPage && (
        <Button
          type="button"
          variant="outline"
          className="self-center"
          disabled={isFetchingNextPage}
          onClick={() => fetchNextPage()}
        >
          {isFetchingNextPage ? (
            <>
              <Loader2 className="size-4 animate-spin" />
              Đang tải...
            </>
          ) : (
            "Xem thêm"
          )}
        </Button>
      )}
    </div>
  );
}

function RecipeRow({ recipe }) {
  const [confirmDelete, setConfirmDelete] = useState(false);
  const publishRecipe = usePublishRecipe();
  const deleteRecipe = useDeleteRecipe();

  const info = getRecipeStatusInfo(recipe.status);
  const minutes = totalMinutes(recipe);

  const handlePublish = () =>
    publishRecipe.mutate(recipe.id, {
      onSuccess: () => toast.success("Đã đăng công thức"),
      onError: (error) => toast.error(error.message),
    });

  const handleDelete = () =>
    deleteRecipe.mutate(recipe.id, {
      onSuccess: () => {
        setConfirmDelete(false);
        toast.success("Đã xóa công thức");
      },
      onError: (error) => toast.error(error.message),
    });

  return (
    <li className="rounded-3xl border border-border bg-card p-4 shadow-sm">
      <div className="flex gap-4">
        <FallbackImage
          src={recipe.imageUrl}
          className="size-20 shrink-0 rounded-2xl object-cover"
          draggable={false}
          fallback={
            <span className="grid size-20 shrink-0 place-items-center rounded-2xl bg-brand-soft text-brand">
              <ChefHat className="size-7" />
            </span>
          }
        />

        <div className="min-w-0 flex-1">
          <StatusBadge info={info} />
          <h3 className="mt-1.5 line-clamp-2 font-heading text-base font-bold leading-snug text-ink">
            {recipe.title}
          </h3>
          <p className="mt-1 flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-subtle">
            <span className="flex items-center gap-1">
              <Users className="size-3.5" />
              {recipe.servings} khẩu phần
            </span>
            {minutes > 0 && (
              <span className="flex items-center gap-1">
                <Clock className="size-3.5" />
                {minutes} phút
              </span>
            )}
            <span>{formatTimeAgo(recipe.publishedAt ?? recipe.createdAt)}</span>
            {info.hint && <span>{info.hint}</span>}
          </p>
        </div>
      </div>

      <div className="mt-3 flex flex-wrap justify-end gap-2 border-t border-border pt-3">
        <Link
          to={`/recipes/${recipe.id}`}
          className={buttonVariants({ variant: "outline", size: "xs" })}
        >
          Xem
        </Link>
        <Link
          to={`/recipes/${recipe.id}/edit`}
          className={buttonVariants({ variant: "outline", size: "xs" })}
        >
          Sửa
        </Link>
        {canPublishRecipe(recipe.status) && (
          <Button type="button" size="xs" disabled={publishRecipe.isPending} onClick={handlePublish}>
            {publishRecipe.isPending && <Loader2 className="size-3 animate-spin" />}
            Đăng
          </Button>
        )}
        <Button type="button" size="xs" variant="ghost" onClick={() => setConfirmDelete(true)}>
          <span className="text-destructive">Xóa</span>
        </Button>
      </div>

      <ConfirmDialog
        open={confirmDelete}
        onOpenChange={setConfirmDelete}
        title="Xóa công thức?"
        description={`“${recipe.title}” sẽ bị xóa vĩnh viễn. Hành động này không thể hoàn tác.`}
        loading={deleteRecipe.isPending}
        onConfirm={handleDelete}
      />
    </li>
  );
}
