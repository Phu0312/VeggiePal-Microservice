import { Award, Calendar, Check, Droplets, Loader2, Lock, Sparkles, Sprout, User } from "lucide-react";

import { formatDate } from "@/features/payment/utils/paymentFormat";
import { useMyBadges } from "@/features/profile/hooks/useProfileExtras";
import { cn } from "@/lib/utils";

// Tên `icon` BE trả về -> icon lucide.
const BADGE_ICONS = {
  sprout: Sprout,
  check: Check,
  user: User,
  calendar: Calendar,
  droplets: Droplets,
  sparkles: Sparkles,
};

/** Huy hiệu xanh của tôi (GET /users/me/badges). Chỉ xem: huy hiệu do BE tự cấp. */
export default function BadgesCard() {
  const { data, isPending, isError, error } = useMyBadges();

  return (
    <section className="rounded-3xl border border-border bg-card p-5 shadow-sm sm:p-6">
      <div className="flex items-center justify-between gap-3">
        <h2 className="flex items-center gap-2 font-heading text-lg font-bold text-ink">
          <Award className="size-5 text-brand" />
          Huy hiệu xanh
        </h2>
        {data && (
          <span className="text-sm text-subtle">
            {data.earnedCount}/{data.totalCount} đã đạt
          </span>
        )}
      </div>

      {isPending ? (
        <p className="mt-4 flex items-center gap-2 text-sm text-subtle">
          <Loader2 className="size-4 animate-spin" />
          Đang tải huy hiệu...
        </p>
      ) : isError ? (
        <p className="mt-4 rounded-xl bg-destructive/10 px-3 py-2 text-sm text-destructive">{error.message}</p>
      ) : (
        <ul className="mt-4 grid gap-3 sm:grid-cols-2">
          {(data?.badges ?? []).map((badge) => {
            const Icon = BADGE_ICONS[badge.icon] ?? Award;
            return (
              <li
                key={badge.code}
                className={cn(
                  "flex items-start gap-3 rounded-2xl border p-3",
                  badge.earned ? "border-brand/30 bg-brand-soft" : "border-border bg-surface opacity-70"
                )}
              >
                <div
                  className={cn(
                    "grid size-10 shrink-0 place-items-center rounded-full",
                    badge.earned ? "bg-brand text-brand-foreground" : "bg-card text-subtle"
                  )}
                >
                  {badge.earned ? <Icon className="size-5" /> : <Lock className="size-4" />}
                </div>
                <div className="min-w-0">
                  <p className="text-sm font-semibold text-ink">{badge.title}</p>
                  <p className="text-xs text-body">{badge.description}</p>
                  {badge.earned && badge.earnedAt && (
                    <p className="mt-0.5 text-[11px] text-subtle">Đạt ngày {formatDate(badge.earnedAt)}</p>
                  )}
                </div>
              </li>
            );
          })}
        </ul>
      )}
    </section>
  );
}
