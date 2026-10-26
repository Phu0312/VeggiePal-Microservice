import { useState } from "react";
import { RefreshCw } from "lucide-react";
import { useIsFetching, useQueryClient } from "@tanstack/react-query";

import { Button } from "@/components/ui/button";
import ModelsLimitsSection from "@/features/admin/monitoring/components/ModelsLimitsSection";
import UsageLogsSection from "@/features/admin/monitoring/components/UsageLogsSection";
import UsageSummarySection from "@/features/admin/monitoring/components/UsageSummarySection";
import { monitoringKeys } from "@/features/admin/monitoring/queryKeys";
import { DAY_OPTIONS } from "@/features/admin/monitoring/utils/monitoringFormat";
import { cn } from "@/lib/utils";

// Trang giám sát AI (/admin/ai-monitoring): lượt dùng, token, độ trễ, lỗi của ai-service,
// model đang dùng, giới hạn quota và nhật ký từng lượt gọi.
export default function AdminAiMonitoringScreen() {
  const [days, setDays] = useState(7);
  const queryClient = useQueryClient();
  const fetching = useIsFetching({ queryKey: monitoringKeys.all }) > 0;

  return (
    <div className="flex flex-col gap-8">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h1 className="font-heading text-3xl font-bold text-ink">Giám sát AI</h1>
          <p className="mt-1 text-sm text-subtle">
            Theo dõi lượt dùng, token, độ trễ và lỗi của các tính năng AI (chatbot, thực đơn, kiểm duyệt, gợi ý, video).
          </p>
        </div>
        <Button
          type="button"
          variant="outline"
          size="sm"
          disabled={fetching}
          onClick={() => queryClient.invalidateQueries({ queryKey: monitoringKeys.all })}
        >
          <RefreshCw className={cn("size-4", fetching && "animate-spin")} />
          Làm mới
        </Button>
      </div>

      <div className="flex flex-col gap-3">
        <div role="group" aria-label="Khoảng thời gian tổng hợp" className="flex items-center gap-2">
          {DAY_OPTIONS.map(({ value, label }) => (
            <button
              key={value}
              type="button"
              aria-pressed={days === value}
              onClick={() => setDays(value)}
              className={cn(
                "rounded-full px-4 py-2 text-sm font-medium transition",
                days === value ? "bg-brand text-brand-foreground" : "bg-surface text-subtle hover:text-ink",
              )}
            >
              {label}
            </button>
          ))}
        </div>
        <UsageSummarySection days={days} />
      </div>

      <ModelsLimitsSection />

      <UsageLogsSection />
    </div>
  );
}
