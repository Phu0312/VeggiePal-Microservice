import { Banknote, CheckCircle2, Clock, Receipt, TriangleAlert, Wallet } from "lucide-react";

import { usePaymentSummary } from "@/features/admin/payments/hooks/useAdminPayments";
import { formatNumber, formatVnd } from "@/features/admin/payments/utils/adminPaymentFormat";
import { cn } from "@/lib/utils";

const TONE_CLASS = {
  brand: "bg-brand-soft text-brand",
  "chart-1": "bg-chart-1/15 text-chart-1",
  "chart-2": "bg-chart-2/15 text-chart-2",
  "chart-4": "bg-chart-4/15 text-chart-4",
  "chart-5": "bg-chart-5/15 text-chart-5",
  destructive: "bg-destructive/10 text-destructive",
};

// Thẻ tổng quan (GET /admin/payments/summary).
export default function PaymentSummarySection({ filters, enabled }) {
  const { data, isPending, isError, error } = usePaymentSummary(filters, { enabled });

  if (isError) {
    return <p className="rounded-xl bg-destructive/10 px-3 py-2 text-sm text-destructive">{error.message}</p>;
  }

  const cards = [
    { icon: Banknote, label: "Doanh thu", value: formatVnd(data?.totalRevenue), tone: "brand" },
    { icon: Receipt, label: "Tổng giao dịch", value: formatNumber(data?.totalTransactions), tone: "chart-2" },
    { icon: CheckCircle2, label: "Đã thanh toán", value: formatNumber(data?.paidTransactions), tone: "chart-1" },
    { icon: Clock, label: "Chưa thanh toán", value: formatNumber(data?.pendingTransactions), tone: "chart-4" },
    {
      icon: TriangleAlert,
      label: "Huỷ / thất bại",
      value: formatNumber((data?.cancelledTransactions ?? 0) + (data?.failedTransactions ?? 0)),
      note: data ? `${formatNumber(data.cancelledTransactions)} huỷ • ${formatNumber(data.failedTransactions)} thất bại` : undefined,
      tone: "destructive",
    },
    { icon: Wallet, label: "Giá trị TB / đơn đã thanh toán", value: formatVnd(data?.averagePaidAmount), tone: "chart-5" },
  ];

  return (
    <section aria-label="Tổng quan thanh toán" className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3">
      {cards.map(({ icon: Icon, label, value, note, tone }) => (
        <div key={label} className="rounded-3xl border border-border bg-card p-5 shadow-sm">
          <span className={cn("grid size-10 place-items-center rounded-2xl", TONE_CLASS[tone])}>
            <Icon className="size-5" />
          </span>
          <p className="mt-4 text-2xl font-bold tabular-nums text-ink">
            {isPending ? <span className="inline-block h-8 w-24 animate-pulse rounded bg-surface align-middle" /> : value}
          </p>
          <p className="mt-1 text-sm text-subtle">{label}</p>
          {note && <p className="mt-2 text-xs text-subtle">{note}</p>}
        </div>
      ))}
    </section>
  );
}
