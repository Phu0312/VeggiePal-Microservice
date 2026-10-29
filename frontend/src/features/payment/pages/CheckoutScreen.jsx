import { useEffect, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { useQueryClient } from "@tanstack/react-query";
import { QRCodeSVG } from "qrcode.react";
import { toast } from "sonner";
import {
  AlertCircle,
  Check,
  Clock,
  Copy,
  Loader2,
  QrCode,
  RefreshCw,
  XCircle,
} from "lucide-react";

import AppHeader from "@/shared/components/AppHeader";
import { Button } from "@/components/ui/button";
import { useOrder, useCheckout, useCancelOrder } from "@/features/payment/hooks";
import { paymentKeys } from "@/features/payment/queryKeys";
import {
  PENDING_ORDER_STORAGE_KEY,
  PLAN_DETAILS,
  formatVnd,
  getBankName,
} from "@/features/payment/utils/paymentFormat";

const POLL_INTERVAL_MS = 2_500;

function formatCountdown(ms) {
  const total = Math.max(0, Math.floor(ms / 1000));
  const m = String(Math.floor(total / 60)).padStart(2, "0");
  const s = String(total % 60).padStart(2, "0");
  return `${m}:${s}`;
}

function CopyButton({ value, label }) {
  const [copied, setCopied] = useState(false);

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(String(value));
      setCopied(true);
      setTimeout(() => setCopied(false), 1500);
    } catch {
      toast.error("Không thể sao chép, vui lòng sao chép thủ công");
    }
  };

  return (
    <Button
      type="button"
      variant="outline"
      size="sm"
      onClick={handleCopy}
      aria-label={`Sao chép ${label}`}
      className="shrink-0 gap-1.5 rounded-full"
    >
      {copied ? <Check className="size-3.5" /> : <Copy className="size-3.5" />}
      {copied ? "Đã chép" : "Sao chép"}
    </Button>
  );
}

function InfoRow({ label, value, copyValue, strong }) {
  return (
    <div className="flex items-center justify-between gap-3 border-b border-border/60 py-3 last:border-b-0">
      <div className="min-w-0">
        <p className="text-xs text-subtle">{label}</p>
        <p
          className={
            strong
              ? "break-words text-lg font-bold text-brand"
              : "break-words text-sm font-semibold text-ink"
          }
        >
          {value}
        </p>
      </div>
      {copyValue != null && <CopyButton value={copyValue} label={label} />}
    </div>
  );
}

function Shell({ children }) {
  return (
    <div className="min-h-dvh bg-canvas transition-colors duration-200">
      <AppHeader />
      <main className="mx-auto flex w-full max-w-xl flex-col items-center px-4 py-8 sm:px-6 sm:py-12">
        {children}
      </main>
    </div>
  );
}

