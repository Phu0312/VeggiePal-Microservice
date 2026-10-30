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
import { useAddFoodLog } from "@/features/diary/hooks/useDiary";
import { foodLogSchema } from "@/features/diary/schema";
import { MEAL_TYPES, optionalNumber } from "@/features/diary/utils/diary";
import SelectField from "@/shared/components/SelectField";

const fieldClass =
  "h-11 w-full rounded-xl border border-border bg-surface px-3.5 text-sm text-ink outline-none transition placeholder:text-subtle focus:border-brand/40 focus:ring-2 focus:ring-brand/15 aria-[invalid=true]:border-destructive/50 aria-[invalid=true]:ring-2 aria-[invalid=true]:ring-destructive/20";
const labelClass = "mb-1.5 block text-sm font-semibold text-ink";

const NUMBER_FIELDS = [
  { name: "calories", label: "Calo (kcal)", placeholder: "VD: 350" },
  { name: "proteinG", label: "Đạm (g)", placeholder: "VD: 12" },
  { name: "carbsG", label: "Tinh bột (g)", placeholder: "VD: 45" },
  { name: "fatG", label: "Chất béo (g)", placeholder: "VD: 8" },
  { name: "fiberG", label: "Chất xơ (g)", placeholder: "VD: 5" },
];

/** Ghi một món vào nhật ký ngày `date` (POST /nutrition/me/food-logs). `mealType` = null là đóng. */
export default function AddFoodDialog({ date, mealType, onClose }) {
  return (
    <Dialog open={mealType !== null} onOpenChange={(open) => !open && onClose()}>
      <DialogContent>{mealType && <AddFoodForm date={date} mealType={mealType} onClose={onClose} />}</DialogContent>
    </Dialog>
  );
}

function AddFoodForm({ date, mealType, onClose }) {
  const idPrefix = useId();
  const addFoodLog = useAddFoodLog();
  const {
    register,
    control,
    handleSubmit,
    setError,
    formState: { errors, isSubmitting },
  } = useForm({
    resolver: zodResolver(foodLogSchema),
    defaultValues: { mealType, foodName: "", calories: "", proteinG: "", carbsG: "", fatG: "", fiberG: "" },
  });

  const onSubmit = async (values) => {
    try {
      await addFoodLog.mutateAsync({
        logDate: date,
        mealType: values.mealType,
        foodName: values.foodName,
        calories: optionalNumber(values.calories),
        proteinG: optionalNumber(values.proteinG),
        carbsG: optionalNumber(values.carbsG),
        fatG: optionalNumber(values.fatG),
        fiberG: optionalNumber(values.fiberG),
      });
      toast.success("Đã ghi món vào nhật ký");
      onClose();
    } catch (error) {
      setError("root", { message: error.message });
    }
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} noValidate className="flex flex-col gap-4">
      <DialogHeader>
        <DialogTitle>Thêm món</DialogTitle>
        <DialogDescription>Dinh dưỡng có thể bỏ trống nếu bạn không biết, món vẫn được ghi lại.</DialogDescription>
      </DialogHeader>

      {errors.root && (
        <p role="alert" className="rounded-xl bg-destructive/10 px-3 py-2 text-sm text-destructive">
          {errors.root.message}
        </p>
      )}

      <div className="grid gap-3 sm:grid-cols-[1fr_10rem]">
        <div>
          <label htmlFor={`${idPrefix}-name`} className={labelClass}>
            Tên món
          </label>
          <input
            id={`${idPrefix}-name`}
            className={fieldClass}
            placeholder="VD: Đậu hũ sốt cà chua"
            aria-invalid={Boolean(errors.foodName)}
            {...register("foodName")}
          />
          {errors.foodName && <p className="mt-1 text-xs text-destructive">{errors.foodName.message}</p>}
        </div>
        <div>
          <label htmlFor={`${idPrefix}-meal`} className={labelClass}>
            Bữa
          </label>
          <Controller
            control={control}
            name="mealType"
            render={({ field }) => (
              <SelectField
                id={`${idPrefix}-meal`}
                variant="field"
                options={MEAL_TYPES}
                value={field.value}
                onValueChange={field.onChange}
                onBlur={field.onBlur}
              />
            )}
          />
        </div>
      </div>

      <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
        {NUMBER_FIELDS.map((field) => (
          <div key={field.name}>
            <label htmlFor={`${idPrefix}-${field.name}`} className={labelClass}>
              {field.label}
            </label>
            <input
              id={`${idPrefix}-${field.name}`}
              inputMode="decimal"
              className={fieldClass}
              placeholder={field.placeholder}
              aria-invalid={Boolean(errors[field.name])}
              {...register(field.name)}
            />
            {errors[field.name] && <p className="mt-1 text-xs text-destructive">{errors[field.name].message}</p>}
          </div>
        ))}
      </div>

      <DialogFooter>
        <Button type="button" variant="outline" onClick={onClose} disabled={isSubmitting}>
          Hủy
        </Button>
        <Button type="submit" disabled={isSubmitting}>
          {isSubmitting && <Loader2 className="size-4 animate-spin" />}
          Ghi món
        </Button>
      </DialogFooter>
    </form>
  );
}
