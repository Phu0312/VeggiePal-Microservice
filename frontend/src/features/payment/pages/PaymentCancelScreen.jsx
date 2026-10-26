import { useEffect } from "react";
import { Link } from "react-router-dom";
import { XCircle, ArrowLeft, Home, HelpCircle } from "lucide-react";

import AppHeader from "@/shared/components/AppHeader";
import AppFooter from "@/shared/components/AppFooter";
import Reveal from "@/shared/components/Reveal";
import { Button } from "@/components/ui/button";
import { PENDING_ORDER_STORAGE_KEY } from "@/features/payment/utils/paymentFormat";

export default function PaymentCancelScreen() {
  // Xóa mã đơn pending khỏi sessionStorage khi người dùng đã hủy
  useEffect(() => {
    sessionStorage.removeItem(PENDING_ORDER_STORAGE_KEY);
  }, []);

  return (
    <div className="min-h-dvh bg-canvas transition-colors duration-200">
      <AppHeader />

      <main className="mx-auto flex w-full max-w-xl flex-col items-center justify-center px-4 py-16 sm:px-6">
        <Reveal>
          <div className="w-full rounded-3xl border border-border bg-card p-6 sm:p-10 shadow-lg text-center space-y-6">
            <div className="mx-auto grid size-20 place-items-center rounded-full bg-amber-500/10 text-amber-600 dark:text-amber-400">
              <XCircle className="size-12" />
            </div>

            <div className="space-y-2">
              <h1 className="font-display-serif text-2xl sm:text-3xl font-bold text-ink">
                Bạn đã hủy giao dịch thanh toán
              </h1>
              <p className="text-sm text-subtle max-w-md mx-auto">
                Yêu cầu thanh toán qua payOS đã bị hủy. Tài khoản và gói thành viên hiện tại của bạn không có bất kỳ thay đổi nào.
              </p>
            </div>

            <div className="rounded-2xl border border-border bg-surface/50 p-4 text-xs text-subtle flex items-start gap-2.5 text-left">
              <HelpCircle className="size-4 shrink-0 text-brand mt-0.5" />
              <span>
                Nếu bạn gặp khó khăn trong quá trình thanh toán bằng mã QR, vui lòng kiểm tra lại kết nối internet hoặc thử lại với phương thức ngân hàng khác.
              </span>
            </div>

            <div className="flex flex-col sm:flex-row items-center justify-center gap-3 pt-2">
              <Button
                type="button"
                variant="default"
                render={<Link to="/pricing" />}
                className="w-full sm:w-auto rounded-full gap-2 font-semibold"
              >
                <ArrowLeft className="size-4" />
                Quay Lại Bảng Giá
              </Button>
              <Button
                type="button"
                variant="outline"
                render={<Link to="/" />}
                className="w-full sm:w-auto rounded-full gap-2 font-semibold"
              >
                <Home className="size-4" />
                Về Trang Chủ
              </Button>
            </div>
          </div>
        </Reveal>
      </main>

      <AppFooter />
    </div>
  );
}
