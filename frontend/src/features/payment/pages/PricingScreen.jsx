import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { toast } from "sonner";
import {
  Sparkles,
  ShieldCheck,
  CreditCard,
  History,
  AlertCircle,
  Calendar,
  CheckCircle2,
} from "lucide-react";

import AppHeader from "@/shared/components/AppHeader";
import AppFooter from "@/shared/components/AppFooter";
import Reveal from "@/shared/components/Reveal";
import { Button } from "@/components/ui/button";
import { useRequireLogin } from "@/features/auth/hooks/useRequireLogin";
import { usePlans, useMySubscription, useCheckout } from "@/features/payment/hooks";
import PlanCard from "@/features/payment/components/PlanCard";
import PlanConfirmDialog from "@/features/payment/components/PlanConfirmDialog";
import {
  PENDING_ORDER_STORAGE_KEY,
  formatDateTime,
} from "@/features/payment/utils/paymentFormat";

export default function PricingScreen() {
  const { plans, loading: loadingPlans, error: plansError, refetch: refetchPlans } = usePlans();
  const { subscription, loading: loadingSub } = useMySubscription();
  const checkoutMutation = useCheckout();
  const navigate = useNavigate();
  const { isAuthenticated, requireLogin } = useRequireLogin();

  const [confirmPlan, setConfirmPlan] = useState(null);
  const [selectedPlanCode, setSelectedPlanCode] = useState(null);

  const isCheckoutLoading = checkoutMutation.isPending;

  const handleCheckout = async (plan) => {
    if (!requireLogin()) {
      return;
    }

    // Nếu người dùng đang dùng gói trả phí khác gói muốn mua -> xác nhận
    const currentCode = subscription?.planCode;
    const isPaidCurrentPlan = currentCode && currentCode !== "FREE";

    if (isPaidCurrentPlan && currentCode !== plan.code) {
      setConfirmPlan(plan);
      return;
    }

    await executeCheckout(plan.code);
  };

  const executeCheckout = async (planCode) => {
    try {
      setSelectedPlanCode(planCode);
      const order = await checkoutMutation.mutateAsync(planCode);
      if (order?.id) {
        sessionStorage.setItem(PENDING_ORDER_STORAGE_KEY, String(order.id));
      }
      if (order?.id) {
        navigate(`/checkout/${order.id}`);
      } else {
        toast.error("Không nhận được thông tin đơn thanh toán");
      }
    } catch (err) {
      toast.error(err.message || "Không thể tạo giao dịch thanh toán");
    } finally {
      setConfirmPlan(null);
      setSelectedPlanCode(null);
    }
  };

  return (
    <div className="min-h-dvh bg-canvas transition-colors duration-200">
      <AppHeader />

      <main className="mx-auto flex w-full max-w-6xl flex-col gap-10 px-4 py-8 sm:px-6 lg:px-8">
        {/* Banner tiêu đề */}
        <Reveal>
          <div className="text-center space-y-4">
            <div className="inline-flex items-center gap-1.5 rounded-full border border-brand/30 bg-brand-soft px-4 py-1 text-xs font-semibold text-brand">
              <Sparkles className="size-3.5" />
              Gói Thành Viên VeggiePal
            </div>
            <h1 className="font-display-serif text-3xl font-bold tracking-tight text-ink sm:text-4xl md:text-5xl">
              Nâng tầm trải nghiệm sống xanh &amp; thuần chay
            </h1>
            <p className="mx-auto max-w-2xl text-sm sm:text-base text-subtle">
              Mở rộng giới hạn hỏi đáp trợ lý Bông Cải, lập thực đơn cá nhân hóa theo mục tiêu sức khỏe
              và tóm tắt video dinh dưỡng không giới hạn.
            </p>
          </div>
        </Reveal>

        {/* Thông tin gói hiện tại (nếu đã đăng nhập) */}
        {isAuthenticated && (
          <Reveal>
            <div className="rounded-3xl border border-border bg-card p-5 sm:p-6 shadow-sm">
              <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
                <div className="flex items-center gap-3.5">
                  <div className="grid size-12 shrink-0 place-items-center rounded-2xl bg-brand-soft text-brand">
                    <ShieldCheck className="size-6" />
                  </div>
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="text-xs font-semibold uppercase tracking-wider text-subtle">
                        Gói hiện tại của bạn
                      </span>
                      <span className="inline-flex items-center gap-1 rounded-full bg-brand/10 px-2.5 py-0.5 text-xs font-bold text-brand">
                        <CheckCircle2 className="size-3" />
                        {subscription?.planCode || "FREE"}
                      </span>
                    </div>
                    {subscription?.expiresAt ? (
                      <p className="mt-1 flex items-center gap-1.5 text-xs sm:text-sm text-subtle">
                        <Calendar className="size-3.5 text-brand" />
                        Hạn sử dụng đến:{" "}
                        <strong className="text-ink">
                          {formatDateTime(subscription.expiresAt)}
                        </strong>
                      </p>
                    ) : (
                      <p className="mt-1 text-xs sm:text-sm text-subtle">
                        Gói mặc định miễn phí, không giới hạn thời gian sử dụng.
                      </p>
                    )}
                  </div>
                </div>

                <div className="flex items-center gap-2 self-end sm:self-center">
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    render={<Link to="/payment/history" />}
                    className="gap-2 rounded-full font-semibold"
                  >
                    <History className="size-4" />
                    Lịch sử thanh toán
                  </Button>
                </div>
              </div>
            </div>
          </Reveal>
        )}

        {/* Danh sách các gói */}
        <div className="space-y-6">
          {loadingPlans || loadingSub ? (
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              {[1, 2, 3].map((idx) => (
                <div
                  key={idx}
                  className="h-96 rounded-3xl border border-border bg-card/50 p-8 animate-pulse flex flex-col justify-between"
                >
                  <div className="space-y-4">
                    <div className="h-6 w-32 rounded-lg bg-surface" />
                    <div className="h-10 w-24 rounded-lg bg-surface" />
                    <div className="space-y-2 pt-6">
                      <div className="h-4 w-full rounded bg-surface" />
                      <div className="h-4 w-5/6 rounded bg-surface" />
                      <div className="h-4 w-4/6 rounded bg-surface" />
                    </div>
                  </div>
                  <div className="h-10 w-full rounded-full bg-surface" />
                </div>
              ))}
            </div>
          ) : plansError ? (
            <div className="rounded-3xl border border-destructive/20 bg-destructive/10 p-8 text-center space-y-3">
              <AlertCircle className="mx-auto size-8 text-destructive" />
              <p className="font-semibold text-destructive">
                {plansError.message || "Không thể tải danh sách gói thành viên"}
              </p>
              <Button
                type="button"
                variant="outline"
                onClick={() => refetchPlans()}
                className="rounded-full gap-2"
              >
                Thử lại
              </Button>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 sm:gap-8 items-stretch">
              {plans.map((plan) => (
                <PlanCard
                  key={plan.id || plan.code}
                  plan={plan}
                  currentSubscription={subscription}
                  onSelectPlan={handleCheckout}
                  isPending={isCheckoutLoading && selectedPlanCode === plan.code}
                />
              ))}
            </div>
          )}
        </div>

        {/* Cam kết & Phương thức thanh toán */}
        <Reveal>
          <div className="rounded-3xl border border-border bg-card/60 p-6 sm:p-8 backdrop-blur-sm">
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-6 text-center sm:text-left">
              <div className="flex flex-col sm:flex-row items-center sm:items-start gap-3">
                <div className="grid size-10 shrink-0 place-items-center rounded-2xl bg-brand-soft text-brand">
                  <CreditCard className="size-5" />
                </div>
                <div>
                  <h4 className="font-bold text-sm text-ink">Thanh toán an toàn qua payOS</h4>
                  <p className="text-xs text-subtle mt-1">
                    Hỗ trợ quét mã VietQR qua 40+ ngân hàng và ví điện tử, xử lý ngay tức thì.
                  </p>
                </div>
              </div>

              <div className="flex flex-col sm:flex-row items-center sm:items-start gap-3">
                <div className="grid size-10 shrink-0 place-items-center rounded-2xl bg-brand-soft text-brand">
                  <ShieldCheck className="size-5" />
                </div>
                <div>
                  <h4 className="font-bold text-sm text-ink">Kích hoạt tức thì</h4>
                  <p className="text-xs text-subtle mt-1">
                    Gói thành viên được kích hoạt tự động ngay sau khi giao dịch thành công.
                  </p>
                </div>
              </div>

              <div className="flex flex-col sm:flex-row items-center sm:items-start gap-3">
                <div className="grid size-10 shrink-0 place-items-center rounded-2xl bg-brand-soft text-brand">
                  <Sparkles className="size-5" />
                </div>
                <div>
                  <h4 className="font-bold text-sm text-ink">Không tự động gia hạn ngầm</h4>
                  <p className="text-xs text-subtle mt-1">
                    Không tự động trừ tiền trong thẻ của bạn. Hết 30 ngày bạn chủ động gia hạn khi cần.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </Reveal>
      </main>

      <AppFooter />

      {/* Hộp thoại xác nhận đổi gói */}
      {confirmPlan && (
        <PlanConfirmDialog
          open={Boolean(confirmPlan)}
          onOpenChange={(open) => !open && setConfirmPlan(null)}
          onConfirm={() => executeCheckout(confirmPlan.code)}
          currentPlan={subscription?.planCode}
          targetPlan={confirmPlan.code}
          loading={isCheckoutLoading}
        />
      )}
    </div>
  );
}
