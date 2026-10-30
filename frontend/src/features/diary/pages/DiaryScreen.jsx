import { useId, useState } from "react";
import { ChevronLeft, ChevronRight, Loader2, NotebookPen, RotateCw } from "lucide-react";

import { Button } from "@/components/ui/button";
import ActivityCard from "@/features/diary/components/ActivityCard";
import AddFoodDialog from "@/features/diary/components/AddFoodDialog";
import DiarySummaryCard from "@/features/diary/components/DiarySummaryCard";
import MealList from "@/features/diary/components/MealList";
import ProfileIncompleteCard from "@/features/diary/components/ProfileIncompleteCard";
import WaterCard from "@/features/diary/components/WaterCard";
import { useDailySummary } from "@/features/diary/hooks/useDiary";
import {
  dayLabel,
  loadGoalType,
  mealForHour,
  parseIsoDate,
  saveGoalType,
  shiftIsoDate,
  toIsoDate,
} from "@/features/diary/utils/diary";
import { GOAL_OPTIONS } from "@/features/meal-planner/utils/mealPlan";
import { cn } from "@/lib/utils";
import AppHeader from "@/shared/components/AppHeader";

// Trang "Nhật ký dinh dưỡng" (route /diary, cần đăng nhập; liên kết đặt ở trang Hồ sơ):
// ghi món theo bữa, nước, vận động trong ngày và so với mục tiêu calo BE tính theo hồ sơ + mục tiêu đang chọn.
export default function DiaryScreen() {
  const dateInputId = useId();
  const today = toIsoDate(new Date());
  const [date, setDate] = useState(today);
  const [goalType, setGoalType] = useState(loadGoalType);
  const [addMeal, setAddMeal] = useState(null);
  const { summary, loading, error, errorCode, refetch, refetching } = useDailySummary(date, goalType);

  const chooseGoal = (value) => {
    setGoalType(value);
    saveGoalType(value);
  };

  // Không ghi nhật ký cho ngày tương lai.
  const pickDate = (value) => {
    if (parseIsoDate(value) && value <= today) setDate(value);
  };

  const needsProfile = errorCode === 2013 || errorCode === 2014;
  const currentGoal = GOAL_OPTIONS.find((option) => option.value === goalType);

  return (
    <div className="min-h-dvh bg-canvas">
      <AppHeader />

      <main className="mx-auto flex w-full max-w-4xl flex-col gap-6 px-4 py-6 sm:px-6 lg:px-8">
        <div>
          <h1 className="flex items-center gap-2 font-heading text-3xl font-bold text-ink">
            <NotebookPen className="size-7 text-brand" />
            Nhật ký dinh dưỡng
          </h1>
          <p className="mt-1 text-sm text-subtle">
            Ghi lại món đã ăn, nước và vận động mỗi ngày để so với mục tiêu calo tính theo hồ sơ của bạn.
          </p>
        </div>

        <div className="flex flex-col gap-3 rounded-3xl border border-border bg-card p-4 shadow-sm sm:flex-row sm:items-center sm:justify-between">
          <div className="flex items-center gap-2">
            <Button
              type="button"
              variant="outline"
              size="icon"
              aria-label="Ngày trước"
              onClick={() => pickDate(shiftIsoDate(date, -1))}
            >
              <ChevronLeft className="size-4" />
            </Button>
            <div className="min-w-0">
              <p className="text-sm font-semibold text-ink">{dayLabel(date, today)}</p>
              <label htmlFor={dateInputId} className="sr-only">
                Chọn ngày
              </label>
              <input
                id={dateInputId}
                type="date"
                value={date}
                max={today}
                onChange={(event) => pickDate(event.target.value)}
                className="bg-transparent text-xs text-subtle outline-none"
              />
            </div>
            <Button
              type="button"
              variant="outline"
              size="icon"
              aria-label="Ngày sau"
              disabled={date >= today}
              onClick={() => pickDate(shiftIsoDate(date, 1))}
            >
              <ChevronRight className="size-4" />
            </Button>
          </div>

          <div role="radiogroup" aria-label="Mục tiêu calo" className="flex flex-wrap gap-2">
            {GOAL_OPTIONS.map((option) => (
              <button
                key={option.value}
                type="button"
                role="radio"
                aria-checked={goalType === option.value}
                onClick={() => chooseGoal(option.value)}
                className={cn(
                  "rounded-full px-4 py-2 text-sm font-medium transition",
                  goalType === option.value
                    ? "bg-brand text-brand-foreground"
                    : "bg-surface text-subtle hover:text-ink"
                )}
              >
                {option.label}
              </button>
            ))}
          </div>
        </div>
        {currentGoal && <p className="-mt-3 text-xs text-subtle">Mục tiêu: {currentGoal.hint}.</p>}

        {loading ? (
          <p className="flex items-center gap-2 text-sm text-subtle">
            <Loader2 className="size-4 animate-spin" />
            Đang tải nhật ký...
          </p>
        ) : needsProfile ? (
          <ProfileIncompleteCard message={error} underage={errorCode === 2014} />
        ) : error ? (
          <div className="flex flex-col items-start gap-3 rounded-3xl border border-border bg-card p-5 shadow-sm">
            <p className="rounded-xl bg-destructive/10 px-3 py-2 text-sm text-destructive">{error}</p>
            <Button type="button" variant="outline" size="sm" onClick={() => refetch()} disabled={refetching}>
              {refetching ? <Loader2 className="size-4 animate-spin" /> : <RotateCw className="size-4" />}
              Thử lại
            </Button>
          </div>
        ) : (
          summary && (
            <>
              <DiarySummaryCard summary={summary} />
              <MealList date={date} entries={summary.entries} onAdd={setAddMeal} />
              <div className="grid gap-6 md:grid-cols-2">
                <WaterCard date={date} summary={summary} />
                <ActivityCard date={date} summary={summary} />
              </div>
              <div className="flex justify-center">
                <Button type="button" size="md" onClick={() => setAddMeal(mealForHour(new Date().getHours()))}>
                  Ghi món mới
                </Button>
              </div>
            </>
          )
        )}
      </main>

      <AddFoodDialog date={date} mealType={addMeal} onClose={() => setAddMeal(null)} />
    </div>
  );
}
