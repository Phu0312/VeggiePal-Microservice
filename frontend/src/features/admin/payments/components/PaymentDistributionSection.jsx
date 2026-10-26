import { usePaymentStatistics } from "@/features/admin/payments/hooks/useAdminPayments";
import {
  PLAN_BAR_CLASS,
  PLAN_LABELS,
  STATUS_BAR_CLASS,
  STATUS_LABELS,
  formatNumber,
  formatVnd,
} from "@/features/admin/payments/utils/adminPaymentFormat";
import { cn } from "@/lib/utils";

function DistributionCard({ title, items, labels, barClass }) {
  const total = items.reduce((sum, item) => sum + item.count, 0);
  return (
    <div className="rounded-3xl border border-border bg-card p-5 shadow-sm">
      <h3 className="font-heading text-lg font-bold text-ink">{title}</h3>
      {total === 0 ? (
        <p className="mt-4 text-sm text-subtle">Chưa có giao dịch nào trong khoảng đã chọn.</p>
      ) : (
        <>
          <div className="mt-4 flex h-3 overflow-hidden rounded-full bg-surface" role="img" aria-label={title}>
            {items.map((item) => (
              <div
                key={item.key}
                className={cn("h-full", barClass[item.key] ?? "bg-chart-3")}
                style={{ width: `${(item.count / total) * 100}%` }}
              />
            ))}
          </div>
          <ul className="mt-4 flex flex-col gap-2.5">
            {items.map((item) => (
              <li key={item.key} className="flex items-center gap-3 text-sm">
                <span className={cn("size-3 shrink-0 rounded-full", barClass[item.key] ?? "bg-chart-3")} />
                <span className="flex-1 font-medium text-ink">{labels[item.key] ?? item.key}</span>
                <span className="tabular-nums text-body">
                  {formatNumber(item.count)} ({Math.round((item.count / total) * 100)}%)
                </span>
                <span className="w-28 text-right tabular-nums text-subtle">{formatVnd(item.amount)}</span>
              </li>
            ))}
          </ul>
        </>
      )}
    </div>
  );
}

// Phân bố trạng thái & gói (GET /admin/payments/statistics).
export default function PaymentDistributionSection({ filters, enabled }) {
  const { data, isPending, isError, error } = usePaymentStatistics(filters, { enabled });

  if (isError) {
    return <p className="rounded-xl bg-destructive/10 px-3 py-2 text-sm text-destructive">{error.message}</p>;
  }
  if (isPending) {
    return <div aria-hidden className="h-48 animate-pulse rounded-3xl border border-border bg-card" />;
  }

  return (
    <section aria-label="Phân bố giao dịch" className="grid grid-cols-1 gap-4 lg:grid-cols-2">
      <DistributionCard
        title="Phân bố theo trạng thái"
        items={data?.statusDistribution ?? []}
        labels={STATUS_LABELS}
        barClass={STATUS_BAR_CLASS}
      />
      <DistributionCard
        title="Phân bố theo gói"
        items={data?.planDistribution ?? []}
        labels={PLAN_LABELS}
        barClass={PLAN_BAR_CLASS}
      />
    </section>
  );
}
