import { useState } from "react";
import { Plus, Trash2, UtensilsCrossed } from "lucide-react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { useDeleteFoodLog } from "@/features/diary/hooks/useDiary";
import { MEAL_TYPES, formatGram, formatNumber, groupByMeal } from "@/features/diary/utils/diary";
import ConfirmDialog from "@/shared/components/ConfirmDialog";

/** Các món trong ngày theo 4 bữa, mỗi bữa có nút "Thêm món" và xóa từng món. */
export default function MealList({ date, entries, onAdd }) {
  const groups = groupByMeal(entries);
  const deleteFoodLog = useDeleteFoodLog();
  const [pending, setPending] = useState(null);

  const confirmDelete = async () => {
    try {
      await deleteFoodLog.mutateAsync({ id: pending.id, date });
      toast.success("Đã xóa món khỏi nhật ký");
      setPending(null);
    } catch (error) {
      toast.error(error.message);
      // 2010: món không còn (đã xóa ở thiết bị khác) -> đóng hộp thoại, danh sách tự làm mới.
      if (error.code === 2010) setPending(null);
    }
  };

  return (
    <section className="rounded-3xl border border-border bg-card p-5 shadow-sm sm:p-6">
      <h2 className="flex items-center gap-2 font-heading text-lg font-bold text-ink">
        <UtensilsCrossed className="size-5 text-brand" />
        Món đã ăn
      </h2>

      <div className="mt-4 flex flex-col divide-y divide-border">
        {MEAL_TYPES.map(({ value, label }) => {
          const items = groups[value];
          const mealCalories = items.reduce((sum, item) => sum + (item.calories ?? 0), 0);
          return (
            <div key={value} className="py-3 first:pt-0 last:pb-0">
              <div className="flex items-center justify-between gap-3">
                <p className="text-sm font-semibold text-ink">
                  {label}
                  {items.length > 0 && (
                    <span className="ml-2 font-normal text-subtle">{formatNumber(mealCalories)} kcal</span>
                  )}
                </p>
                <Button type="button" variant="ghost" size="sm" onClick={() => onAdd(value)}>
                  <Plus className="size-4" />
                  Thêm món
                </Button>
              </div>
              {items.length === 0 ? (
                <p className="mt-1 text-xs text-subtle">Chưa ghi món nào.</p>
              ) : (
                <ul className="mt-2 flex flex-col gap-2">
                  {items.map((item) => (
                    <li
                      key={item.id}
                      className="flex items-center justify-between gap-3 rounded-2xl bg-surface px-3.5 py-2.5"
                    >
                      <div className="min-w-0">
                        <p className="truncate text-sm font-medium text-ink">{item.foodName}</p>
                        <p className="text-xs text-subtle">
                          {item.calories != null ? `${formatNumber(item.calories)} kcal` : "Chưa rõ calo"}
                          {" · "}Đạm {formatGram(item.proteinG)} g · Tinh bột {formatGram(item.carbsG)} g · Béo{" "}
                          {formatGram(item.fatG)} g
                        </p>
                      </div>
                      <Button
                        type="button"
                        variant="ghost"
                        size="icon-sm"
                        aria-label={`Xóa ${item.foodName}`}
                        onClick={() => setPending(item)}
                      >
                        <Trash2 className="size-4 text-destructive" />
                      </Button>
                    </li>
                  ))}
                </ul>
              )}
            </div>
          );
        })}
      </div>

      <ConfirmDialog
        open={pending !== null}
        onOpenChange={(open) => !open && setPending(null)}
        title="Xóa món khỏi nhật ký?"
        description={pending ? `“${pending.foodName}” sẽ bị xóa khỏi nhật ký ngày này.` : ""}
        loading={deleteFoodLog.isPending}
        onConfirm={confirmDelete}
      />
    </section>
  );
}
