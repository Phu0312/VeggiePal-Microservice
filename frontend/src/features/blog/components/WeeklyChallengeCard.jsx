import { useState } from "react";
import { CalendarCheck, Check, Gift } from "lucide-react";

import { Button } from "@/components/ui/button";
import { useRequireLogin } from "@/features/auth/hooks/useRequireLogin";
import ChallengeRewardDialog from "@/features/blog/components/ChallengeRewardDialog";
import { useChallenge } from "@/features/blog/hooks/useChallenge";
import { CHALLENGE_BADGE_NAME } from "@/features/blog/utils/challenge";

// Thử thách 7 ngày: tiến độ lưu theo user ở localStorage (xem useChallenge), chưa có API.
export default function WeeklyChallengeCard() {
  const { days, total, checkedToday, completed, broken, checkIn } = useChallenge();
  const { requireLogin } = useRequireLogin();
  const [rewardOpen, setRewardOpen] = useState(false);

  const handleCheckIn = () => {
    if (!requireLogin()) return;
    // Lần check-in thứ 7 -> mở popup mở khóa huy hiệu và voucher.
    if (checkIn()) setRewardOpen(true);
  };

  return (
    <section className="rounded-3xl border border-border bg-card p-5 shadow-sm">
      <div className="flex items-center justify-between gap-2">
        <span className="inline-flex items-center gap-1 rounded-full bg-brand-soft px-2.5 py-1 text-[11px] font-medium text-brand">
          <CalendarCheck className="size-3" />
          Thử thách 7 ngày
        </span>
        <span className="text-sm font-bold text-brand">
          {days} / {total} Ngày
        </span>
      </div>

      <h2 className="mt-3 font-heading text-lg font-bold leading-snug text-ink">
        7 Ngày Sống Thuần Chay Tươi Mới
      </h2>
      <p className="mt-1.5 text-xs leading-relaxed text-body">
        Check-in mỗi ngày trong 7 ngày liên tiếp để mở khóa huy hiệu độc quyền “{CHALLENGE_BADGE_NAME}”
        và nhận voucher quán chay đối tác. Bỏ lỡ một ngày là chuỗi sẽ bắt đầu lại.
      </p>

      <div
        role="progressbar"
        aria-valuemin={0}
        aria-valuemax={total}
        aria-valuenow={days}
        className="mt-4 h-2 overflow-hidden rounded-full bg-surface"
      >
        <div
          className="h-full rounded-full bg-brand transition-all"
          style={{ width: `${(days / total) * 100}%` }}
        />
      </div>

      {broken && (
        <p className="mt-2 text-[11px] text-subtle">
          Bạn đã lỡ một ngày nên chuỗi đã đứt. Check-in hôm nay để bắt đầu lại từ ngày 1.
        </p>
      )}

      {completed ? (
        <Button type="button" variant="soft" className="mt-4 w-full" onClick={() => setRewardOpen(true)}>
          <Gift className="size-4" />
          Xem phần thưởng
        </Button>
      ) : (
        <Button type="button" className="mt-4 w-full" disabled={checkedToday} onClick={handleCheckIn}>
          {checkedToday ? (
            <>
              <Check className="size-4" />
              Đã check-in hôm nay
            </>
          ) : (
            "Check-in Bữa Tối Hôm Nay"
          )}
        </Button>
      )}

      <ChallengeRewardDialog open={rewardOpen} onOpenChange={setRewardOpen} />
    </section>
  );
}
