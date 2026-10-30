import { useId, useState } from "react";
import { zodResolver } from "@hookform/resolvers/zod";
import { Loader2, Pencil, Plus, Salad, Trash2 } from "lucide-react";
import { useFieldArray, useForm } from "react-hook-form";
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
import { useAuthStore } from "@/features/auth/store/authStore";
import { useUpdateVideoNutrition, useVideoNutrition } from "@/features/video/hooks/useVideoNutrition";
import { videoNutritionSchema } from "@/features/video/schema";

const fieldClass =
  "h-10 w-full rounded-xl border border-border bg-surface px-3 text-sm text-ink outline-none transition placeholder:text-subtle focus:border-brand/40 focus:ring-2 focus:ring-brand/15 aria-[invalid=true]:border-destructive/50";
const labelClass = "mb-1 block text-xs font-semibold text-ink";

const MACROS = [
  { name: "kcal", label: "Calo (kcal)" },
  { name: "proteinG", label: "Đạm (g)" },
  { name: "carbsG", label: "Tinh bột (g)" },
  { name: "fatG", label: "Béo (g)" },
  { name: "fiberG", label: "Xơ (g)" },
];

const toText = (value) => (value == null ? "" : String(value));
const toNumber = (text) => {
  const trimmed = String(text ?? "").trim();
  return trimmed ? Number(trimmed.replace(",", ".")) : null;
};
const fmt = (value) => (value == null ? "—" : Number(value).toLocaleString("vi-VN", { maximumFractionDigits: 1 }));

/**
 * Dinh dưỡng mỗi khẩu phần và nguyên liệu của video (GET /videos/:id/nutrition, công khai).
 * Chủ video hoặc ADMIN sửa được (PUT /videos/:id/nutrition). Chưa có thông tin thì khách không thấy thẻ này.
 */
export default function VideoNutritionCard({ video }) {
  const user = useAuthStore((s) => s.user);
  const { data: nutrition, isPending } = useVideoNutrition(video?.id);
  const [editing, setEditing] = useState(false);
  const canEdit = Boolean(video && user && (video.authorId === user.id || user.role === "ADMIN"));

  if (!video || isPending || (!nutrition && !canEdit)) return null;

  return (
    <section className="rounded-3xl border border-border bg-card p-5 shadow-sm sm:p-6">
      <div className="flex items-center justify-between gap-3">
        <h2 className="flex items-center gap-2 font-heading text-lg font-bold text-ink">
          <Salad className="size-5 text-brand" />
          Dinh dưỡng món ăn
        </h2>
        {canEdit && (
          <Button type="button" variant="ghost" size="sm" onClick={() => setEditing(true)}>
            <Pencil className="size-4" />
            {nutrition ? "Sửa" : "Thêm thông tin"}
          </Button>
        )}
      </div>

      {nutrition ? (
        <>
          {nutrition.servingLabel && <p className="mt-1 text-xs text-subtle">Mỗi khẩu phần: {nutrition.servingLabel}</p>}
          <dl className="mt-4 grid grid-cols-2 gap-2 sm:grid-cols-5">
            {MACROS.map((macro) => (
              <div key={macro.name} className="rounded-2xl bg-surface px-3 py-2">
                <dt className="text-[11px] text-subtle">{macro.label}</dt>
                <dd className="text-sm font-semibold text-ink">{fmt(nutrition[macro.name])}</dd>
              </div>
            ))}
          </dl>
          {nutrition.ingredients?.length > 0 && (
            <ul className="mt-4 flex flex-col gap-1.5 text-sm text-body">
              {nutrition.ingredients.map((item, index) => (
                <li key={`${item.name}-${index}`} className="flex justify-between gap-3 border-b border-border/60 pb-1.5">
                  <span>{item.name}</span>
                  {item.amount && <span className="text-subtle">{item.amount}</span>}
                </li>
              ))}
            </ul>
          )}
        </>
      ) : (
        <p className="mt-3 text-sm text-subtle">Video chưa có thông tin dinh dưỡng. Thêm để người xem biết món này có gì.</p>
      )}

      <Dialog open={editing} onOpenChange={setEditing}>
        <DialogContent>
          {editing && <NutritionForm videoId={video.id} nutrition={nutrition} onClose={() => setEditing(false)} />}
        </DialogContent>
      </Dialog>
    </section>
  );
}

