import { Link } from "react-router-dom";
import {
  History,
  Receipt,
  ArrowRight,
  Sparkles,
  Calendar,
  AlertCircle,
  CheckCircle2,
  Clock,
  XCircle,
} from "lucide-react";

import AppHeader from "@/shared/components/AppHeader";
import AppFooter from "@/shared/components/AppFooter";
import Reveal from "@/shared/components/Reveal";
import { Button } from "@/components/ui/button";
import { usePaymentHistory } from "@/features/payment/hooks/usePaymentHistory";
import {
  formatVnd,
  formatDateTime,
  getPaymentStatusInfo,
  isOrderResumable,
  PLAN_DETAILS,
} from "@/features/payment/utils/paymentFormat";
import { cn } from "@/lib/utils";

export default function PaymentHistoryScreen() {
  const { history, loading, error, refetch } = usePaymentHistory();

  return (
    <div className="min-h-dvh bg-canvas transition-colors duration-200">
      <AppHeader />

      <main className="mx-auto flex w-full max-w-5xl flex-col gap-8 px-4 py-8 sm:px-6 lg:px-8">
        <Reveal>
          <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 border-b border-border pb-6">
            <div>
              <div className="inline-flex items-center gap-1.5 rounded-full border border-brand/30 bg-brand-soft px-3.5 py-0.5 text-xs font-semibold text-brand mb-2">
                <History className="size-3.5" />
                Lịch sử giao dịch
              </div>
              <h1 className="font-display-serif text-2xl sm:text-3xl font-bold tracking-tight text-ink">
                Lịch sử thanh toán &amp; Gói thành viên
              </h1>
              <p className="mt-1 text-sm text-subtle">
                Theo dõi toàn bộ các đơn hàng và trạng thái kích hoạt gói dịch vụ của bạn.
              </p>
            </div>

            <Button
              type="button"
              variant="default"
              render={<Link to="/pricing" />}
              className="rounded-full gap-2 font-semibold shadow-sm"
            >
              <Sparkles className="size-4" />
              Xem Các Gói Thành Viên
            </Button>
          </div>
        </Reveal>

        {/* Nội dung danh sách */}
        <div>
          {loading ? (
            <div className="space-y-4">
              {[1, 2, 3].map((i) => (
                <div
                  key={i}
                  className="h-24 rounded-2xl border border-border bg-card/60 p-5 animate-pulse flex items-center justify-between"
                >
                  <div className="space-y-2">
                    <div className="h-5 w-48 rounded bg-surface" />
                    <div className="h-4 w-32 rounded bg-surface" />
                  </div>
                  <div className="h-8 w-24 rounded-full bg-surface" />
                </div>
              ))}
            </div>
          ) : error ? (
            <div className="rounded-3xl border border-destructive/20 bg-destructive/10 p-8 text-center space-y-3">
              <AlertCircle className="mx-auto size-8 text-destructive" />
              <p className="font-semibold text-destructive">
                {error.message || "Không thể tải lịch sử thanh toán"}
              </p>
              <Button
                type="button"
                variant="outline"
                onClick={() => refetch()}
                className="rounded-full gap-2"
              >
                Thử lại
              </Button>
            </div>
          ) : history.length === 0 ? (
            <div className="rounded-3xl border border-border bg-card p-12 text-center space-y-4 shadow-sm">
              <div className="mx-auto grid size-16 place-items-center rounded-full bg-surface text-subtle">
                <Receipt className="size-8" />
              </div>
              <div className="space-y-1">
                <h3 className="font-bold text-base text-ink">
                  Bạn chưa có giao dịch thanh toán nào
                </h3>
                <p className="text-xs sm:text-sm text-subtle max-w-md mx-auto">
                  Khám phá các gói thành viên PLUS và PRO để nâng cao trải nghiệm hỏi đáp AI và lên thực đơn chay hàng tuần.
                </p>
              </div>
              <Button
                type="button"
                variant="default"
                render={<Link to="/pricing" />}
                className="rounded-full gap-2 font-semibold mt-2"
              >
                Khám Phá Các Gói Dịch Vụ
                <ArrowRight className="size-4" />
              </Button>
            </div>
          ) : (
            <div className="space-y-3">
              {history.map((order) => {
                const statusInfo = getPaymentStatusInfo(order.status);
                const planInfo = PLAN_DETAILS[order.planCode] || {
                  name: `Gói ${order.planCode}`,
                };

                return (
                  <div
                    key={order.id}
                    className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 rounded-2xl border border-border bg-card p-4 sm:p-5 shadow-xs transition hover:border-brand/30"
                  >
                    <div className="flex items-start gap-3.5 min-w-0">
                      <div className="grid size-11 shrink-0 place-items-center rounded-2xl bg-surface text-ink">
                        {order.status === "PAID" ? (
                          <CheckCircle2 className="size-5 text-emerald-600 dark:text-emerald-400" />
                        ) : order.status === "FAILED" || order.status === "CANCELLED" ? (
                          <XCircle className="size-5 text-destructive" />
                        ) : (
                          <Clock className="size-5 text-amber-600 dark:text-amber-400" />
                        )}
                      </div>

                      <div className="min-w-0">
                        <div className="flex items-center gap-2 flex-wrap">
                          <h4 className="font-bold text-base text-ink">
                            {planInfo.name}
                          </h4>
                          <span className="text-xs text-subtle">
                            #{order.orderCode}
                          </span>
                        </div>

                        <div className="mt-1 flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-subtle">
                          <span className="flex items-center gap-1">
                            <Calendar className="size-3 text-subtle" />
                            Tạo: {formatDateTime(order.createdAt)}
                          </span>
                          {order.paidAt && (
                            <span className="flex items-center gap-1 text-emerald-700 dark:text-emerald-400 font-medium">
                              <CheckCircle2 className="size-3" />
                              Thanh toán: {formatDateTime(order.paidAt)}
                            </span>
                          )}
                        </div>
                      </div>
                    </div>

                    <div className="flex items-center justify-between sm:justify-end gap-4 w-full sm:w-auto border-t sm:border-t-0 pt-3 sm:pt-0 border-border/50">
                      <div className="text-left sm:text-right">
                        <p className="text-sm sm:text-base font-bold text-ink">
                          {formatVnd(order.amount)}
                        </p>
                      </div>

                      {isOrderResumable(order) && (
                        <Button
                          type="button"
                          size="sm"
                          render={<Link to={`/checkout/${order.id}`} />}
                          className="rounded-full font-semibold"
                        >
                          Tiếp tục thanh toán
                        </Button>
                      )}

                      <span
                        className={cn(
                          "inline-flex items-center rounded-full border px-3 py-1 text-xs font-semibold shrink-0",
                          statusInfo.className
                        )}
                      >
                        {statusInfo.label}
                      </span>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </main>

      <AppFooter />
    </div>
  );
}
