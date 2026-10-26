import { ShoppingCart } from "lucide-react";
import { toast } from "sonner";

import iconNutrition from "@/assets/img/icon_video_page.png";
import { Button } from "@/components/ui/button";
import { nutritionFacts } from "@/features/video/data/mockVideo";

// Thẻ giá trị dinh dưỡng của video.
// Do BE hiện chưa có endpoint bóc tách dữ liệu dinh dưỡng thật cho video,
// phần này được đánh dấu rõ ràng là dữ liệu mẫu tham khảo.
export default function NutritionFactsCard() {
  const { servingLabel, kcal, protein, fiber, ingredients } = nutritionFacts;

  const handleCopyShoppingList = () => {
    toast.info("Tính năng chép vào giỏ đi chợ đang được phát triển.");
  };

  return (
    <section className="rounded-3xl border border-border bg-card p-5 shadow-sm">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <div className="flex items-center gap-2.5">
          <img src={iconNutrition} alt="" className="size-9 shrink-0" />
          <div>
            <h2 className="text-sm font-bold leading-snug text-ink">
              Giá Trị Dinh Dưỡng
            </h2>
            <span className="text-[11px] font-medium text-subtle">
              (Dữ liệu mẫu tham khảo)
            </span>
          </div>
        </div>
        <span className="rounded-full bg-brand-soft px-2.5 py-1 text-[11px] font-semibold text-brand">
          {servingLabel}
        </span>
      </div>

      <div className="mt-4 grid grid-cols-3 gap-2 text-center">
        <NutritionStat value={kcal} label="Năng lượng (Kcal)" valueClass="text-ink" />
        <NutritionStat value={protein} label="Đạm đậu & nấm" valueClass="text-[#E38B29]" />
        <NutritionStat value={fiber} label="Chất xơ tự nhiên" valueClass="text-[#8A5A00]" />
      </div>

      <ul className="mt-4 flex flex-col gap-2">
        {ingredients.map((item) => (
          <li
            key={item.id}
            className="flex items-center justify-between gap-3 text-xs text-body"
          >
            <span className="flex items-center gap-2">
              <span className="size-1.5 shrink-0 rounded-full bg-brand" />
              {item.name}
            </span>
            <span className="shrink-0 font-medium text-subtle">{item.amount}</span>
          </li>
        ))}
      </ul>

      <Button
        type="button"
        size="md"
        onClick={handleCopyShoppingList}
        className="mt-4 w-full shadow-sm"
      >
        <ShoppingCart className="size-4" />
        Chép vào giỏ đi chợ
      </Button>
    </section>
  );
}

function NutritionStat({ value, label, valueClass }) {
  return (
    <div className="rounded-xl bg-surface px-2 py-2.5">
      <p className={`text-lg font-bold ${valueClass}`}>{value}</p>
      <p className="mt-0.5 text-[10px] leading-tight text-subtle">{label}</p>
    </div>
  );
}