function NutritionForm({ videoId, nutrition, onClose }) {
  const idPrefix = useId();
  const update = useUpdateVideoNutrition();
  const {
    register,
    control,
    handleSubmit,
    setError,
    formState: { errors, isSubmitting },
  } = useForm({
    resolver: zodResolver(videoNutritionSchema),
    defaultValues: {
      servingLabel: nutrition?.servingLabel ?? "",
      kcal: toText(nutrition?.kcal),
      proteinG: toText(nutrition?.proteinG),
      carbsG: toText(nutrition?.carbsG),
      fatG: toText(nutrition?.fatG),
      fiberG: toText(nutrition?.fiberG),
      ingredients: (nutrition?.ingredients ?? []).map((item) => ({ name: item.name ?? "", amount: item.amount ?? "" })),
    },
  });
  const ingredients = useFieldArray({ control, name: "ingredients" });

  const onSubmit = async (values) => {
    try {
      await update.mutateAsync({
        videoId,
        payload: {
          servingLabel: values.servingLabel || null,
          kcal: toNumber(values.kcal),
          proteinG: toNumber(values.proteinG),
          carbsG: toNumber(values.carbsG),
          fatG: toNumber(values.fatG),
          fiberG: toNumber(values.fiberG),
          ingredients: values.ingredients.map((item) => ({ name: item.name, amount: item.amount || null })),
        },
      });
      toast.success("Đã lưu thông tin dinh dưỡng");
      onClose();
    } catch (error) {
      setError("root", { message: error.message });
    }
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} noValidate className="flex max-h-[80vh] flex-col gap-4 overflow-y-auto">
      <DialogHeader>
        <DialogTitle>Dinh dưỡng món ăn</DialogTitle>
        <DialogDescription>Số liệu cho một khẩu phần. Ô nào không biết có thể để trống.</DialogDescription>
      </DialogHeader>
      {errors.root && (
        <p role="alert" className="rounded-xl bg-destructive/10 px-3 py-2 text-sm text-destructive">
          {errors.root.message}
        </p>
      )}

      <div>
        <label htmlFor={`${idPrefix}-serving`} className={labelClass}>
          Khẩu phần
        </label>
        <input
          id={`${idPrefix}-serving`}
          className={fieldClass}
          placeholder="VD: 1 tô (350g)"
          aria-invalid={Boolean(errors.servingLabel)}
          {...register("servingLabel")}
        />
        {errors.servingLabel && <p className="mt-1 text-xs text-destructive">{errors.servingLabel.message}</p>}
      </div>

      <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
        {MACROS.map((macro) => (
          <div key={macro.name}>
            <label htmlFor={`${idPrefix}-${macro.name}`} className={labelClass}>
              {macro.label}
            </label>
            <input
              id={`${idPrefix}-${macro.name}`}
              inputMode="decimal"
              className={fieldClass}
              aria-invalid={Boolean(errors[macro.name])}
              {...register(macro.name)}
            />
            {errors[macro.name] && <p className="mt-1 text-xs text-destructive">{errors[macro.name].message}</p>}
          </div>
        ))}
      </div>

      <div>
        <p className={labelClass}>Nguyên liệu</p>
        <ul className="flex flex-col gap-2">
          {ingredients.fields.map((field, index) => (
            <li key={field.id} className="flex items-start gap-2">
              <div className="flex-1">
                <input
                  className={fieldClass}
                  placeholder="Tên nguyên liệu"
                  aria-label={`Tên nguyên liệu ${index + 1}`}
                  aria-invalid={Boolean(errors.ingredients?.[index]?.name)}
                  {...register(`ingredients.${index}.name`)}
                />
                {errors.ingredients?.[index]?.name && (
                  <p className="mt-1 text-xs text-destructive">{errors.ingredients[index].name.message}</p>
                )}
              </div>
              <input
                className={`${fieldClass} w-32`}
                placeholder="Lượng"
                aria-label={`Lượng nguyên liệu ${index + 1}`}
                {...register(`ingredients.${index}.amount`)}
              />
              <Button
                type="button"
                variant="ghost"
                size="icon-sm"
                className="mt-1.5"
                aria-label={`Xóa nguyên liệu ${index + 1}`}
                onClick={() => ingredients.remove(index)}
              >
                <Trash2 className="size-4 text-destructive" />
              </Button>
            </li>
          ))}
        </ul>
        <Button
          type="button"
          variant="outline"
          size="sm"
          className="mt-2"
          onClick={() => ingredients.append({ name: "", amount: "" })}
        >
          <Plus className="size-4" />
          Thêm nguyên liệu
        </Button>
      </div>

      <DialogFooter>
        <Button type="button" variant="outline" onClick={onClose} disabled={isSubmitting}>
          Hủy
        </Button>
        <Button type="submit" disabled={isSubmitting}>
          {isSubmitting && <Loader2 className="size-4 animate-spin" />}
          Lưu
        </Button>
      </DialogFooter>
    </form>
  );
}
