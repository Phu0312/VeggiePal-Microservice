import { Flame } from "lucide-react";

import { formatGram, formatNumber, percentOf } from "@/features/diary/utils/diary";
import { cn } from "@/lib/utils";

// Màu macro theo quy ước chart-*: carb chart-1, béo chart-4, đạm chart-5.
const MACROS = [
  { key: "proteinG", target: "targetProteinG", label: "Đạm", bar: "bg-chart-5" },
  { key: "carbsG", target: "targetCarbsG", label: "Tinh bột", bar: "bg-chart-1" },
  { key: "fatG", target: "targetFatG", label: "Chất béo", bar: "bg-chart-4" },
];

/** Calo đã nạp so với mục tiêu (BE tính theo hồ sơ + mục tiêu đang chọn) và 3 macro chính. */
export default function DiarySummaryCard({ summary }) {
  const consumed = summary.consumedCalories ?? 0;
  const target = summary.targetCalories ?? 0;
  const over = target > 0 && consumed > target;

  return (
    <section className="rounded-3xl border border-border bg-card p-5 shadow-sm sm:p-6">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <p className="flex items-center gap-1.5 text-sm font-semibold text-subtle">
            <Flame className="size-4 text-warning" />
            Calo đã nạp
          </p>
          <p className="mt-1 font-heading text-3xl font-extrabold text-ink">
            {formatNumber(consumed)}
            <span className="text-base font-semibold text-subtle"> / {formatNumber(target)} kcal</span>
          </p>
        </div>
        <dl className="grid grid-cols-2 gap-x-6 gap-y-1 text-sm">
          <dt className="text-subtle">Còn lại</dt>
          <dd className={cn("text-right font-semibold", over ? "text-warning" : "text-ink")}>
            {over ? `Vượt ${formatNumber(consumed - target)}` : formatNumber(summary.remainingCalories ?? 0)} kcal
          </dd>
          <dt className="text-subtle">Đã đốt (vận động)</dt>
          <dd className="text-right font-semibold text-ink">{formatNumber(summary.caloriesBurned ?? 0)} kcal</dd>
        </dl>
      </div>

      <div className="mt-4 h-3 overflow-hidden rounded-full bg-surface" role="progressbar" aria-valuemin={0} aria-valuemax={100} aria-valuenow={percentOf(consumed, target)} aria-label="Tiến độ calo">
        <div
          className={cn("h-full rounded-full transition-all", over ? "bg-warning" : "bg-brand")}
          style={{ width: `${percentOf(consumed, target)}%` }}
        />
      </div>

      <div className="mt-5 grid gap-4 sm:grid-cols-3">
        {MACROS.map((macro) => (
          <div key={macro.key}>
            <div className="flex items-baseline justify-between text-sm">
              <span className="font-semibold text-ink">{macro.label}</span>
              <span className="text-subtle">
                {formatGram(summary[macro.key])} / {formatGram(summary[macro.target])} g
              </span>
            </div>
            <div className="mt-1.5 h-2 overflow-hidden rounded-full bg-surface">
              <div
                className={cn("h-full rounded-full", macro.bar)}
                style={{ width: `${percentOf(summary[macro.key], summary[macro.target])}%` }}
              />
            </div>
          </div>
        ))}
      </div>
      <p className="mt-4 text-xs text-subtle">
        Chất xơ: {formatGram(summary.fiberG)} g. Mục tiêu calo chỉ là gợi ý, không thay thế tư vấn của chuyên gia dinh
        dưỡng.
      </p>
    </section>
  );
}
