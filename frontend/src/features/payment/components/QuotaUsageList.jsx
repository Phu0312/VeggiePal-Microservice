import { CalendarClock, ChefHat, Loader2, MessageCircle, Video } from "lucide-react";

import { useMyQuotas } from "@/features/payment/hooks/useMyQuotas";
import { cn } from "@/lib/utils";

const FEATURES = [
  { key: "mealPlan", label: "Thực đơn AI", icon: ChefHat },
  { key: "chat", label: "Hỏi đáp trợ lý", icon: MessageCircle },
  { key: "video", label: "Bóc tách video", icon: Video },
];

const PERIOD_LABELS = { DAILY: "hôm nay", MONTHLY: "tháng này" };

// resetsAt là LocalDate "YYYY-MM-DD": đọc thẳng các phần, không qua Date để khỏi lệch múi giờ.
function formatLocalDate(value) {
  const [y, m, d] = String(value).split("-");
  return d ? `${d}/${m}/${y}` : value;
}

/**
 * Lượt đã dùng / còn lại của từng tính năng AI theo gói (GET /ai/quotas/me).
 * Dùng ở trang Gói dịch vụ, trang thanh toán và trang Hồ sơ. `compact` xếp một cột (khung hẹp).
 */
export default function QuotaUsageList({ className, compact = false }) {
  const { quotas, loading, error } = useMyQuotas();

  if (loading) {
    return (
      <p className={cn("flex items-center gap-2 text-sm text-subtle", className)}>
        <Loader2 className="size-4 animate-spin" />
        Đang tải hạn mức...
      </p>
    );
  }
  if (error || !quotas) {
    return error ? <p className={cn("text-sm text-subtle", className)}>{error}</p> : null;
  }

  return (
    <ul className={cn("grid gap-3", !compact && "sm:grid-cols-3", className)}>
      {FEATURES.map(({ key, label, icon: Icon }) => {
        const item = quotas[key];
        if (!item) return null;
        const limit = item.limit ?? 0;
        const used = item.used ?? 0;
        const percent = limit > 0 ? Math.min(100, Math.round((used / limit) * 100)) : 100;
        const exhausted = (item.remaining ?? 0) <= 0;
        return (
          <li key={key} className="rounded-2xl bg-surface px-4 py-3">
            <p className="flex items-center gap-1.5 text-sm font-semibold text-ink">
              <Icon className="size-4 text-brand" />
              {label}
            </p>
            <p className="mt-1 text-xs text-subtle">
              {limit > 0
                ? `Còn ${item.remaining}/${limit} lượt ${PERIOD_LABELS[item.period] ?? ""}`
                : "Gói hiện tại chưa có lượt"}
            </p>
            <div className="mt-2 h-1.5 overflow-hidden rounded-full bg-border/60">
              <div
                className={cn("h-full rounded-full", exhausted ? "bg-warning" : "bg-brand")}
                style={{ width: `${percent}%` }}
              />
            </div>
            {item.resetsAt && limit > 0 && (
              <p className="mt-1.5 flex items-center gap-1 text-[11px] text-subtle">
                <CalendarClock className="size-3" />
                Làm mới ngày {formatLocalDate(item.resetsAt)}
              </p>
            )}
          </li>
        );
      })}
    </ul>
  );
}
