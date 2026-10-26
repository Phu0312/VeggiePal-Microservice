import { useState } from "react";
import { ChevronLeft, ChevronRight, Eye } from "lucide-react";

import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { useAdminOrder, useAdminOrders } from "@/features/admin/payments/hooks/useAdminPayments";
import {
  PLAN_LABELS,
  STATUS_LABELS,
  formatDateTime,
  formatNumber,
  formatVnd,
  getPaymentStatusInfo,
  toOptions,
} from "@/features/admin/payments/utils/adminPaymentFormat";
import { cn } from "@/lib/utils";
import SelectField from "@/shared/components/SelectField";

const PAGE_SIZE = 20;
const STATUS_OPTIONS = toOptions(STATUS_LABELS, "Mọi trạng thái");

function StatusBadge({ status }) {
  const info = getPaymentStatusInfo(status);
  return (
    <span className={cn("inline-flex rounded-full border px-2 py-0.5 text-[11px] font-medium", info.className)}>
      {info.label}
    </span>
  );
}

function DetailRow({ label, value }) {
  return (
    <div className="flex justify-between gap-4 border-b border-border py-2 text-sm last:border-0">
      <dt className="text-subtle">{label}</dt>
      <dd className="break-all text-right font-medium text-ink">{value || "—"}</dd>
    </div>
  );
}

