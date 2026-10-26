import { useState } from "react";
import { ChevronDown, TriangleAlert } from "lucide-react";

import { useDayRecipes } from "@/features/meal-planner/hooks/useDayRecipes";
import {
  dayLabel,
  dayTargetDeviations,
  mealLabel,
  normalizeDay,
  sortedDays,
  sortedMeals,
  toRounded,
} from "@/features/meal-planner/utils/mealPlan";
import { cn } from "@/lib/utils";

const formatNumber = (value) => toRounded(value).toLocaleString("vi-VN");

/**
 * Xem nhanh nội dung một thực đơn (hoặc một phiên bản cũ), chỉ đọc: mỗi ngày một dòng kèm năng lượng,
 * bấm vào để xem 3 bữa. `plan` là phần `plan` của BE (có days[].meals và days[].nutritionTotals).
 */
export default function PlanDaysPreview({ plan }) {
  const days = sortedDays({ plan });
  if (days.length === 0) {
    return <p className="rounded-2xl bg-surface px-4 py-3 text-sm text-subtle">Thực đơn này chưa có ngày nào.</p>;
  }

  return (
    <ul className="flex flex-col gap-1.5">
      {days.map((day) => (
        <DayRow key={normalizeDay(day.day)} day={day} />
      ))}
    </ul>
  );
}

function DayRow({ day }) {
  const [open, setOpen] = useState(false);
  const totals = day.nutritionTotals;
  const missed = dayTargetDeviations(day).length > 0;

  return (
    <li className="rounded-2xl border border-border text-sm">
      <button
        type="button"
        onClick={() => setOpen((value) => !value)}
        aria-expanded={open}
        className="flex w-full items-center gap-3 px-3 py-2 text-left"
      >
        <span className="w-16 shrink-0 font-semibold text-ink">{dayLabel(day).long}</span>
        <span className="min-w-0 flex-1 truncate text-xs text-subtle">
          {totals
            ? `${formatNumber(totals.calories)} kcal · đạm ${formatNumber(totals.protein)}g · tinh bột ${formatNumber(
                totals.carbohydrate,
              )}g · béo ${formatNumber(totals.fat)}g`
            : "Chưa có số liệu dinh dưỡng"}
        </span>
        {missed && (
          <TriangleAlert className="size-4 shrink-0 text-warning" aria-label="Chưa đạt mục tiêu dinh dưỡng" />
        )}
        <ChevronDown className={cn("size-4 shrink-0 text-subtle transition", open && "rotate-180")} />
      </button>
      {open && <DayMeals day={day} />}
    </li>
  );
}

// Tách riêng để chỉ tải chi tiết công thức (GET /recipes/:id) khi người dùng mở ngày đó.
function DayMeals({ day }) {
  const meals = sortedMeals(day);
  const recipes = useDayRecipes(meals.map((meal) => meal.recipeId));

  return (
    <ul className="flex flex-col gap-1 border-t border-border px-3 py-2">
      {meals.map((meal) => {
        const { recipe, isPending } = recipes.get(meal.recipeId) ?? {};
        const title = recipe?.title ?? (isPending ? "Đang tải món..." : `Món #${meal.recipeId}`);
        return (
          <li key={normalizeDay(meal.mealType)} className="flex items-baseline justify-between gap-3">
            <span className="min-w-0 truncate text-body">
              <span className="font-medium text-ink">{mealLabel(meal.mealType)}:</span> {title}
            </span>
            <span className="shrink-0 text-xs text-subtle">{formatNumber(meal.nutrition?.calories)} kcal</span>
          </li>
        );
      })}
    </ul>
  );
}
