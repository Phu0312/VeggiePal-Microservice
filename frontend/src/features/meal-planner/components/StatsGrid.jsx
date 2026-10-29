import { ChevronRight, Flame, Scale } from "lucide-react";
import { Link } from "react-router-dom";

import MacroBalanceCard from "@/features/meal-planner/components/MacroBalanceCard";
import { toRounded } from "@/features/meal-planner/utils/mealPlan";
import { useLatestHealthRecord } from "@/features/profile/hooks/useHealthRecords";
import { bmiInfo } from "@/features/profile/utils/editProfileHelpers";
import Reveal from "@/shared/components/Reveal";

const ICONS = {
  bmi: Scale,
  fire: Flame,
};

function bmiStat(record, isPending) {
  const bmi = Number(record?.bmi);
  const hasBmi = Number.isFinite(bmi) && bmi > 0;
  const info = bmiInfo(hasBmi ? bmi : null);

  return {
    id: "bmi",
    icon: "bmi",
    label: "Chỉ số BMI",
    value: hasBmi ? bmi.toFixed(1) : "—",
    caption: hasBmi
      ? `${info.text} • chuẩn ${info.range}`
      : isPending
        ? "Đang tải chỉ số..."
        : "Chưa có chỉ số, hãy cập nhật hồ sơ sức khỏe",
    to: hasBmi ? undefined : "/profile/edit",
  };
}

function calorieStat(dayTotals, target, dayLong) {
  const calories = toRounded(dayTotals?.calories);
  const max = Number(target?.maxCalories);
  const min = Number(target?.minCalories);
  const hasMax = Number.isFinite(max) && max > 0;
  const hasMin = Number.isFinite(min) && min > 0;

  let caption = "Chưa có thực đơn, hãy nhờ VeggiePal lên thực đơn nhé";
  if (dayTotals) {
    if (hasMax && hasMin) caption = `Mục tiêu ${min.toLocaleString("en-US")} - ${max.toLocaleString("en-US")} kcal/ngày`;
    else if (hasMax) caption = `Mục tiêu tối đa ${max.toLocaleString("en-US")} kcal/ngày`;
    else caption = `Tổng năng lượng ${dayLong} theo thực đơn`;
  }

  return {
    id: "calo",
    icon: "fire",
    label: "Calo Trong Ngày",
    value: dayTotals ? calories.toLocaleString("en-US") : "—",
    unit: hasMax && dayTotals ? `/ ${max.toLocaleString("en-US")} kcal` : dayTotals ? "kcal" : undefined,
    caption,
  };
}

/**
 * Ba thẻ đầu trang: BMI, Calo và tỉ lệ Macro của ngày đang xem.
 * - BMI: thật, từ nutrition-service (bản ghi sức khỏe mới nhất).
 * - Calo: thật, tổng calo của ngày đang xem trong thực đơn.
 * `dayTotals`: nutritionTotals của ngày đang xem; `target`: dailyNutritionTarget của thực đơn.
 */
export default function StatsGrid({ dayTotals, target, dayLong = "hôm nay" }) {
  const { data: latestRecord, isPending } = useLatestHealthRecord();
  const stats = [bmiStat(latestRecord, isPending), calorieStat(dayTotals, target, dayLong)];

  return (
    <section className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
      {stats.map((stat, index) => (
        <Reveal key={stat.id} delay={index * 80} className="h-full">
          <article className="flex h-full flex-col gap-3 rounded-3xl border border-border bg-card p-5 shadow-sm transition hover:-translate-y-0.5 hover:shadow-lg">
            <StatHeader stat={stat} />

            <div className="flex items-baseline gap-1.5">
              <span className="text-2xl font-bold text-ink">{stat.value}</span>
              {stat.unit && <span className="text-sm font-medium text-subtle">{stat.unit}</span>}
            </div>

            <p className="mt-auto text-xs leading-snug text-subtle">{stat.caption}</p>
          </article>
        </Reveal>
      ))}
      <Reveal delay={stats.length * 80} className="h-full">
        <MacroBalanceCard totals={dayTotals ?? null} />
      </Reveal>
    </section>
  );
}

// Thẻ BMI chưa có số liệu dẫn sang trang cập nhật hồ sơ; thẻ còn lại chỉ hiển thị.
function StatHeader({ stat }) {
  const Icon = ICONS[stat.icon];
  const content = (
    <>
      <span className="grid size-11 shrink-0 place-items-center rounded-2xl bg-gradient-to-br from-brand to-brand-2 text-white shadow-sm">
        <Icon className="size-5" />
      </span>
      <span className="flex-1">{stat.label}</span>
      {stat.to && <ChevronRight className="h-4 w-4" />}
    </>
  );
  const className = "flex items-center gap-2 text-left text-sm font-medium text-subtle";

  if (stat.to) {
    return (
      <Link to={stat.to} className={`${className} transition hover:text-ink`}>
        {content}
      </Link>
    );
  }
  return <div className={className}>{content}</div>;
}
