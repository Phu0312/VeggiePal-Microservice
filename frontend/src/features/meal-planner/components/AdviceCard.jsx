import { CalendarDays, Lightbulb, Settings2 } from "lucide-react";

import { buttonVariants } from "@/components/ui/variants/button-variants";
import iconLeaf from "@/assets/img/icon_leaf.png";
import iconSleep from "@/assets/img/icon_sleep.png";
import iconWater from "@/assets/img/icon_water.png";
import { dailyAdviceStats } from "@/features/meal-planner/data/mockMealPlanner";

const STAT_ICONS = {
  veggie: iconLeaf,
  water: iconWater,
  sleep: iconSleep,
};

export default function AdviceCard() {
  return (
    <article className="flex flex-col rounded-[28px] bg-card p-6 shadow-lg sm:p-7">
      <div className="flex items-center gap-3">
        <span className="grid size-11 shrink-0 place-items-center rounded-full bg-brand-soft text-brand">
          <Lightbulb className="h-5 w-5" />
        </span>
        <h3 className="text-lg font-bold text-ink">Lời Khuyên Của Bé Bông Cải</h3>
      </div>

      <blockquote className="mt-4 rounded-3xl bg-gradient-to-br from-brand-soft to-surface p-5 text-sm italic leading-relaxed text-body">
        "Hãy bắt đầu từ những thay đổi nhỏ như thêm rau xanh vào bữa ăn, uống
        đủ nước và ngủ đủ giấc. Cơ thể khoẻ mạnh không chỉ đến từ thực phẩm, mà
        còn từ thói quen tốt mỗi ngày!" 💚
      </blockquote>

      <div className="mt-4 grid grid-cols-1 gap-2 sm:grid-cols-3">
        {dailyAdviceStats.map((stat) => {
          const icon = STAT_ICONS[stat.id];
          return (
            <div
              key={stat.id}
              className="flex items-center gap-2.5 rounded-2xl bg-surface px-3 py-2.5"
            >
              <img src={icon} alt="" className="h-8 w-8 shrink-0" />
              <span className="flex flex-1 flex-col leading-tight">
                <span className="text-[11px] font-medium text-subtle">
                  {stat.label}
                </span>
                <span className="text-xs font-bold text-ink">{stat.value}</span>
              </span>
            </div>
          );
        })}
      </div>

      <div className="mt-5 flex items-center gap-3">
        {/* Hai nút co giãn theo flex và nhãn có thể xuống dòng nên dùng h-auto + min-h thay vì chiều cao cố định. */}
        <a
          href="#today-meals"
          className={buttonVariants({
            size: "lg",
            className: "h-auto min-h-11 flex-[1.6] shrink whitespace-normal px-2 py-2.5",
          })}
        >
          <CalendarDays className="size-4" />
          Xem Kế Hoạch Chi Tiết
        </a>
        <a
          href="#ai-suggestion"
          className={buttonVariants({
            variant: "secondary",
            size: "lg",
            className: "h-auto min-h-11 flex-1 shrink whitespace-normal px-2 py-2.5",
          })}
        >
          <Settings2 className="size-4" />
          Chỉnh Sửa Nhu Cầu
        </a>
      </div>
    </article>
  );
}
