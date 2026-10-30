import { useId } from "react";
import { zodResolver } from "@hookform/resolvers/zod";
import { Droplets, Loader2, Plus } from "lucide-react";
import { useForm } from "react-hook-form";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { useAddWater } from "@/features/diary/hooks/useDiary";
import { waterSchema } from "@/features/diary/schema";
import { formatNumber, percentOf } from "@/features/diary/utils/diary";

const QUICK_AMOUNTS = [250, 500];

/** Nước đã uống trong ngày, thêm nhanh 250 / 500 ml hoặc tự nhập (POST /nutrition/me/water, 1 – 5000 ml). */
export default function WaterCard({ date, summary }) {
  const inputId = useId();
  const addWater = useAddWater();
  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm({ resolver: zodResolver(waterSchema), defaultValues: { amountMl: "" } });

  const add = async (amountMl) => {
    try {
      await addWater.mutateAsync({ date, amountMl });
      toast.success(`Đã thêm ${formatNumber(amountMl)} ml nước`);
      reset();
    } catch (error) {
      toast.error(error.message);
    }
  };

  const water = summary.waterMl ?? 0;
  const target = summary.waterTargetMl ?? 0;

  return (
    <section className="rounded-3xl border border-border bg-card p-5 shadow-sm sm:p-6">
      <h2 className="flex items-center gap-2 font-heading text-lg font-bold text-ink">
        <Droplets className="size-5 text-chart-2" />
        Nước
      </h2>
      <p className="mt-2 font-heading text-2xl font-extrabold text-ink">
        {formatNumber(water)}
        <span className="text-sm font-semibold text-subtle"> / {formatNumber(target)} ml</span>
      </p>
      {summary.waterGlasses != null && <p className="text-xs text-subtle">Khoảng {summary.waterGlasses} ly</p>}
      <div className="mt-3 h-2.5 overflow-hidden rounded-full bg-surface">
        <div className="h-full rounded-full bg-chart-2 transition-all" style={{ width: `${percentOf(water, target)}%` }} />
      </div>

      <div className="mt-4 flex flex-wrap gap-2">
        {QUICK_AMOUNTS.map((amount) => (
          <Button
            key={amount}
            type="button"
            variant="soft"
            size="sm"
            disabled={addWater.isPending}
            onClick={() => add(amount)}
          >
            <Plus className="size-4" />
            {amount} ml
          </Button>
        ))}
      </div>

      <form onSubmit={handleSubmit(({ amountMl }) => add(Number(amountMl)))} noValidate className="mt-3 flex gap-2">
        <label htmlFor={inputId} className="sr-only">
          Lượng nước (ml)
        </label>
        <input
          id={inputId}
          inputMode="numeric"
          placeholder="Số ml khác"
          aria-invalid={Boolean(errors.amountMl)}
          className="h-10 w-full rounded-xl border border-border bg-surface px-3.5 text-sm text-ink outline-none transition placeholder:text-subtle focus:border-brand/40 focus:ring-2 focus:ring-brand/15 aria-[invalid=true]:border-destructive/50"
          {...register("amountMl")}
        />
        <Button type="submit" size="sm" className="h-10" disabled={addWater.isPending}>
          {addWater.isPending && <Loader2 className="size-4 animate-spin" />}
          Thêm
        </Button>
      </form>
      {errors.amountMl && <p className="mt-1 text-xs text-destructive">{errors.amountMl.message}</p>}
    </section>
  );
}
