import { Link, useParams } from "react-router-dom";

import { useAuthStore } from "@/features/auth/store/authStore";
import RecipeForm from "@/features/recipe/components/RecipeForm";
import { useRecipe } from "@/features/recipe/hooks/useRecipes";
import AppFooter from "@/shared/components/AppFooter";
import AppHeader from "@/shared/components/AppHeader";

// Trang tạo công thức (/recipes/new) và sửa công thức (/recipes/:recipeId/edit), cần đăng nhập.
// GET /recipes/:id kèm token thì chủ công thức / ADMIN nạp được cả bản nháp để sửa; người khác nhận 404.
// Công thức đã xóa (ARCHIVED) hoặc bị ẩn (HIDDEN) vẫn nạp được nhưng BE từ chối lưu (lỗi 4108).
export default function RecipeFormScreen() {
  const { recipeId } = useParams();
  const isEdit = recipeId !== undefined;
  const id = /^[1-9]\d*$/.test(recipeId ?? "") ? Number(recipeId) : null;

  const user = useAuthStore((s) => s.user);
  const { data: recipe, isPending, isError } = useRecipe(isEdit ? id : null);

  const canEdit = recipe && (recipe.userId === user?.id || user?.role === "ADMIN");

  let body;
  if (isEdit && (id === null || isError)) {
    body = <Notice title="Không tìm thấy công thức">Công thức không tồn tại hoặc đã bị xóa.</Notice>;
  } else if (isEdit && isPending) {
    body = <FormSkeleton />;
  } else if (isEdit && !canEdit) {
    body = (
      <Notice title="Bạn không có quyền sửa công thức này">
        Chỉ tác giả hoặc quản trị viên mới sửa được công thức.
      </Notice>
    );
  } else {
    body = <RecipeForm recipe={isEdit ? recipe : undefined} />;
  }

  return (
    <div className="min-h-dvh">
      <AppHeader />

      <main className="mx-auto flex w-full max-w-3xl flex-col gap-6 px-6 py-6">
        <h1 className="font-heading text-3xl font-bold text-ink">
          {isEdit ? "Chỉnh sửa công thức" : "Tạo công thức mới"}
        </h1>
        {body}
      </main>

      <AppFooter />
    </div>
  );
}

function Notice({ title, children }) {
  return (
    <div className="rounded-3xl border border-border bg-card p-8 text-center shadow-sm">
      <h2 className="font-heading text-xl font-bold text-ink">{title}</h2>
      <p className="mt-2 text-sm text-subtle">{children}</p>
      <Link
        to="/my-content?tab=recipes"
        className="mt-4 inline-block rounded-full bg-brand px-5 py-2 text-sm font-medium text-brand-foreground transition hover:opacity-90"
      >
        Về công thức của tôi
      </Link>
    </div>
  );
}

function FormSkeleton() {
  return (
    <div
      aria-hidden
      className="animate-pulse space-y-5 rounded-3xl border border-border bg-card p-5 shadow-sm sm:p-6"
    >
      <div className="h-11 w-full rounded-xl bg-surface" />
      <div className="h-20 w-full rounded-xl bg-surface" />
      <div className="h-11 w-full rounded-xl bg-surface" />
      <div className="h-40 w-full rounded-xl bg-surface" />
    </div>
  );
}
