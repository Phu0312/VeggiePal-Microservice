import { Clock, Loader2, Pencil, RefreshCw, Scale, Timer, Utensils } from "lucide-react";
import { Link } from "react-router-dom";

import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import FallbackImage from "@/shared/components/FallbackImage";

/**
 * Thẻ một bữa ăn.
 * `meal`: { label, time, title, description, image, prepMinutes, kcal, protein, carb, fat, href?, servingMultiplier? }
 * - servingMultiplier: hệ số khẩu phần riêng của bữa này (BE chọn 0,75 - 2,0 để bữa chạm ngân sách calo; khác 1 thì hiện
 *   nhãn "Khẩu phần ×N"); kcal/macro đã nhân sẵn.
 * - href: có thì tên món dẫn tới trang công thức.
 * - onReplace: có thì hiện nút "Đổi món"; `replacing` đang đổi bữa này, `replaceDisabled` khóa nút
 *   (đang đổi bữa khác hoặc bữa này không đổi được).
 * - onEdit: có thì hiện nút "Tự chọn món / khẩu phần" (mở hộp thoại chỉnh tay), khóa cùng điều kiện với "Đổi món".
 * (Yêu thích là theo cả thực đơn, nút nằm ở TodayMeals chứ không ở từng thẻ món.)
 */
export default function MealCard({
  meal,
  onReplace,
  onEdit,
  replacing = false,
  replaceDisabled = false,
  replaceHint,
}) {
  const title = meal.href ? (
    <Link to={meal.href} className="transition hover:text-brand">
      {meal.title}
    </Link>
  ) : (
    meal.title
  );

  return (
    <article className="flex h-full flex-col overflow-hidden rounded-2xl bg-card shadow-md transition hover:shadow-lg">
      <div className="relative h-40 w-full bg-surface">
        <FallbackImage
          src={meal.image}
          alt={meal.title}
          className="h-full w-full object-cover"
          loading="lazy"
          fallback={
            <div className="grid h-full w-full place-items-center text-subtle">
              <Utensils className="size-8" />
            </div>
          }
        />
        <span className="absolute left-3 top-3 flex items-center gap-1 rounded-full bg-white/95 px-2.5 py-1 text-[11px] font-semibold text-neutral-800 shadow-sm">
          <Clock className="h-3 w-3" />
          {meal.label}
          {meal.time ? ` • ${meal.time}` : ""}
        </span>
        {meal.servingMultiplier > 0 && meal.servingMultiplier !== 1 && (
          <span
            title="Khẩu phần được điều chỉnh để bữa này chạm ngân sách calo, giúp cả ngày đạt mục tiêu của bạn"
            className="absolute bottom-3 left-3 flex items-center gap-1 rounded-full bg-brand px-2 py-1 text-[11px] font-semibold text-brand-foreground shadow-sm"
          >
            <Scale className="h-3 w-3" />
            Khẩu phần ×{meal.servingMultiplier.toLocaleString("vi-VN", { maximumFractionDigits: 2 })}
          </span>
        )}
        {meal.prepMinutes > 0 && (
          <span className="absolute bottom-3 right-3 flex items-center gap-1 rounded-full bg-white/95 px-2 py-1 text-[11px] font-semibold text-neutral-800 shadow-sm">
            <Timer className="h-3 w-3" />
            {meal.prepMinutes} phút
          </span>
        )}
      </div>

      <div className="flex flex-1 flex-col gap-2 p-4">
        <h3 className="text-sm font-bold leading-snug text-ink">{title}</h3>
        {meal.description && <p className="line-clamp-3 text-xs leading-relaxed text-subtle">{meal.description}</p>}

        <div className="mt-auto grid grid-cols-4 gap-1 pt-1 text-center">
          <MacroStat value={meal.kcal} unit="Kcal" />
          <MacroStat value={`${meal.protein}g`} unit="Đạm" valueClass="text-chart-5" />
          <MacroStat value={`${meal.carb}g`} unit="Carb" valueClass="text-chart-1" />
          <MacroStat value={`${meal.fat}g`} unit="Béo" valueClass="text-chart-4" />
        </div>

        {(onReplace || onEdit) && (
          <div className="mt-3 flex flex-col gap-2">
            {onReplace && (
              <Button
                type="button"
                variant="soft"
                className="text-xs"
                disabled={replaceDisabled || replacing}
                title={replaceHint}
                onClick={onReplace}
              >
                {replacing ? <Loader2 className="size-3.5 animate-spin" /> : <RefreshCw className="size-3.5" />}
                {replacing ? "Đang đổi món..." : "Đổi món (AI gợi ý)"}
              </Button>
            )}
            {onEdit && (
              <Button
                type="button"
                variant="outline"
                className="text-xs"
                disabled={replaceDisabled || replacing}
                onClick={onEdit}
              >
                <Pencil className="size-3.5" />
                Tự chọn món / khẩu phần
              </Button>
            )}
          </div>
        )}
      </div>
    </article>
  );
}

function MacroStat({ value, unit, valueClass }) {
  return (
    <div className="flex flex-col">
      <span className={cn("text-xs font-bold", valueClass || "text-ink")}>{value}</span>
      <span className="text-[10px] text-subtle">{unit}</span>
    </div>
  );
}
