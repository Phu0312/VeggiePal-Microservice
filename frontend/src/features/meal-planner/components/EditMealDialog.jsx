import { useState } from "react";
import { Loader2, Utensils } from "lucide-react";
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
import { usePreviewMealEdit, useSaveMealEdit } from "@/features/meal-planner/hooks/useMealPlanMutations";
import {
  buildMealEdits,
  dayLabel,
  dayMacroNotes,
  dayTargetDeviations,
  findDayByKey,
  formatServing,
  MACRO_ROWS,
  mealLabel,
  normalizeDay,
  SERVING_OPTIONS,
  toRounded,
} from "@/features/meal-planner/utils/mealPlan";
import { useRecipeNutrition } from "@/features/recipe/hooks/useRecipeNutrition";
import { useRecipeFeed } from "@/features/recipe/hooks/useRecipes";
import { cn } from "@/lib/utils";
import FallbackImage from "@/shared/components/FallbackImage";

const formatNumber = (value) => (value == null ? "—" : Number(value).toLocaleString("vi-VN"));

/**
 * Hộp thoại tự chỉnh một bữa của thực đơn: chọn món khác từ danh sách gợi ý (công thức đã đăng, bỏ các món đang
 * có trong ngày) và/hoặc đổi khẩu phần, bấm "Xem trước" để BE tính lại dinh dưỡng (chưa lưu), rồi "Lưu thay đổi".
 * Chỉ sửa món / khẩu phần của 3 bữa sẵn có, không thêm hay xóa bữa.
 *
 * Cha chỉ dựng component này khi đang sửa (nên `open` luôn true) và truyền:
 * - plan: MealPlan đang xem; day: ngày đang chọn; meal: bữa trong plan (mealType, recipeId, servingMultiplier?).
 * - current: { title, image } của món hiện tại (cha đã tải chi tiết công thức).
 * - usedRecipeIds: id các món khác đang có trong cùng ngày, để không gợi ý trùng.
 * - onClose: đóng hộp thoại.
 */
