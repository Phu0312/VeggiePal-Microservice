import { useMemo, useState } from "react";
import { TrendingDown, ChevronRight, ThumbsUp, Loader2 } from "lucide-react";

import { useHealthRecordHistory } from "@/features/profile/hooks/useHealthRecords";
import { bmiInfo } from "@/features/profile/utils/editProfileHelpers";
import {
  calcChartPoints,
  calcTrendAnalysis,
} from "@/features/profile/utils/bmiChartHelpers";

export default function BmiTrackerCard() {
  const [metric, setMetric] = useState("bmi"); // 'bmi' | 'weightKg'
  const { data, isPending, error } = useHealthRecordHistory({ size: 6 });

  // Sắp xếp các bản ghi theo trình tự thời gian (cũ -> mới) để vẽ trục từ trái sang phải
  const records = useMemo(() => {
    return [...(data ?? [])].sort(
      (a, b) => new Date(a.recordedAt) - new Date(b.recordedAt)
    );
  }, [data]);

  const hasEnoughData = records.length >= 2;
  const chartData = hasEnoughData ? calcChartPoints(records, metric, 500, 120) : null;
  const trend = hasEnoughData ? calcTrendAnalysis(records, metric) : null;

  const latestRecord = records[records.length - 1];
  const latestBmi = bmiInfo(latestRecord?.bmi);
  const latestValue = latestRecord
    ? Number(latestRecord[metric] ?? 0).toFixed(1)
    : "—";

  return (
    <div className="bg-card rounded-3xl p-6 shadow-sm border border-border">
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-2 mb-6">
        <div>
          <div className="flex items-center gap-2">
            <TrendingDown className="w-4 h-4 text-brand" />
            <h3 className="font-bold text-sm text-ink">
              Theo Dõi Thể Trạng &amp; BMI
            </h3>
          </div>
          <p className="text-[11px] text-subtle mt-0.5">
            {latestRecord ? (
              metric === "bmi" ? (
                `Thuật toán AI đề xuất giúp duy trì thể trạng ${latestValue} (${latestBmi.text})`
              ) : (
                `Cân nặng hiện tại: ${latestValue} kg`
              )
            ) : (
              "Chưa có dữ liệu thể trạng"
            )}
          </p>
        </div>

        {/* Toggle BMI / Cân nặng (kg) */}
        <div className="flex items-center bg-surface p-1 rounded-xl text-[11px] font-semibold text-body">
          <button
            type="button"
            onClick={() => setMetric("bmi")}
            className={`px-3 py-1 rounded-lg transition-colors cursor-pointer ${
              metric === "bmi"
                ? "bg-card shadow-2xs text-ink"
                : "hover:text-ink"
            }`}
          >
            BMI
          </button>
          <button
            type="button"
            onClick={() => setMetric("weightKg")}
            className={`px-3 py-1 rounded-lg transition-colors cursor-pointer ${
              metric === "weightKg"
                ? "bg-card shadow-2xs text-ink"
                : "hover:text-ink"
            }`}
          >
            Cân nặng (kg)
          </button>
        </div>
      </div>

      {isPending ? (
        <div className="flex items-center justify-center gap-2 py-14 text-xs text-subtle">
          <Loader2 className="w-4 h-4 animate-spin text-brand" />
          Đang tải dữ liệu thể trạng…
        </div>
      ) : error ? (
        <p className="rounded-xl bg-destructive/10 px-3 py-2 text-xs text-destructive">
          {error.message || "Không tải được lịch sử sức khỏe"}
        </p>
      ) : !hasEnoughData || !chartData ? (
        <div className="flex items-center justify-center rounded-2xl border border-dashed border-border py-12 text-xs text-subtle">
          Chưa đủ dữ liệu để vẽ biểu đồ
        </div>
      ) : (
        <>
          {/* Biểu đồ SVG với điểm và path tính toán từ dữ liệu thật */}
          <div className="w-full h-44 relative mb-4">
            <svg
              className="w-full h-full overflow-visible"
              viewBox="0 0 500 120"
              preserveAspectRatio="none"
            >
              <defs>
                <linearGradient id="bmiTrackerGradient" x1="0" y1="0" x2="0" y2="1">
                  <stop
                    offset="0%"
                    className="text-brand"
                    stopColor="currentColor"
                    stopOpacity="0.25"
                  />
                  <stop
                    offset="100%"
                    className="text-brand"
                    stopColor="currentColor"
                    stopOpacity="0.0"
                  />
                </linearGradient>
              </defs>

              {/* Vùng mờ bên dưới đường biểu đồ */}
              <path d={chartData.areaPath} fill="url(#bmiTrackerGradient)" />

              {/* Đường line biểu đồ */}
              <path
                d={chartData.linePath}
                fill="none"
                stroke="currentColor"
                className="text-brand"
                strokeWidth="3.5"
                strokeLinecap="round"
              />

              {/* Các điểm đo trên biểu đồ */}
              {chartData.points.map((p, i) => (
                <circle
                  key={records[i]?.id ?? i}
                  cx={p.x}
                  cy={p.y}
                  r={p.isLast ? 5.5 : 4.5}
                  stroke="currentColor"
                  strokeWidth="2"
                  className={
                    p.isLast
                      ? "fill-brand text-card"
                      : "fill-brand/70 text-card"
                  }
                />
              ))}
            </svg>

            {/* Nhãn trục thời gian */}
            <div className="flex justify-between text-[10px] text-subtle mt-2 font-medium">
              {chartData.points.map((p, i) => (
                <span key={records[i]?.id ?? i} className={p.isLast ? "font-bold text-body" : ""}>
                  {p.date} ({p.value.toFixed(1)})
                </span>
              ))}
            </div>
          </div>

          {/* Nhận xét AI dựa trên dữ liệu thật */}
          {trend && (
            <div className="p-3 bg-brand-soft rounded-2xl border border-brand/20 flex items-center justify-between text-xs text-body">
              <div className="flex items-center gap-2">
                <ThumbsUp className="w-4 h-4 text-brand shrink-0" />
                <span className="text-[11px] leading-tight">
                  <strong className="text-ink">{trend.highlight}:</strong> {trend.detail}
                </span>
              </div>
              <button
                type="button"
                className="text-[11px] font-semibold text-brand hover:underline flex items-center gap-0.5 shrink-0 cursor-pointer"
              >
                Xem chi tiết phân tích AI <ChevronRight className="w-3.5 h-3.5" />
              </button>
            </div>
          )}
        </>
      )}
    </div>
  );
}