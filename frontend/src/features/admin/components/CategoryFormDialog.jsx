import { useId } from "react";
import { zodResolver } from "@hookform/resolvers/zod";
import { Loader2 } from "lucide-react";
import { Controller, useForm } from "react-hook-form";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import ToggleField from "@/features/admin/components/ToggleField";
import { useCreateCategory, useUpdateCategory } from "@/features/blog/hooks/useCategoryMutations";
import { CATEGORY_NAME_MAX, categorySchema } from "@/features/blog/schema";
import {
  CATEGORY_TYPE_OPTIONS,
  categoryToFormValues,
  categoryTypeLabel,
  emptyCategoryForm,
  formValuesToCategoryPayload,
} from "@/features/blog/utils/categoryForm";
import SelectField from "@/shared/components/SelectField";

const fieldClass =
  "h-11 w-full rounded-xl border border-border bg-surface px-3.5 text-sm text-ink outline-none transition placeholder:text-subtle focus:border-brand/40 focus:ring-2 focus:ring-brand/15 aria-[invalid=true]:border-destructive/50 aria-[invalid=true]:ring-2 aria-[invalid=true]:ring-destructive/20";
const labelClass = "mb-1.5 block text-sm font-semibold text-ink";

/**
 * Hộp thoại tạo / sửa danh mục. `target` quyết định chế độ (null = đóng):
 * - { mode: "create-root" }                 tạo danh mục gốc, chọn loại
 * - { mode: "create-child", parent }        tạo danh mục con, tự kế thừa loại của cha
 * - { mode: "edit", category }              chỉ đổi tên / thứ tự / hiển thị (BE không cho đổi cha và loại)
 */
export default function CategoryFormDialog({ target, onClose }) {
  return (
    <Dialog open={target !== null} onOpenChange={(open) => !open && onClose()}>
      <DialogContent>{target && <CategoryForm target={target} onClose={onClose} />}</DialogContent>
    </Dialog>
  );
}

function CategoryForm({ target, onClose }) {
  const idPrefix = useId();
  const { mode } = target;
  const isEdit = mode === "edit";
  const isChild = mode === "create-child";

  const createCategory = useCreateCategory();
  const updateCategory = useUpdateCategory();

  const {
    register,
    control,
    handleSubmit,
    setError,
    formState: { errors, isSubmitting },
  } = useForm({
    resolver: zodResolver(categorySchema),
    defaultValues: isEdit
      ? categoryToFormValues(target.category)
      : emptyCategoryForm(isChild ? target.parent.type : "FOOD_TYPE"),
  });

  const title = isEdit
    ? "Sửa danh mục"
    : isChild
      ? `Thêm danh mục con của “${target.parent.name}”`
      : "Thêm danh mục gốc";

  const onSubmit = async (values) => {
    try {
      if (isEdit) {
        const payload = formValuesToCategoryPayload(values, { isEdit: true });
        await updateCategory.mutateAsync({ id: target.category.id, payload });
        toast.success("Đã cập nhật danh mục");
      } else {
        const payload = formValuesToCategoryPayload(values, {
          parentId: isChild ? target.parent.id : undefined,
        });
        await createCategory.mutateAsync(payload);
        toast.success("Đã thêm danh mục");
      }
      onClose();
    } catch (error) {
      setError("root", { message: error.message });
    }
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} noValidate className="flex flex-col gap-4">
      <DialogHeader>
        <DialogTitle>{title}</DialogTitle>
        <DialogDescription>
          {isChild
            ? `Danh mục con tự dùng loại “${categoryTypeLabel(target.parent.type)}” của danh mục cha.`
            : "Cây danh mục chỉ có tối đa 2 cấp."}
        </DialogDescription>
      </DialogHeader>

      <div>
        <label htmlFor={`${idPrefix}-name`} className={labelClass}>
          Tên danh mục
        </label>
        <input
          id={`${idPrefix}-name`}
          type="text"
          autoFocus
          maxLength={CATEGORY_NAME_MAX}
          aria-invalid={Boolean(errors.name)}
          className={fieldClass}
          {...register("name")}
        />
        {errors.name && <p className="mt-1.5 text-xs text-destructive">{errors.name.message}</p>}
      </div>

      {mode === "create-root" && (
        <div>
          <label htmlFor={`${idPrefix}-type`} className={labelClass}>
            Loại
          </label>
          <Controller
            name="type"
            control={control}
            render={({ field }) => (
              <SelectField
                id={`${idPrefix}-type`}
                variant="field"
                options={CATEGORY_TYPE_OPTIONS}
                value={field.value}
                onValueChange={field.onChange}
                onBlur={field.onBlur}
              />
            )}
          />
        </div>
      )}
      {isEdit && (
        <p className="text-sm text-subtle">
          Loại: <b className="text-ink">{categoryTypeLabel(target.category.type)}</b> (không đổi được)
        </p>
      )}

      <div>
        <label htmlFor={`${idPrefix}-order`} className={labelClass}>
          Thứ tự hiển thị
        </label>
        <input
          id={`${idPrefix}-order`}
          type="text"
          inputMode="numeric"
          placeholder="0"
          aria-invalid={Boolean(errors.displayOrder)}
          className={fieldClass}
          {...register("displayOrder")}
        />
        {errors.displayOrder ? (
          <p className="mt-1.5 text-xs text-destructive">{errors.displayOrder.message}</p>
        ) : (
          <p className="mt-1.5 text-xs text-subtle">Số nhỏ hiện trước. Để trống nếu không cần sắp xếp.</p>
        )}
      </div>

      <ToggleField
        label="Đang hiển thị"
        hint="Tắt để ẩn danh mục khỏi người dùng (bài đã gắn vào danh mục vẫn giữ nguyên)."
        {...register("active")}
      />

      {errors.root && (
        <p className="rounded-xl bg-destructive/10 px-3 py-2 text-sm text-destructive">
          {errors.root.message}
        </p>
      )}

      <DialogFooter>
        <Button type="button" variant="ghost" onClick={onClose} disabled={isSubmitting}>
          Hủy
        </Button>
        <Button type="submit" disabled={isSubmitting}>
          {isSubmitting && <Loader2 className="size-4 animate-spin" />}
          {isEdit ? "Lưu thay đổi" : "Thêm danh mục"}
        </Button>
      </DialogFooter>
    </form>
  );
}
