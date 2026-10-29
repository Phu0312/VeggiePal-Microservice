import { PieChart } from "lucide-react";

import { macroLabels } from "@/features/meal-planner/data/mealPlannerOptions";
import { macroPercentages, toRounded } from "@/features/meal-planner/utils/mealPlan";

const SEGMENT_COLORS = {
  carb: "var(--chart-1)",
  protein: "var(--chart-5)",
  fat: "var(--chart-4)",
};

const SEGMENT_ORDER = ["carb", "protein", "fat"];

/**
 * Thẻ tỉ lệ năng lượng tinh bột / đạm / béo của ngày đang xem, nằm cạnh thẻ BMI và Calo.
 * `totals`: nutritionTotals của ngày (calories, protein, carbohydrate, fat) hoặc null khi chưa có thực đơn.
 */
export default function MacroBalanceCard({ totals }) {
  const percents = macroPercentages(totals);
  const segments = SEGMENT_ORDER.map((id) => ({ id, label: macroLabels[id], value: percents?.[id] ?? 0 }));

  // Mỗi đoạn của biểu đồ bắt đầu ngay sau tổng các đoạn đứng trước nó.
  const stops = percents
    ? segments.map((item, index) => {
        const start = segments.slice(0, index).reduce((sum, prev) => sum + prev.value, 0);
        return `${SEGMENT_COLORS[item.id]} ${start}% ${start + item.value}%`;
      })
    : null;

  return (
    <article
      id="macro-balance"
      className="flex h-full scroll-mt-28 flex-col gap-3 rounded-3xl border border-border bg-card p-5 shadow-sm transition hover:-translate-y-0.5 hover:shadow-lg"
    >
      <div className="flex items-center gap-2 text-sm font-medium text-subtle">
        <span className="grid size-11 shrink-0 place-items-center rounded-2xl bg-gradient-to-br from-brand to-brand-2 text-white shadow-sm">
          <PieChart className="size-5" />
        </span>
        <span className="flex-1">Tỉ lệ Macro</span>
      </div>

      <div className="flex items-center gap-4">
        <div
          className="grid size-24 shrink-0 place-items-center rounded-full bg-surface"
          style={stops ? { background: `conic-gradient(${stops.join(", ")})` } : undefined}
        >
          <div className="flex size-[68px] flex-col items-center justify-center rounded-full bg-card text-center leading-tight">
            <span className="text-sm font-bold text-ink">100%</span>
            <span className="text-[10px] font-medium text-brand">thực vật</span>
          </div>
        </div>

        <ul className="flex min-w-0 flex-col gap-1.5">
          {segments.map((item) => (
            <li key={item.id} className="flex items-center gap-2 text-xs">
              <span className="size-2 shrink-0 rounded-full" style={{ background: SEGMENT_COLORS[item.id] }} />
              <span className="font-semibold text-ink">{percents ? `${item.value}%` : "—"}</span>
              <span className="truncate text-subtle">{item.label}</span>
            </li>
          ))}
        </ul>
      </div>

      <p className="text-xs leading-snug text-subtle">
        {totals
          ? `${toRounded(totals.protein)}g đạm • ${toRounded(totals.carbohydrate)}g tinh bột • ${toRounded(totals.fat)}g béo`
          : "Tạo thực đơn để xem tỉ lệ dinh dưỡng của từng ngày."}
      </p>
    </article>
  );
}