export default function CheckoutScreen() {
  const { orderId } = useParams();
  const navigate = useNavigate();
  const queryClient = useQueryClient();

  const { order, loading, error, refetch } = useOrder(orderId, {
    poll: true,
    intervalMs: POLL_INTERVAL_MS,
  });
  const checkoutMutation = useCheckout();
  const cancelMutation = useCancelOrder();

  const [now, setNow] = useState(() => Date.now());

  const status = order?.status;

  // Đồng hồ đếm ngược mỗi giây khi đơn còn PENDING
  useEffect(() => {
    if (status !== "PENDING") return undefined;
    const timer = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(timer);
  }, [status]);

  // Phản ứng theo trạng thái đơn
  useEffect(() => {
    if (!status) return;
    if (status === "PAID") {
      queryClient.invalidateQueries({ queryKey: paymentKeys.subscription() });
      queryClient.invalidateQueries({ queryKey: paymentKeys.history() });
      if (order?.id != null) {
        sessionStorage.setItem(PENDING_ORDER_STORAGE_KEY, String(order.id));
      }
      navigate("/payment/success", { replace: true });
    } else if (status === "CANCELLED") {
      navigate("/pricing", { replace: true });
    }
  }, [status, order?.id, navigate, queryClient]);

  const handleCancel = async () => {
    if (cancelMutation.isPending) return;
    try {
      await cancelMutation.mutateAsync(order.id);
      navigate("/pricing", { replace: true });
    } catch (err) {
      toast.error(err.message || "Chưa huỷ được đơn, vui lòng thử lại");
    }
  };

  const handleRecreate = async () => {
    if (checkoutMutation.isPending || !order?.planCode) return;
    try {
      const next = await checkoutMutation.mutateAsync(order.planCode);
      if (next?.id) {
        sessionStorage.setItem(PENDING_ORDER_STORAGE_KEY, String(next.id));
        navigate(`/checkout/${next.id}`, { replace: true });
      } else {
        toast.error("Không nhận được thông tin đơn thanh toán");
      }
    } catch (err) {
      toast.error(err.message || "Không thể tạo lại giao dịch thanh toán");
    }
  };

  const cardClass =
    "w-full rounded-3xl border border-border bg-card p-5 shadow-sm sm:p-8";

  if (loading) {
    return (
      <Shell>
        <div className={`${cardClass} grid place-items-center py-20`}>
          <Loader2 className="size-8 animate-spin text-brand" />
          <p className="mt-3 text-sm text-subtle">Đang tải đơn thanh toán...</p>
        </div>
      </Shell>
    );
  }

  if (error || !order) {
    return (
      <Shell>
        <div className={`${cardClass} space-y-4 text-center`}>
          <AlertCircle className="mx-auto size-10 text-destructive" />
          <p className="font-semibold text-destructive">
            {error?.message || "Không tìm thấy đơn hàng"}
          </p>
          <div className="flex flex-col justify-center gap-2 sm:flex-row">
            <Button type="button" variant="outline" className="rounded-full" onClick={() => refetch()}>
              Thử lại
            </Button>
            <Button type="button" render={<Link to="/pricing" />} className="rounded-full">
              Về trang gói thành viên
            </Button>
          </div>
        </div>
      </Shell>
    );
  }

  if (status === "FAILED") {
    return (
      <Shell>
        <div className={`${cardClass} space-y-4 text-center`}>
          <XCircle className="mx-auto size-12 text-destructive" />
          <h1 className="font-display-serif text-2xl font-bold text-ink">Thanh toán thất bại</h1>
          <p className="text-sm text-subtle">
            Giao dịch không thành công. Bạn có thể quay lại và thử thanh toán lại.
          </p>
          <Button type="button" render={<Link to="/pricing" />} className="rounded-full">
            Quay về trang gói thành viên
          </Button>
        </div>
      </Shell>
    );
  }

  if (status !== "PENDING") {
    // PAID / CANCELLED đang điều hướng
    return (
      <Shell>
        <div className={`${cardClass} grid place-items-center py-20`}>
          <Loader2 className="size-8 animate-spin text-brand" />
        </div>
      </Shell>
    );
  }

  const expiresMs = order.expiredAt ? new Date(order.expiredAt).getTime() : null;
  const remaining = Number.isFinite(expiresMs) ? expiresMs - now : null;
  const isExpired = !order.qrCode || (remaining != null && remaining <= 0);
  const planName = PLAN_DETAILS[order.planCode]?.name ?? `Gói ${order.planCode}`;

  if (isExpired) {
    return (
      <Shell>
        <div className={`${cardClass} space-y-4 text-center`}>
          <div className="mx-auto grid size-14 place-items-center rounded-full bg-amber-500/10 text-amber-600 dark:text-amber-400">
            <Clock className="size-7" />
          </div>
          <h1 className="font-display-serif text-2xl font-bold text-ink">Mã QR đã hết hạn</h1>
          <p className="text-sm text-subtle">
            Đơn {planName} đã quá thời gian thanh toán. Hãy tạo lại mã QR mới để tiếp tục.
          </p>
          <div className="flex flex-col justify-center gap-2 sm:flex-row">
            <Button
              type="button"
              onClick={handleRecreate}
              disabled={checkoutMutation.isPending}
              className="gap-2 rounded-full font-semibold"
            >
              {checkoutMutation.isPending ? (
                <Loader2 className="size-4 animate-spin" />
              ) : (
                <RefreshCw className="size-4" />
              )}
              Tạo lại
            </Button>
            <Button type="button" variant="outline" render={<Link to="/pricing" />} className="rounded-full">
              Về trang gói thành viên
            </Button>
          </div>
        </div>
      </Shell>
    );
  }

  return (
    <Shell>
      <div className={`${cardClass} space-y-6`}>
        <div className="space-y-2 text-center">
          <div className="inline-flex items-center gap-1.5 rounded-full border border-brand/30 bg-brand-soft px-3.5 py-1 text-xs font-semibold text-brand">
            <QrCode className="size-3.5" />
            Thanh toán chuyển khoản VietQR
          </div>
          <h1 className="font-display-serif text-2xl font-bold tracking-tight text-ink sm:text-3xl">
            Quét mã để thanh toán
          </h1>
          <p className="text-sm text-subtle">
            Mở app ngân hàng, quét mã QR bên dưới. Gói sẽ tự kích hoạt sau khi thanh toán thành công.
          </p>
        </div>

        <div className="flex flex-col items-center gap-3">
          {/* Nền trắng cố định để mã QR luôn quét được ở dark mode */}
          <div className="rounded-2xl border border-border bg-white p-4 shadow-xs">
            <QRCodeSVG
              value={order.qrCode}
              size={256}
              marginSize={0}
              className="h-auto w-full max-w-64"
            />
          </div>
          {remaining != null && (
            <div className="inline-flex items-center gap-2 rounded-full bg-surface px-4 py-1.5 text-sm text-subtle">
              <Clock className="size-4 text-brand" />
              Hết hạn sau
              <strong className="font-mono text-base text-ink tabular-nums">
                {formatCountdown(remaining)}
              </strong>
            </div>
          )}
          <p className="flex items-center gap-2 text-xs text-subtle">
            <Loader2 className="size-3.5 animate-spin" />
            Đang chờ thanh toán...
          </p>
        </div>

        <div className="rounded-2xl border border-border bg-surface/50 px-4">
          <InfoRow label="Gói" value={planName} copyValue={planName} />
          <InfoRow label="Số tiền" value={formatVnd(order.amount)} copyValue={order.amount} strong />
          <InfoRow label="Chủ tài khoản" value={order.accountName || "—"} copyValue={order.accountName} />
          <InfoRow label="Số tài khoản" value={order.accountNumber || "—"} copyValue={order.accountNumber} />
          <InfoRow label="Ngân hàng" value={getBankName(order.bin)} copyValue={getBankName(order.bin)} />
          <InfoRow label="Nội dung chuyển khoản" value={order.description || "—"} copyValue={order.description} />
        </div>

        <p className="text-center text-xs text-subtle">
          Vui lòng giữ nguyên số tiền và nội dung chuyển khoản để hệ thống tự xác nhận.
        </p>

        <Button
          type="button"
          variant="outline"
          onClick={handleCancel}
          disabled={cancelMutation.isPending}
          className="w-full gap-2 rounded-full font-semibold"
        >
          {cancelMutation.isPending && <Loader2 className="size-4 animate-spin" />}
          {cancelMutation.isPending ? "Đang huỷ..." : "Huỷ thanh toán"}
        </Button>
      </div>
    </Shell>
  );
}
