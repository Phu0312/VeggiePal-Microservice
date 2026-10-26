import { useEffect, useState, useMemo } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { useQueryClient } from "@tanstack/react-query";
import {
  CheckCircle2,
  Clock,
  AlertTriangle,
  ArrowRight,
  History,
  Home,
  Receipt,
  Sparkles,
  Loader2,
} from "lucide-react";

import AppHeader from "@/shared/components/AppHeader";
import AppFooter from "@/shared/components/AppFooter";
import Reveal from "@/shared/components/Reveal";
import { Button } from "@/components/ui/button";
import { useOrder, usePaymentHistory } from "@/features/payment/hooks";
import { paymentKeys } from "@/features/payment/queryKeys";
import {
  PENDING_ORDER_STORAGE_KEY,
  formatVnd,
  formatDateTime,
  PLAN_DETAILS,
} from "@/features/payment/utils/paymentFormat";

// Thời gian chờ tối đa cho polling webhook: 45 giây (mỗi 2.5s gọi 1 lần)
const MAX_POLL_DURATION_MS = 45_000;
const POLL_INTERVAL_MS = 2_500;

export default function PaymentSuccessScreen() {
  const [searchParams] = useSearchParams();
  const queryClient = useQueryClient();

  const [isTimedOut, setIsTimedOut] = useState(false);

  // 1. Lấy order id từ sessionStorage
  const [storedOrderId] = useState(() => {
    return sessionStorage.getItem(PENDING_ORDER_STORAGE_KEY);
  });

  const orderCodeParam = searchParams.get("orderCode");

  // 2. Nếu không có trong sessionStorage, tìm theo orderCode trong /payments/history
  const { history, loading: loadingHistory } = usePaymentHistory();

  const matchedFromHistory = useMemo(() => {
    if (storedOrderId) return null;
    if (!history?.length) return null;
    if (orderCodeParam) {
      return (
        history.find((o) => String(o.orderCode) === String(orderCodeParam)) ??
        null
      );
    }
    return history[0] ?? null;
  }, [storedOrderId, orderCodeParam, history]);

  const effectiveOrderId =
    storedOrderId || (matchedFromHistory ? String(matchedFromHistory.id) : null);
  const isResolvingId = !storedOrderId && loadingHistory;

  // 3. Poll chi tiết đơn hàng
  const { order } = useOrder(effectiveOrderId, {
    poll: !isTimedOut && Boolean(effectiveOrderId),
    intervalMs: POLL_INTERVAL_MS,
  });

  // Dữ liệu đơn hàng có thể lấy từ order query hoặc từ matchedFromHistory nếu chưa có
  const currentOrder = order || matchedFromHistory;
  const isPaid = currentOrder?.status === "PAID";
  const isFailed = currentOrder?.status === "FAILED";

  // 4. Timeout sau 45s nếu chưa PAID và chưa FAILED
  useEffect(() => {
    if (isPaid || isFailed) return;

    const timer = setTimeout(() => {
      setIsTimedOut(true);
      sessionStorage.removeItem(PENDING_ORDER_STORAGE_KEY);
    }, MAX_POLL_DURATION_MS);

    return () => clearTimeout(timer);
  }, [isPaid, isFailed]);

  // 5. Khi PAID thành công: invalidate subscription và history, xóa sessionStorage
  useEffect(() => {
    if (isPaid) {
      queryClient.invalidateQueries({ queryKey: paymentKeys.subscription() });
      queryClient.invalidateQueries({ queryKey: paymentKeys.history() });
      sessionStorage.removeItem(PENDING_ORDER_STORAGE_KEY);
    }
  }, [isPaid, queryClient]);

  // Khi FAILED: xóa sessionStorage
  useEffect(() => {
    if (isFailed) {
      sessionStorage.removeItem(PENDING_ORDER_STORAGE_KEY);
    }
  }, [isFailed]);

  const planInfo = useMemo(() => {
    return PLAN_DETAILS[currentOrder?.planCode] || {
      name: `Gói ${currentOrder?.planCode || ""}`,
    };
  }, [currentOrder?.planCode]);

  return (
    <div className="min-h-dvh bg-canvas transition-colors duration-200">
      <AppHeader />

      <main className="mx-auto flex w-full max-w-2xl flex-col items-center justify-center px-4 py-12 sm:px-6">
        <Reveal>
          <div className="w-full rounded-3xl border border-border bg-card p-6 sm:p-10 shadow-lg text-center">
            {/* Trường hợp 1: Đang tìm mã đơn hoặc đang chờ webhook */}
            {isResolvingId || (!isPaid && !isFailed && !isTimedOut) ? (
              <div className="py-8 space-y-6">
                <div className="mx-auto grid size-20 place-items-center rounded-full bg-brand-soft text-brand animate-pulse">
                  <Loader2 className="size-10 animate-spin" />
                </div>
                <div className="space-y-2">
                  <h2 className="font-display-serif text-2xl sm:text-3xl font-bold text-ink">
                    Đang xác thực thanh toán…
                  </h2>
                  <p className="text-sm text-subtle max-w-md mx-auto">
                    Hệ thống đang đồng bộ kết quả từ cổng thanh toán payOS. Vui lòng giữ màn hình trong giây lát.
                  </p>
                </div>
                <div className="inline-flex items-center gap-2 rounded-full bg-surface px-4 py-1.5 text-xs text-subtle">
                  <Clock className="size-3.5 text-brand" />
                  Đang kiểm tra trạng thái đơn hàng #{currentOrder?.orderCode || orderCodeParam || "..."}
                </div>
              </div>
            ) : isPaid ? (
              /* Trường hợp 2: ĐÃ THANH TOÁN THÀNH CÔNG (PAID) */
              <div className="space-y-6">
                <div className="mx-auto grid size-20 place-items-center rounded-full bg-emerald-500/10 text-emerald-600 dark:text-emerald-400">
                  <CheckCircle2 className="size-12" />
                </div>

                <div className="space-y-2">
                  <span className="inline-flex items-center gap-1.5 rounded-full border border-brand/30 bg-brand-soft px-3.5 py-1 text-xs font-semibold text-brand">
                    <Sparkles className="size-3.5" />
                    Thanh toán thành công
                  </span>
                  <h2 className="font-display-serif text-2xl sm:text-3xl font-bold text-ink">
                    Chúc mừng bạn đã nâng cấp thành công!
                  </h2>
                  <p className="text-sm text-subtle max-w-md mx-auto">
                    Tài khoản của bạn đã được kích hoạt quyền lợi <strong className="text-ink">{planInfo.name}</strong>.
                    Bắt đầu trải nghiệm ngay hôm nay.
                  </p>
                </div>

                {/* Thông tin hóa đơn */}
                {currentOrder && (
                  <div className="rounded-2xl border border-border bg-surface/50 p-5 text-left space-y-3 text-sm">
                    <div className="flex items-center justify-between border-b border-border/60 pb-2">
                      <span className="text-subtle flex items-center gap-1.5">
                        <Receipt className="size-4" />
                        Mã đơn hàng
                      </span>
                      <strong className="text-ink">#{currentOrder.orderCode}</strong>
                    </div>
                    <div className="flex items-center justify-between border-b border-border/60 pb-2">
                      <span className="text-subtle">Gói dịch vụ</span>
                      <strong className="text-ink">{planInfo.name}</strong>
                    </div>
                    <div className="flex items-center justify-between border-b border-border/60 pb-2">
                      <span className="text-subtle">Số tiền thanh toán</span>
                      <strong className="text-brand font-bold">{formatVnd(currentOrder.amount)}</strong>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-subtle">Thời gian thanh toán</span>
                      <span className="text-ink">{formatDateTime(currentOrder.paidAt || currentOrder.createdAt)}</span>
                    </div>
                  </div>
                )}

                {/* Nút điều hướng */}
                <div className="flex flex-col sm:flex-row items-center justify-center gap-3 pt-4">
                  <Button
                    type="button"
                    variant="default"
                    render={<Link to="/" />}
                    className="w-full sm:w-auto rounded-full gap-2 font-semibold"
                  >
                    <Home className="size-4" />
                    Về Trang Chủ
                  </Button>
                  <Button
                    type="button"
                    variant="outline"
                    render={<Link to="/pricing" />}
                    className="w-full sm:w-auto rounded-full gap-2 font-semibold"
                  >
                    Xem Quyền Lợi Gói
                    <ArrowRight className="size-4" />
                  </Button>
                </div>
              </div>
            ) : isFailed ? (
              /* Trường hợp 3: ĐƠN HÀNG THẤT BẠI (FAILED) */
              <div className="space-y-6">
                <div className="mx-auto grid size-20 place-items-center rounded-full bg-destructive/10 text-destructive">
                  <AlertTriangle className="size-12" />
                </div>

                <div className="space-y-2">
                  <h2 className="font-display-serif text-2xl sm:text-3xl font-bold text-ink">
                    Giao dịch không thành công
                  </h2>
                  <p className="text-sm text-subtle max-w-md mx-auto">
                    Thanh toán của bạn đã bị từ chối hoặc phát sinh sự cố trong quá trình giao dịch.
                  </p>
                </div>

                <div className="flex flex-col sm:flex-row items-center justify-center gap-3 pt-4">
                  <Button
                    type="button"
                    variant="default"
                    render={<Link to="/pricing" />}
                    className="w-full sm:w-auto rounded-full gap-2 font-semibold"
                  >
                    Thử Lại Tại Trang Gói
                  </Button>
                  <Button
                    type="button"
                    variant="outline"
                    render={<Link to="/" />}
                    className="w-full sm:w-auto rounded-full gap-2 font-semibold"
                  >
                    Về Trang Chủ
                  </Button>
                </div>
              </div>
            ) : (
              /* Trường hợp 4: HẾT THỜI GIAN CHỜ MÀ CHƯA PAID (ĐANG XỬ LÝ) */
              <div className="space-y-6">
                <div className="mx-auto grid size-20 place-items-center rounded-full bg-amber-500/10 text-amber-600 dark:text-amber-400">
                  <Clock className="size-12" />
                </div>

                <div className="space-y-2">
                  <h2 className="font-display-serif text-2xl sm:text-3xl font-bold text-ink">
                    Giao dịch đang được xử lý
                  </h2>
                  <p className="text-sm text-body max-w-md mx-auto">
                    Cổng thanh toán đang xác nhận thông tin chuyển khoản của bạn.
                    Gói thành viên sẽ được cập nhật tự động ngay khi ngân hàng gửi kết quả.
                  </p>
                  <p className="text-xs text-subtle">
                    Vui lòng kiểm tra lại trạng thái trong lịch sử thanh toán sau ít phút.
                  </p>
                </div>

                <div className="flex flex-col sm:flex-row items-center justify-center gap-3 pt-4">
                  <Button
                    type="button"
                    variant="default"
                    render={<Link to="/payment/history" />}
                    className="w-full sm:w-auto rounded-full gap-2 font-semibold"
                  >
                    <History className="size-4" />
                    Xem Lịch Sử Thanh Toán
                  </Button>
                  <Button
                    type="button"
                    variant="outline"
                    render={<Link to="/" />}
                    className="w-full sm:w-auto rounded-full gap-2 font-semibold"
                  >
                    Về Trang Chủ
                  </Button>
                </div>
              </div>
            )}
          </div>
        </Reveal>
      </main>

      <AppFooter />
    </div>
  );
}
