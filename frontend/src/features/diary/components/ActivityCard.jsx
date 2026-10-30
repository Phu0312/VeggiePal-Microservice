import { useId, useState } from "react";
import { zodResolver } from "@hookform/resolvers/zod";
import { Activity, Loader2, Pencil } from "lucide-react";
import { useForm } from "react-hook-form";
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
import { useUpdateDailyActivity } from "@/features/diary/hooks/useDiary";
import { activitySchema } from "@/features/diary/schema";
import { formatNumber, optionalNumber } from "@/features/diary/utils/diary";

const fieldClass =
  "h-11 w-full rounded-xl border border-border bg-surface px-3.5 text-sm text-ink outline-none transition placeholder:text-subtle focus:border-brand/40 focus:ring-2 focus:ring-brand/15 aria-[invalid=true]:border-destructive/50 aria-[invalid=true]:ring-2 aria-[invalid=true]:ring-destructive/20";
const labelClass = "mb-1.5 block text-sm font-semibold text-ink";

const NUMBER_FIELDS = [
  { name: "exerciseMinutes", label: "Thời gian tập (phút)" },
  { name: "steps", label: "Số bước" },
  { name: "caloriesBurned", label: "Calo đã đốt (kcal)" },
  { name: "waterTargetMl", label: "Mục tiêu nước (ml)" },
];

const toText = (value) => (value == null ? "" : String(value));

/** Vận động trong ngày, sửa qua PUT /nutrition/me/daily-activity (chỉ gửi ô đã điền, ô trống BE giữ nguyên). */
export default function ActivityCard({ date, summary }) {
  const [open, setOpen] = useState(false);

  return (
    <section className="rounded-3xl border border-border bg-card p-5 shadow-sm sm:p-6">
      <div className="flex items-center justify-between gap-3">
        <h2 className="flex items-center gap-2 font-heading text-lg font-bold text-ink">
          <Activity className="size-5 text-chart-3" />
          Vận động
        </h2>
        <Button type="button" variant="ghost" size="sm" onClick={() => setOpen(true)}>
          <Pencil className="size-4" />
          Cập nhật
        </Button>
      </div>
      <dl className="mt-3 grid grid-cols-2 gap-3 text-sm">
        <div className="rounded-2xl bg-surface px-3.5 py-2.5">
          <dt className="text-xs text-subtle">Thời gian tập</dt>
          <dd className="font-semibold text-ink">{formatNumber(summary.exerciseMinutes ?? 0)} phút</dd>
        </div>
        <div className="rounded-2xl bg-surface px-3.5 py-2.5">
          <dt className="text-xs text-subtle">Số bước</dt>
          <dd className="font-semibold text-ink">{formatNumber(summary.steps ?? 0)}</dd>
        </div>
      </dl>
      {summary.activityNote && <p className="mt-3 text-sm text-body">{summary.activityNote}</p>}

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent>
          {open && <ActivityForm date={date} summary={summary} onClose={() => setOpen(false)} />}
        </DialogContent>
      </Dialog>
    </section>
  );
}

function ActivityForm({ date, summary, onClose }) {
  const idPrefix = useId();
  const updateActivity = useUpdateDailyActivity();
  const {
    register,
    handleSubmit,
    setError,
    formState: { errors, isSubmitting },
  } = useForm({
    resolver: zodResolver(activitySchema),
    defaultValues: {
      exerciseMinutes: toText(summary.exerciseMinutes),
      steps: toText(summary.steps),
      caloriesBurned: toText(summary.caloriesBurned),
      waterTargetMl: toText(summary.waterTargetMl),
      activityNote: summary.activityNote ?? "",
    },
  });

  const onSubmit = async (values) => {
    try {
      await updateActivity.mutateAsync({
        date,
        exerciseMinutes: optionalNumber(values.exerciseMinutes),
        steps: optionalNumber(values.steps),
        caloriesBurned: optionalNumber(values.caloriesBurned),
        waterTargetMl: optionalNumber(values.waterTargetMl),
        activityNote: values.activityNote,
      });
      toast.success("Đã cập nhật vận động");
      onClose();
    } catch (error) {
      setError("root", { message: error.message });
    }
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} noValidate className="flex flex-col gap-4">
      <DialogHeader>
        <DialogTitle>Cập nhật vận động</DialogTitle>
        <DialogDescription>Ô để trống giữ nguyên giá trị đã lưu.</DialogDescription>
      </DialogHeader>
      {errors.root && (
        <p role="alert" className="rounded-xl bg-destructive/10 px-3 py-2 text-sm text-destructive">
          {errors.root.message}
        </p>
      )}
      <div className="grid grid-cols-2 gap-3">
        {NUMBER_FIELDS.map((field) => (
          <div key={field.name}>
            <label htmlFor={`${idPrefix}-${field.name}`} className={labelClass}>
              {field.label}
            </label>
            <input
              id={`${idPrefix}-${field.name}`}
              inputMode="numeric"
              className={fieldClass}
              aria-invalid={Boolean(errors[field.name])}
              {...register(field.name)}
            />
            {errors[field.name] && <p className="mt-1 text-xs text-destructive">{errors[field.name].message}</p>}
          </div>
        ))}
      </div>
      <div>
        <label htmlFor={`${idPrefix}-note`} className={labelClass}>
          Ghi chú
        </label>
        <input
          id={`${idPrefix}-note`}
          className={fieldClass}
          placeholder="VD: Chạy bộ 3 km buổi sáng"
          aria-invalid={Boolean(errors.activityNote)}
          {...register("activityNote")}
        />
        {errors.activityNote && <p className="mt-1 text-xs text-destructive">{errors.activityNote.message}</p>}
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
