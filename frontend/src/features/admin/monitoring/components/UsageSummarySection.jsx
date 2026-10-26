import { Activity, Gauge, MessageSquareText, Sparkles, TriangleAlert } from "lucide-react";

import { useUsageSummary } from "@/features/admin/monitoring/hooks/useMonitoring";
import { failureRate, formatNumber } from "@/features/admin/monitoring/utils/monitoringFormat";
import { cn } from "@/lib/utils";

const TONE_CLASS = {
  brand: "bg-brand-soft text-brand",
  "chart-2": "bg-chart-2/15 text-chart-2",
  "chart-4": "bg-chart-4/15 text-chart-4",
  "chart-5": "bg-chart-5/15 text-chart-5",
  destructive: "bg-destructive/10 text-destructive",
};

// Số liệu tổng hợp lượt dùng AI trong `days` ngày gần nhất (GET /ai/admin/monitoring/summary).
export default function UsageSummarySection({ days }) {
  const { data, isPending, isError, error } = useUsageSummary(days);

  if (isError) {
    return <p className="rounded-xl bg-destructive/10 px-3 py-2 text-sm text-destructive">{error.message}</p>;
  }

  const rate = failureRate(data);
  const cards = [
    { icon: Activity, label: "Tổng số request", value: formatNumber(data?.requests), tone: "brand" },
    {
      icon: MessageSquareText,
      label: "Token đầu vào",
      value: formatNumber(data?.promptTokens),
      tone: "chart-2",
    },
    { icon: Sparkles, label: "Token đầu ra", value: formatNumber(data?.completionTokens), tone: "chart-5" },
    {
      icon: Gauge,
      label: "Độ trễ trung bình",
      value: data ? `${formatNumber(data.averageLatencyMs)} ms` : null,
      tone: "chart-4",
    },
    {
      icon: TriangleAlert,
      label: "Request thất bại",
      value: formatNumber(data?.failedRequests),
      note: rate ? `${rate} tổng số request` : undefined,
      tone: "destructive",
    },
  ];

  return (
    <section aria-label="Tổng hợp sử dụng AI" className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-5">
      {cards.map(({ icon: Icon, label, value, note, tone }) => (
        <div key={label} className="rounded-3xl border border-border bg-card p-5 shadow-sm">
          <span className={cn("grid size-10 place-items-center rounded-2xl", TONE_CLASS[tone])}>
            <Icon className="size-5" />
          </span>
          <p className="mt-4 text-2xl font-bold tabular-nums text-ink">
            {isPending ? <span className="inline-block h-8 w-16 animate-pulse rounded bg-surface align-middle" /> : value}
          </p>
          <p className="mt-1 text-sm text-subtle">{label}</p>
          {note && <p className="mt-2 text-xs text-subtle">{note}</p>}
        </div>
      ))}
    </section>
  );
}
