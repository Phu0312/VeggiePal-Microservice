import { useState } from "react";
import { Eye, EyeOff, Pencil, Plus, Trash2 } from "lucide-react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import CategoryFormDialog from "@/features/admin/components/CategoryFormDialog";
import { useCategories } from "@/features/blog/hooks/useCategories";
import { useDeleteCategory } from "@/features/blog/hooks/useCategoryMutations";
import { categoryTypeLabel } from "@/features/blog/utils/categoryForm";
import { cn } from "@/lib/utils";
import ConfirmDialog from "@/shared/components/ConfirmDialog";

// Trang quản lý danh mục (/admin/categories): cây 2 cấp, gồm cả danh mục đang ẩn.
export default function AdminCategoriesScreen() {
  const { data: tree, isPending, isError, error } = useCategories({ activeOnly: false });
  const deleteCategory = useDeleteCategory();

  const [formTarget, setFormTarget] = useState(null);
  const [deleting, setDeleting] = useState(null);

  const handleDelete = () =>
    deleteCategory.mutate(deleting.id, {
      onSuccess: () => {
        setDeleting(null);
        toast.success("Đã xóa danh mục");
      },
      onError: (err) => {
        setDeleting(null);
        toast.error(err.message);
      },
    });

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h1 className="font-heading text-3xl font-bold text-ink">Danh mục</h1>
          <p className="mt-1 text-sm text-subtle">
            Danh mục dùng để phân loại bài viết. Cây danh mục có tối đa 2 cấp.
          </p>
        </div>
        <Button type="button" onClick={() => setFormTarget({ mode: "create-root" })}>
          <Plus className="size-4" />
          Thêm danh mục gốc
        </Button>
      </div>

      {isError ? (
        <p className="rounded-xl bg-destructive/10 px-3 py-2 text-sm text-destructive">{error.message}</p>
      ) : isPending ? (
        <div aria-hidden className="flex flex-col gap-3">
          {[0, 1, 2].map((i) => (
            <div key={i} className="h-24 animate-pulse rounded-3xl border border-border bg-card" />
          ))}
        </div>
      ) : tree.length === 0 ? (
        <p className="rounded-3xl border border-border bg-card p-6 text-sm text-subtle">
          Chưa có danh mục nào. Bấm “Thêm danh mục gốc” để bắt đầu.
        </p>
      ) : (
        <ul className="flex flex-col gap-4">
          {tree.map((root) => (
            <li key={root.id} className="overflow-hidden rounded-3xl border border-border bg-card shadow-sm">
              <CategoryRow
                category={root}
                isRoot
                onAddChild={() => setFormTarget({ mode: "create-child", parent: root })}
                onEdit={() => setFormTarget({ mode: "edit", category: root })}
                onDelete={() => setDeleting(root)}
              />
              {root.children?.length > 0 && (
                <ul className="divide-y divide-border border-t border-border bg-surface/50">
                  {root.children.map((child) => (
                    <li key={child.id}>
                      <CategoryRow
                        category={child}
                        onEdit={() => setFormTarget({ mode: "edit", category: child })}
                        onDelete={() => setDeleting(child)}
                      />
                    </li>
                  ))}
                </ul>
              )}
            </li>
          ))}
        </ul>
      )}

      <CategoryFormDialog target={formTarget} onClose={() => setFormTarget(null)} />

      <ConfirmDialog
        open={deleting !== null}
        onOpenChange={(open) => !open && setDeleting(null)}
        title="Xóa danh mục?"
        description={`“${deleting?.name ?? ""}” sẽ bị xóa. Chỉ xóa được khi không còn bài viết hay danh mục con nào thuộc về nó; nếu không, hãy tắt “Đang hiển thị” để ẩn thay vì xóa.`}
        loading={deleteCategory.isPending}
        onConfirm={handleDelete}
      />
    </div>
  );
}

function CategoryRow({ category, isRoot = false, onAddChild, onEdit, onDelete }) {
  return (
    <div className={cn("flex flex-wrap items-center gap-x-4 gap-y-2 px-4 py-3 sm:px-5", !isRoot && "pl-8 sm:pl-12")}>
      <div className="min-w-0 flex-1">
        <p className={cn("truncate text-ink", isRoot ? "font-heading text-lg font-bold" : "text-sm font-semibold")}>
          {category.name}
        </p>
        <p className="mt-0.5 flex flex-wrap items-center gap-x-3 text-xs text-subtle">
          {isRoot && <span>{categoryTypeLabel(category.type)}</span>}
          <span>Thứ tự: {category.displayOrder ?? 0}</span>
          {isRoot && <span>{category.children?.length ?? 0} danh mục con</span>}
        </p>
      </div>

      <span
        className={cn(
          "flex shrink-0 items-center gap-1 rounded-full px-2.5 py-1 text-[11px] font-medium",
          category.active ? "bg-brand-soft text-brand" : "bg-surface text-subtle"
        )}
      >
        {category.active ? <Eye className="size-3" /> : <EyeOff className="size-3" />}
        {category.active ? "Đang hiển thị" : "Đang ẩn"}
      </span>

      <div className="flex shrink-0 items-center gap-1">
        {isRoot && (
          <Button type="button" size="xs" variant="outline" onClick={onAddChild}>
            <Plus className="size-3" />
            Thêm con
          </Button>
        )}
        <Button type="button" size="icon-sm" variant="ghost" aria-label={`Sửa ${category.name}`} onClick={onEdit}>
          <Pencil className="size-4" />
        </Button>
        <Button type="button" size="icon-sm" variant="ghost" aria-label={`Xóa ${category.name}`} onClick={onDelete}>
          <Trash2 className="size-4 text-destructive" />
        </Button>
      </div>
    </div>
  );
}
