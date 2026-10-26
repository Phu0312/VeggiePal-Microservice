import { useState } from "react";

import { usePaymentRevenue } from "@/features/admin/payments/hooks/useAdminPayments";
import {
  GROUP_OPTIONS,
  formatNumber,
  formatPeriod,
  formatVnd,
} from "@/features/admin/payments/utils/adminPaymentFormat";
import { cn } from "@/lib/utils";

// Doanh thu theo ngày/tháng, vẽ bằng thanh CSS màu chart-1 (GET /admin/payments/revenue).
export default function RevenueChartSection({ filters, enabled }) {
  const [groupBy, setGroupBy] = useState("DAY");
  const { data, isPending, isError, error } = usePaymentRevenue(filters, groupBy, { enabled });

  const points = data?.points ?? [];
  const max = Math.max(...points.map((p) => p.revenue), 1);

  return (
    <section aria-label="Doanh thu" className="rounded-3xl border border-border bg-card p-5 shadow-sm">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h2 className="font-heading text-xl font-bold text-ink">Doanh thu</h2>
          {data && (
            <p className="mt-1 text-sm text-subtle">
              Tổng {formatVnd(data.totalRevenue)} từ {formatNumber(data.paidTransactions)} đơn đã thanh toán
            </p>
          )}
        </div>
        <div role="group" aria-label="Nhóm doanh thu" className="flex items-center gap-2">
          {GROUP_OPTIONS.map(({ value, label }) => (
            <button
              key={value}
              type="button"
              aria-pressed={groupBy === value}
              onClick={() => setGroupBy(value)}
              className={cn(
                "rounded-full px-4 py-2 text-sm font-medium transition",
                groupBy === value ? "bg-brand text-brand-foreground" : "bg-surface text-subtle hover:text-ink",
              )}
            >
              {label}
            </button>
          ))}
        </div>
      </div>

      {isError ? (
        <p className="mt-4 rounded-xl bg-destructive/10 px-3 py-2 text-sm text-destructive">{error.message}</p>
      ) : isPending ? (
        <div aria-hidden className="mt-4 h-56 animate-pulse rounded-2xl bg-surface" />
      ) : points.length === 0 ? (
        <p className="mt-4 text-sm text-subtle">Chưa có doanh thu trong khoảng đã chọn.</p>
      ) : (
        <div className="mt-6 overflow-x-auto">
          <ul
            className="flex h-56 items-end gap-2"
            style={{ minWidth: `${points.length * 44}px` }}
          >
            {points.map((point) => (
              <li
                key={point.period}
                title={`${point.period}: ${formatVnd(point.revenue)} (${formatNumber(point.transactionCount)} đơn)`}
                className="flex h-full min-w-9 flex-1 flex-col items-center justify-end gap-1"
              >
                <span className="text-[10px] tabular-nums text-subtle">{formatVnd(point.revenue)}</span>
                <div
                  className="w-full rounded-t-lg bg-chart-1 transition-[height]"
                  style={{ height: `${Math.max((point.revenue / max) * 100 * 0.8, point.revenue > 0 ? 2 : 0)}%` }}
                />
                <span className="text-xs tabular-nums text-subtle">{formatPeriod(point.period)}</span>
              </li>
            ))}
          </ul>
        </div>
      )}
    </section>
  );
}
