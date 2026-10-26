import { Sprout } from "lucide-react";

import iconMacro from "@/assets/img/icon_macro.png";
import { macroLabels } from "@/features/meal-planner/data/mockMealPlanner";
import { macroPercentages, toRounded } from "@/features/meal-planner/utils/mealPlan";

const SEGMENT_COLORS = {
  carb: "var(--chart-1)",
  protein: "var(--chart-5)",
  fat: "var(--chart-4)",
};

const SEGMENT_ORDER = ["carb", "protein", "fat"];

/**
 * Tỉ lệ năng lượng tinh bột / đạm / béo của ngày đang xem.
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
    <article className="rounded-[28px] bg-card p-6 shadow-lg sm:p-7">
      <div className="flex items-center gap-2">
        <span className="grid size-7 shrink-0 place-items-center rounded-full bg-brand-soft text-brand">
          <Sprout className="h-3.5 w-3.5" />
        </span>
        <span className="text-sm font-semibold text-brand">Cân Bằng Dinh Dưỡng</span>
      </div>
      <h3 className="mt-3 text-lg font-bold text-ink">Tỉ lệ Macro Vàng</h3>
      <p className="mt-1 text-sm text-subtle">
        Phù hợp hoàn hảo cho cơ thể, để đạt trạng thái lý tưởng và duy trì sức khoẻ bền vững.
      </p>

      <div className="mt-6 flex flex-wrap items-center justify-between gap-6">
        <div className="flex items-center gap-6">
          <div
            className="relative grid size-32 shrink-0 place-items-center rounded-full bg-surface"
            style={stops ? { background: `conic-gradient(${stops.join(", ")})` } : undefined}
          >
            <div className="flex size-[80px] flex-col items-center justify-center rounded-full bg-card text-center">
              <span className="text-lg font-bold leading-tight text-ink">100%</span>
              <span className="text-[10px] font-medium text-brand">Plant-Power</span>
            </div>
          </div>

          <ul className="flex flex-col gap-2.5">
            {segments.map((item) => (
              <li key={item.id} className="flex items-center gap-2 text-sm">
                <span className="size-2.5 shrink-0 rounded-full" style={{ background: SEGMENT_COLORS[item.id] }} />
                <span className="font-semibold text-ink">{percents ? `${item.value}%` : "—"}</span>
                <span className="text-subtle">{item.label}</span>
              </li>
            ))}
          </ul>
        </div>

        <img src={iconMacro} alt="" className="h-28 w-auto shrink-0 select-none sm:h-32" draggable={false} />
      </div>

      <div className="mt-6 flex items-center justify-between rounded-2xl bg-surface px-4 py-3">
        <span className="text-xs text-subtle">
          {totals ? (
            <>
              Tổng trong ngày:{" "}
              <span className="font-semibold text-ink">
                {toRounded(totals.calories).toLocaleString("en-US")} kcal • {toRounded(totals.protein)}g đạm •{" "}
                {toRounded(totals.carbohydrate)}g tinh bột • {toRounded(totals.fat)}g béo
              </span>
            </>
          ) : (
            "Tạo thực đơn để xem tỉ lệ dinh dưỡng của từng ngày."
          )}
        </span>
      </div>
    </article>
  );
}
