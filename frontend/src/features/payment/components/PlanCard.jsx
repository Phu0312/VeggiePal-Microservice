import { Check, Sparkles, Bot, Utensils, Video, Loader2 } from "lucide-react";

import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import { formatVnd, PLAN_DETAILS } from "@/features/payment/utils/paymentFormat";

export default function PlanCard({
  plan,
  currentSubscription,
  onSelectPlan,
  isPending = false,
}) {
  const isFree = plan.code === "FREE" || plan.price <= 0;
  const isCurrentPlan = currentSubscription?.planCode === plan.code;
  const isActiveCurrentPlan = isCurrentPlan && !isFree;

  const details = PLAN_DETAILS[plan.code] || {
    name: `Gói ${plan.code}`,
    popular: false,
    badgeLabel: null,
  };

  const isPopular = details.popular;

  return (
    <div
      className={cn(
        "relative flex flex-col justify-between rounded-3xl border p-6 sm:p-8 transition-all duration-300",
        isPopular
          ? "border-brand shadow-lg ring-2 ring-brand/30 bg-card"
          : "border-border bg-card/70 hover:border-brand/40 hover:shadow-md",
        isActiveCurrentPlan && "border-brand-2 ring-2 ring-brand-2/40 bg-brand-soft/20 dark:bg-brand-soft/5"
      )}
    >
      {/* Badge nổi bật */}
      {isPopular && !isActiveCurrentPlan && (
        <div className="absolute -top-3.5 left-1/2 -translate-x-1/2">
          <span className="inline-flex items-center gap-1 rounded-full bg-brand px-3.5 py-1 text-xs font-bold text-brand-foreground shadow-sm">
            <Sparkles className="size-3.5" />
            {details.badgeLabel}
          </span>
        </div>
      )}

      {isActiveCurrentPlan && (
        <div className="absolute -top-3.5 left-1/2 -translate-x-1/2">
          <span className="inline-flex items-center gap-1 rounded-full bg-brand-2 px-3.5 py-1 text-xs font-bold text-white shadow-sm">
            <Check className="size-3.5" />
            Đang sử dụng
          </span>
        </div>
      )}

      {/* Header card */}
      <div>
        <div className="flex items-center justify-between">
          <h3 className="font-display-serif text-xl sm:text-2xl font-bold text-ink">
            {details.name}
          </h3>
        </div>

        <div className="mt-4 flex items-baseline gap-1">
          <span className="text-3xl sm:text-4xl font-extrabold tracking-tight text-ink">
            {isFree ? "0đ" : formatVnd(plan.price)}
          </span>
          <span className="text-sm font-medium text-subtle">
            {isFree ? "/ vĩnh viễn" : `/ ${plan.durationDays || 30} ngày`}
          </span>
        </div>

        <p className="mt-2 text-xs text-subtle sm:text-sm">
          {isFree
            ? "Trải nghiệm tính năng AI cơ bản và khởi đầu lối sống ăn chay lành mạnh."
            : plan.code === "PLUS"
            ? "Mở rộng giới hạn cho người ăn chay thường xuyên và cần thực đơn đa dạng."
            : "Tối đa hóa sức mạnh trợ lý AI dinh dưỡng và phân tích video toàn diện."}
        </p>

        {/* Danh sách quyền lợi */}
        <div className="mt-6 border-t border-border pt-6">
          <p className="text-xs font-semibold uppercase tracking-wider text-subtle mb-3">
            Quyền lợi bao gồm
          </p>
          <ul className="space-y-3 text-sm text-body">
            <li className="flex items-center gap-2.5">
              <span className="grid size-6 shrink-0 place-items-center rounded-full bg-brand-soft text-brand">
                <Bot className="size-3.5" />
              </span>
              <span>
                <strong className="text-ink">{plan.chatPerDay}</strong> lượt hỏi AI / ngày
              </span>
            </li>

            <li className="flex items-center gap-2.5">
              <span className="grid size-6 shrink-0 place-items-center rounded-full bg-brand-soft text-brand">
                <Utensils className="size-3.5" />
              </span>
              <span>
                <strong className="text-ink">{plan.mealPlansPerMonth}</strong> thực đơn AI 7 ngày / tháng
              </span>
            </li>

            <li className="flex items-center gap-2.5">
              <span className="grid size-6 shrink-0 place-items-center rounded-full bg-brand-soft text-brand">
                <Video className="size-3.5" />
              </span>
              <span>
                <strong className="text-ink">{plan.videosPerMonth}</strong> lượt tóm tắt video dinh dưỡng / tháng
              </span>
            </li>

            <li className="flex items-center gap-2.5 text-xs text-subtle">
              <Check className="size-4 shrink-0 text-brand" />
              <span>Cập nhật khẩu phần theo chỉ số sức khỏe cá nhân</span>
            </li>
            <li className="flex items-center gap-2.5 text-xs text-subtle">
              <Check className="size-4 shrink-0 text-brand" />
              <span>Gợi ý tự động tránh nguyên liệu dị ứng</span>
            </li>
          </ul>
        </div>
      </div>

      {/* Nút hành động */}
      <div className="mt-8 pt-4">
        {isFree ? (
          <Button
            type="button"
            variant="outline"
            disabled
            className="w-full rounded-full cursor-not-allowed font-medium text-subtle"
          >
            {isCurrentPlan ? "Gói hiện tại của bạn" : "Gói miễn phí mặc định"}
          </Button>
        ) : (
          <Button
            type="button"
            variant={isPopular ? "default" : "outline"}
            disabled={isPending}
            onClick={() => onSelectPlan(plan)}
            className={cn(
              "w-full rounded-full gap-2 font-semibold shadow-sm transition hover:scale-[1.01]",
              isPopular && "bg-brand text-brand-foreground hover:bg-brand/90"
            )}
          >
            {isPending ? (
              <>
                <Loader2 className="size-4 animate-spin" />
                Đang xử lý…
              </>
            ) : isActiveCurrentPlan ? (
              "Gia hạn thêm 30 ngày"
            ) : (
              "Nâng cấp ngay"
            )}
          </Button>
        )}
      </div>
    </div>
  );
}
