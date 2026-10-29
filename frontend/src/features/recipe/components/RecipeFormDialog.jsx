import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { useAuthStore } from "@/features/auth/store/authStore";
import RecipeForm from "@/features/recipe/components/RecipeForm";
import { useRecipe } from "@/features/recipe/hooks/useRecipes";

// Popup tạo công thức (không có recipeId) và sửa công thức (có recipeId), cần đăng nhập.
// GET /recipes/:id kèm token thì chủ công thức / ADMIN nạp được cả bản nháp để sửa; người khác nhận 404.
// Công thức đã xóa (ARCHIVED) hoặc bị ẩn (HIDDEN) vẫn nạp được nhưng BE từ chối lưu (lỗi 4108).
export default function RecipeFormDialog({ recipeId, onClose }) {
  const isEdit = recipeId !== undefined;
  const id = Number.isInteger(recipeId) && recipeId > 0 ? recipeId : null;

  const user = useAuthStore((s) => s.user);
  const { data: recipe, isPending, isError } = useRecipe(isEdit ? id : null);

  const canEdit = recipe && (recipe.userId === user?.id || user?.role === "ADMIN");

  let body;
  if (isEdit && (id === null || isError)) {
    body = (
      <Notice title="Không tìm thấy công thức" onClose={onClose}>
        Công thức không tồn tại hoặc đã bị xóa.
      </Notice>
    );
  } else if (isEdit && isPending) {
    body = <FormSkeleton />;
  } else if (isEdit && !canEdit) {
    body = (
      <Notice title="Bạn không có quyền sửa công thức này" onClose={onClose}>
        Chỉ tác giả hoặc quản trị viên mới sửa được công thức.
      </Notice>
    );
  } else {
    body = <RecipeForm recipe={isEdit ? recipe : undefined} onClose={onClose} />;
  }

  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="max-w-3xl bg-surface">
        <DialogHeader>
          <DialogTitle>{isEdit ? "Chỉnh sửa công thức" : "Tạo công thức mới"}</DialogTitle>
          <DialogDescription>
            {isEdit
              ? "Cập nhật thông tin, nguyên liệu và các bước làm."
              : "Chia sẻ món chay của bạn: nguyên liệu, các bước làm và ảnh minh hoạ."}
          </DialogDescription>
        </DialogHeader>
        {body}
      </DialogContent>
    </Dialog>
  );
}

function Notice({ title, children, onClose }) {
  return (
    <div className="rounded-3xl border border-border bg-card p-8 text-center">
      <h2 className="font-heading text-xl font-bold text-ink">{title}</h2>
      <p className="mt-2 text-sm text-subtle">{children}</p>
      <Button type="button" className="mt-4" onClick={onClose}>
        Đóng
      </Button>
    </div>
  );
}

function FormSkeleton() {
  return (
    <div aria-hidden className="animate-pulse space-y-5 rounded-3xl border border-border bg-card p-5 sm:p-6">
      <div className="h-11 w-full rounded-xl bg-surface" />
      <div className="h-20 w-full rounded-xl bg-surface" />
      <div className="h-11 w-full rounded-xl bg-surface" />
      <div className="h-40 w-full rounded-xl bg-surface" />
    </div>
  );
}
