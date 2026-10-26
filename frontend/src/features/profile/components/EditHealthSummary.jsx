import { Heart, User } from "lucide-react";

import { bmiInfo, formatDt } from "@/features/profile/utils/editProfileHelpers";

const tileClass =
  "rounded-2xl border border-border bg-surface p-3.5";
const tileTitleClass =
  "flex justify-between items-center text-[11px] text-subtle font-bold mb-1";

/** 3 ô chiều cao / cân nặng / BMI từ bản ghi mới nhất (BMI do BE tính). */
export default function EditHealthSummary({ latest }) {
  const bmi = bmiInfo(latest?.bmi);
  const measuredAt = latest
    ? `Đo lần gần nhất: ${formatDt(latest.recordedAt)}`
    : "Chưa có dữ liệu đo";

  return (
    <div className="grid grid-cols-1 sm:grid-cols-3 gap-3.5 mb-5">
      <div className={tileClass}>
        <div className={tileTitleClass}>
          <span>CHIỀU CAO</span>
          <User className="h-3.5 w-3.5 text-brand" />
        </div>
        <div className="text-lg font-extrabold text-ink">
          {latest?.heightCm != null ? latest.heightCm : "—"}{" "}
          <span className="text-xs font-normal text-subtle">cm</span>
        </div>
        <span className="text-[10px] text-subtle">{measuredAt}</span>
      </div>

      <div className={tileClass}>
        <div className={tileTitleClass}>
          <span>CÂN NẶNG</span>
          <Heart className="h-3.5 w-3.5 text-brand" />
        </div>
        <div className="text-lg font-extrabold text-ink">
          {latest?.weightKg != null ? latest.weightKg : "—"}{" "}
          <span className="text-xs font-normal text-subtle">kg</span>
        </div>
        <span className="text-[10px] text-subtle">{measuredAt}</span>
      </div>

      <div className={tileClass}>
        <div className={tileTitleClass}>
          <span>CHỈ SỐ BMI</span>
          {bmi.badge && (
            <span className={`rounded-full px-1.5 py-0.2 text-[9px] font-bold ${bmi.badgeClass}`}>
              {bmi.badge}
            </span>
          )}
        </div>
        <div className="flex items-baseline gap-2">
          <span className={`text-lg font-extrabold ${bmi.valueClass}`}>
            {latest?.bmi != null ? Number(latest.bmi).toFixed(1) : "—"}
          </span>
          <span className={`text-[11px] font-semibold ${bmi.textClass}`}>
            {bmi.text !== "—" ? bmi.text : ""}
          </span>
        </div>
        <span className="text-[10px] text-subtle">
          {latest ? `Dải chuẩn: ${bmi.range}` : bmi.range}
        </span>
      </div>
    </div>
  );
}