export default function EditMealDialog({ plan, day, meal, current, usedRecipeIds, onClose }) {
  const currentMultiplier = Number(meal.servingMultiplier) || 1;
  const [selected, setSelected] = useState({ id: meal.recipeId, title: current.title });
  const [multiplier, setMultiplier] = useState(currentMultiplier);

  const preview = usePreviewMealEdit();
  const save = useSaveMealEdit();

  const feed = useRecipeFeed({ size: 12 });
  const { nutritionById } = useRecipeNutrition(feed.recipes);
  const suggestions = feed.recipes.filter((recipe) => recipe.id !== meal.recipeId && !usedRecipeIds.includes(recipe.id));

  const edits = buildMealEdits({
    day: day.day,
    mealType: meal.mealType,
    currentRecipeId: meal.recipeId,
    currentMultiplier,
    recipeId: selected.id,
    multiplier,
  });
  const changed = edits.length > 0;
  const busy = preview.isPending || save.isPending;

  // Đổi lựa chọn thì kết quả xem trước cũ không còn đúng.
  const choose = (apply) => {
    apply();
    preview.reset();
  };

  const changeSummary = [
    `${dayLabel(day).long} · ${mealLabel(meal.mealType)}`,
    selected.id !== meal.recipeId ? `đổi sang "${selected.title}"` : "chỉnh khẩu phần",
    multiplier !== 1 ? `khẩu phần ${formatServing(multiplier)}` : null,
  ]
    .filter(Boolean)
    .join(", ")
    .replace(", ", ": ");

  const handleSave = async () => {
    try {
      await save.mutateAsync({ planId: plan.id, edits, changeSummary });
      toast.success("Đã lưu thay đổi cho bữa này");
      onClose();
    } catch (err) {
      toast.error(err.message);
    }
  };

  const result = preview.data;
  const newDay = findDayByKey(result?.plan, day.day);
  const newMeal = newDay?.meals?.find((m) => normalizeDay(m.mealType) === normalizeDay(meal.mealType));
  const deviations = dayTargetDeviations(newDay);
  const macroNotes = dayMacroNotes(newDay);

  return (
    <Dialog open onOpenChange={(next) => !next && !save.isPending && onClose()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>
            Chỉnh {mealLabel(meal.mealType)} · {dayLabel(day).long}
          </DialogTitle>
          <DialogDescription>
            Chọn một món khác từ gợi ý hoặc đổi khẩu phần, rồi xem trước dinh dưỡng của cả ngày trước khi lưu.
          </DialogDescription>
        </DialogHeader>

        <section>
          <h3 className="text-sm font-semibold text-ink">Món ăn</h3>
          <ul className="mt-2 flex max-h-64 flex-col gap-2 overflow-y-auto pr-1">
            <RecipeOption
              title={current.title}
              image={current.image}
              note="Món hiện tại"
              selected={selected.id === meal.recipeId}
              onSelect={() => choose(() => setSelected({ id: meal.recipeId, title: current.title }))}
            />
            {suggestions.map((recipe) => (
              <RecipeOption
                key={recipe.id}
                title={recipe.title}
                image={recipe.imageUrl}
                note={describeRecipe(recipe, nutritionById.get(recipe.id))}
                selected={selected.id === recipe.id}
                onSelect={() => choose(() => setSelected({ id: recipe.id, title: recipe.title }))}
              />
            ))}
            {feed.isPending && (
              <li className="flex items-center gap-2 px-2 py-3 text-sm text-subtle">
                <Loader2 className="size-4 animate-spin" />
                Đang tải gợi ý...
              </li>
            )}
            {feed.isError && <li className="px-2 py-3 text-sm text-destructive">Không tải được danh sách gợi ý.</li>}
          </ul>
          {feed.hasNextPage && (
            <Button
              type="button"
              variant="ghost"
              size="sm"
              className="mt-1"
              disabled={feed.isFetchingNextPage}
              onClick={() => feed.fetchNextPage()}
            >
              {feed.isFetchingNextPage && <Loader2 className="size-4 animate-spin" />}
              Xem thêm gợi ý
            </Button>
          )}
        </section>

        <section>
          <h3 className="text-sm font-semibold text-ink">Khẩu phần</h3>
          <div className="mt-2 flex flex-wrap gap-2">
            {SERVING_OPTIONS.map((option) => (
              <button
                key={option}
                type="button"
                aria-pressed={multiplier === option}
                onClick={() => choose(() => setMultiplier(option))}
                className={cn(
                  "rounded-full border px-3 py-1 text-sm font-medium transition",
                  multiplier === option
                    ? "border-brand bg-brand text-brand-foreground"
                    : "border-border text-body hover:bg-surface",
                )}
              >
                {formatServing(option)}
              </button>
            ))}
          </div>
        </section>

        {preview.isError && (
          <p className="rounded-xl bg-destructive/10 px-3 py-2 text-sm text-destructive">{preview.error.message}</p>
        )}

        {result && newDay && (
          <section className="flex flex-col gap-3 text-sm">
            <h3 className="font-semibold text-ink">Dinh dưỡng cả ngày sau khi đổi</h3>
            <div className="overflow-hidden rounded-2xl border border-border">
              <div className="grid grid-cols-3 bg-surface px-3 py-2 text-xs font-semibold text-subtle">
                <span />
                <span className="text-right">Hiện tại</span>
                <span className="text-right">Sau khi đổi</span>
              </div>
              {MACRO_ROWS.map((row) => (
                <div key={row.key} className="grid grid-cols-3 border-t border-border px-3 py-2">
                  <span className="text-body">{row.label}</span>
                  <span className="text-right text-subtle">
                    {formatNumber(toRounded(day.nutritionTotals?.[row.key]))} {row.unit}
                  </span>
                  <span className="text-right font-semibold text-ink">
                    {formatNumber(toRounded(newDay.nutritionTotals?.[row.key]))} {row.unit}
                  </span>
                </div>
              ))}
            </div>
            {newMeal && (
              <p className="text-xs text-subtle">
                Riêng bữa này: {formatNumber(toRounded(newMeal.nutrition?.calories))} kcal, đạm{" "}
                {formatNumber(toRounded(newMeal.nutrition?.protein))}g, tinh bột{" "}
                {formatNumber(toRounded(newMeal.nutrition?.carbohydrate))}g, béo{" "}
                {formatNumber(toRounded(newMeal.nutrition?.fat))}g.
              </p>
            )}
            {deviations.length > 0 && (
              <p className="rounded-xl bg-warning/10 px-3 py-2 text-warning">
                Sau khi đổi, ngày này chưa đạt mục tiêu:{" "}
                {deviations
                  .map((item) => `${item.label.toLowerCase()} ${formatNumber(item.actual)} ${item.unit}`)
                  .join(", ")}
                .
              </p>
            )}
            {macroNotes.length > 0 && (
              <p className="text-xs text-subtle">
                Calo cả ngày vẫn đạt, chỉ lưu ý:{" "}
                {macroNotes
                  .map((item) => `${item.label.toLowerCase()} ${formatNumber(item.actual)} ${item.unit}`)
                  .join(", ")}{" "}
                nằm ngoài khoảng mục tiêu.
              </p>
            )}
          </section>
        )}

        <DialogFooter>
          <Button type="button" variant="ghost" disabled={save.isPending} onClick={onClose}>
            Hủy
          </Button>
          {result ? (
            <Button type="button" disabled={save.isPending} onClick={handleSave}>
              {save.isPending && <Loader2 className="size-4 animate-spin" />}
              Lưu thay đổi
            </Button>
          ) : (
            <Button
              type="button"
              disabled={!changed || busy}
              onClick={() => preview.mutate({ planId: plan.id, edits })}
            >
              {preview.isPending && <Loader2 className="size-4 animate-spin" />}
              Xem trước
            </Button>
          )}
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

// "Khoảng 320 kcal/khẩu phần · 35 phút" (bỏ phần chưa tính được).
function describeRecipe(recipe, nutrition) {
  const minutes = (Number(recipe.prepTime) || 0) + (Number(recipe.cookTime) || 0);
  return [
    nutrition?.kcal ? `Khoảng ${Math.round(nutrition.kcal).toLocaleString("vi-VN")} kcal/khẩu phần` : null,
    minutes > 0 ? `${minutes} phút` : null,
  ]
    .filter(Boolean)
    .join(" · ");
}

function RecipeOption({ title, image, note, selected, onSelect }) {
  return (
    <li>
      <button
        type="button"
        role="radio"
        aria-checked={selected}
        onClick={onSelect}
        className={cn(
          "flex w-full items-center gap-3 rounded-2xl border px-3 py-2 text-left transition",
          selected ? "border-brand bg-brand-soft" : "border-border hover:bg-surface",
        )}
      >
        <FallbackImage
          src={image}
          alt=""
          className="size-12 shrink-0 rounded-xl object-cover"
          loading="lazy"
          fallback={
            <span className="grid size-12 shrink-0 place-items-center rounded-xl bg-surface text-subtle">
              <Utensils className="size-5" />
            </span>
          }
        />
        <span className="min-w-0 flex-1">
          <span className="block truncate text-sm font-semibold text-ink">{title}</span>
          {note && <span className="block truncate text-xs text-subtle">{note}</span>}
        </span>
      </button>
    </li>
  );
}
