import { useId } from "react";
import { zodResolver } from "@hookform/resolvers/zod";
import { Loader2 } from "lucide-react";
import { useForm, useWatch } from "react-hook-form";
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
import {
  useCreateIngredient,
  useUpdateIngredient,
} from "@/features/ingredient/hooks/useIngredientMutations";
import { INGREDIENT_LIMITS, ingredientSchema } from "@/features/ingredient/schema";
import {
  emptyIngredientForm,
  formValuesToPayload,
  ingredientToFormValues,
} from "@/features/ingredient/utils/ingredientForm";

const fieldClass =
  "w-full rounded-xl border border-border bg-surface px-3.5 text-sm text-ink outline-none transition placeholder:text-subtle focus:border-brand/40 focus:ring-2 focus:ring-brand/15 aria-[invalid=true]:border-destructive/50 aria-[invalid=true]:ring-2 aria-[invalid=true]:ring-destructive/20";
const inputClass = `${fieldClass} h-11`;
const labelClass = "mb-1.5 block text-sm font-semibold text-ink";
const errorClass = "mt-1.5 text-xs text-destructive";

// Các ô dinh dưỡng trên 100g: [tên field, nhãn, đơn vị].
const NUTRITION_FIELDS = [
  ["caloriesPer100g", "Năng lượng", "kcal"],
  ["proteinPer100g", "Đạm", "g"],
  ["carbsPer100g", "Tinh bột", "g"],
  ["fatPer100g", "Béo", "g"],
  ["fiberPer100g", "Chất xơ (không bắt buộc)", "g"],
];

/**
 * Hộp thoại thêm / sửa nguyên liệu. `target`: null = đóng,
 * { mode: "create" } hoặc { mode: "edit", ingredient }.
 */
export default function IngredientFormDialog({ target, onClose }) {
  return (
    <Dialog open={target !== null} onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="max-w-xl">
        {target && <IngredientForm target={target} onClose={onClose} />}
      </DialogContent>
    </Dialog>
  );
}

function IngredientForm({ target, onClose }) {
  const idPrefix = useId();
  const isEdit = target.mode === "edit";

  const createIngredient = useCreateIngredient();
  const updateIngredient = useUpdateIngredient();

  const {
    register,
    handleSubmit,
    setError,
    control,
    formState: { errors, isSubmitting },
  } = useForm({
    resolver: zodResolver(ingredientSchema),
    defaultValues: isEdit ? ingredientToFormValues(target.ingredient) : emptyIngredientForm(),
  });

  const active = useWatch({ control, name: "active" });

  const onSubmit = async (values) => {
    const payload = formValuesToPayload(values);
    try {
      if (isEdit) {
        await updateIngredient.mutateAsync({ id: target.ingredient.id, payload });
        toast.success("Đã cập nhật nguyên liệu");
      } else {
        await createIngredient.mutateAsync(payload);
        toast.success("Đã thêm nguyên liệu");
      }
      onClose();
    } catch (error) {
      setError("root", { message: error.message });
    }
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} noValidate className="flex flex-col gap-4">
      <DialogHeader>
        <DialogTitle>{isEdit ? "Sửa nguyên liệu" : "Thêm nguyên liệu"}</DialogTitle>
        <DialogDescription>
          Dinh dưỡng tính trên 100g nguyên liệu. Thay đổi sẽ ảnh hưởng kcal của các công thức đang dùng nguyên liệu này.
        </DialogDescription>
      </DialogHeader>

      <div>
        <label htmlFor={`${idPrefix}-name`} className={labelClass}>
          Tên nguyên liệu
        </label>
        <input
          id={`${idPrefix}-name`}
          type="text"
          autoFocus
          maxLength={INGREDIENT_LIMITS.name}
          aria-invalid={Boolean(errors.name)}
          className={inputClass}
          {...register("name")}
        />
        {errors.name && <p className={errorClass}>{errors.name.message}</p>}
      </div>

      <div>
        <label htmlFor={`${idPrefix}-desc`} className={labelClass}>
          Mô tả (không bắt buộc)
        </label>
        <textarea
          id={`${idPrefix}-desc`}
          rows={2}
          maxLength={INGREDIENT_LIMITS.description}
          aria-invalid={Boolean(errors.description)}
          className={`${fieldClass} resize-y py-2.5`}
          {...register("description")}
        />
        {errors.description && <p className={errorClass}>{errors.description.message}</p>}
      </div>

      <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
        {NUTRITION_FIELDS.map(([name, label, unit]) => (
          <div key={name}>
            <label htmlFor={`${idPrefix}-${name}`} className={labelClass}>
              {label}
              <span className="font-normal text-subtle"> ({unit})</span>
            </label>
            <input
              id={`${idPrefix}-${name}`}
              type="text"
              inputMode="decimal"
              aria-invalid={Boolean(errors[name])}
              className={inputClass}
              {...register(name)}
            />
            {errors[name] && <p className={errorClass}>{errors[name].message}</p>}
          </div>
        ))}
      </div>

      <div className="flex flex-col gap-3 rounded-2xl bg-surface p-4">
        <ToggleField label="Thuần chay" {...register("vegan")} />
        <ToggleField label="Có thể gây dị ứng" {...register("allergen")} />
        <ToggleField
          label="Đang sử dụng"
          hint="Tắt để người dùng không còn chọn được nguyên liệu này trong công thức."
          {...register("active")}
        />
        {!active && (
          <p className="rounded-xl bg-warning/10 px-3 py-2 text-xs text-warning">
            Lưu ý: nguyên liệu đã tắt sẽ biến mất khỏi mọi danh sách, kể cả trang quản trị này (hệ thống chưa
            có chức năng xem nguyên liệu đã ẩn), nên bạn sẽ không bật lại được từ đây.
          </p>
        )}
      </div>

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
          {isEdit ? "Lưu thay đổi" : "Thêm nguyên liệu"}
        </Button>
      </DialogFooter>
    </form>
  );
}