function OrderDetailDialog({ orderId, onClose }) {
  const { data, isPending, isError, error } = useAdminOrder(orderId);

  return (
    <Dialog open={orderId != null} onOpenChange={(open) => !open && onClose()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Chi tiết đơn hàng #{orderId}</DialogTitle>
          <DialogDescription>Thông tin giao dịch thanh toán.</DialogDescription>
        </DialogHeader>
        {isError ? (
          <p className="rounded-xl bg-destructive/10 px-3 py-2 text-sm text-destructive">{error.message}</p>
        ) : isPending ? (
          <div aria-hidden className="h-48 animate-pulse rounded-2xl bg-surface" />
        ) : (
          <dl className="max-h-[60vh] overflow-y-auto">
            <DetailRow label="Mã đơn" value={data.orderCode} />
            <DetailRow label="Người dùng" value={data.userId != null ? `#${data.userId}` : null} />
            <DetailRow label="Gói" value={PLAN_LABELS[data.planCode] ?? data.planCode} />
            <DetailRow label="Số tiền" value={formatVnd(data.amount)} />
            <DetailRow label="Trạng thái" value={<StatusBadge status={data.status} />} />
            <DetailRow label="Nội dung" value={data.description} />
            <DetailRow label="Ngày tạo" value={formatDateTime(data.createdAt)} />
            <DetailRow label="Ngày thanh toán" value={formatDateTime(data.paidAt)} />
            <DetailRow label="Hết hạn" value={formatDateTime(data.expiredAt)} />
            <DetailRow label="Payment link ID" value={data.paymentLinkId} />
            <DetailRow label="Mã tham chiếu" value={data.paymentReference} />
            <DetailRow label="Chủ tài khoản" value={data.accountName} />
            <DetailRow label="Số tài khoản" value={data.accountNumber} />
          </dl>
        )}
      </DialogContent>
    </Dialog>
  );
}

// Bảng đơn hàng có lọc trạng thái, phân trang, xem chi tiết (GET /admin/payments/orders[/{id}]).
// filters: { from, to, planCode } dùng chung với các khối khác của trang.
export default function OrdersTableSection({ filters, enabled }) {
  const [status, setStatus] = useState("");
  const [page, setPage] = useState(0);
  const [selectedId, setSelectedId] = useState(null);

  const { data, isPending, isError, error, isFetching } = useAdminOrders(
    { ...filters, status, page, size: PAGE_SIZE },
    { enabled },
  );

  // Khi bộ lọc dùng chung đổi thì quay về trang đầu (reset theo key, không dùng effect).
  const filterKey = `${filters.from}|${filters.to}|${filters.planCode}`;
  const [seenKey, setSeenKey] = useState(filterKey);
  if (seenKey !== filterKey) {
    setSeenKey(filterKey);
    setPage(0);
  }

  const items = data?.items ?? [];

  return (
    <section aria-label="Danh sách đơn hàng" className="flex flex-col gap-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h2 className="font-heading text-xl font-bold text-ink">Đơn hàng</h2>
        <SelectField
          aria-label="Lọc theo trạng thái"
          options={STATUS_OPTIONS}
          value={status}
          onValueChange={(value) => {
            setStatus(value);
            setPage(0);
          }}
          className="h-10"
        />
      </div>

      {isError ? (
        <p className="rounded-xl bg-destructive/10 px-3 py-2 text-sm text-destructive">{error.message}</p>
      ) : isPending ? (
        <div aria-hidden className="h-64 animate-pulse rounded-3xl border border-border bg-card" />
      ) : items.length === 0 ? (
        <p className="rounded-3xl border border-border bg-card p-6 text-sm text-subtle">
          Không có đơn hàng nào khớp bộ lọc.
        </p>
      ) : (
        <div className="overflow-hidden rounded-3xl border border-border bg-card shadow-sm">
          <div className="overflow-x-auto">
            <table className="w-full min-w-[820px] text-left text-sm">
              <thead className="bg-surface text-xs uppercase tracking-wide text-subtle">
                <tr>
                  <th className="px-4 py-3 font-semibold">Mã đơn</th>
                  <th className="px-3 py-3 font-semibold">Người dùng</th>
                  <th className="px-3 py-3 font-semibold">Gói</th>
                  <th className="px-3 py-3 text-right font-semibold">Số tiền</th>
                  <th className="px-3 py-3 font-semibold">Trạng thái</th>
                  <th className="px-3 py-3 font-semibold">Ngày tạo</th>
                  <th className="px-3 py-3 font-semibold">Ngày thanh toán</th>
                  <th className="px-3 py-3" />
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {items.map((order) => (
                  <tr key={order.id} className="text-body">
                    <td className="px-4 py-3 font-mono text-xs">{order.orderCode}</td>
                    <td className="px-3 py-3">#{order.userId}</td>
                    <td className="px-3 py-3 font-medium text-ink">{PLAN_LABELS[order.planCode] ?? order.planCode}</td>
                    <td className="whitespace-nowrap px-3 py-3 text-right tabular-nums">{formatVnd(order.amount)}</td>
                    <td className="px-3 py-3">
                      <StatusBadge status={order.status} />
                    </td>
                    <td className="whitespace-nowrap px-3 py-3 tabular-nums">{formatDateTime(order.createdAt)}</td>
                    <td className="whitespace-nowrap px-3 py-3 tabular-nums">{formatDateTime(order.paidAt)}</td>
                    <td className="px-3 py-3 text-right">
                      <Button
                        type="button"
                        size="sm"
                        variant="outline"
                        aria-label={`Xem chi tiết đơn ${order.orderCode}`}
                        onClick={() => setSelectedId(order.id)}
                      >
                        <Eye className="size-4" />
                        Chi tiết
                      </Button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="flex flex-wrap items-center justify-between gap-3 border-t border-border px-4 py-3 text-sm text-subtle">
            <span>
              {formatNumber(data.totalElements)} đơn • Trang {data.page + 1}/{Math.max(data.totalPages, 1)}
              {isFetching && " • Đang tải..."}
            </span>
            <div className="flex gap-2">
              <Button
                type="button"
                size="sm"
                variant="outline"
                disabled={data.page <= 0 || isFetching}
                onClick={() => setPage((p) => Math.max(p - 1, 0))}
              >
                <ChevronLeft className="size-4" />
                Trước
              </Button>
              <Button
                type="button"
                size="sm"
                variant="outline"
                disabled={data.page + 1 >= data.totalPages || isFetching}
                onClick={() => setPage((p) => p + 1)}
              >
                Sau
                <ChevronRight className="size-4" />
              </Button>
            </div>
          </div>
        </div>
      )}

      <OrderDetailDialog orderId={selectedId} onClose={() => setSelectedId(null)} />
    </section>
  );
}
