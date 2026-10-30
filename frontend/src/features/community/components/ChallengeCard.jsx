import { useState } from "react";
import { Link } from "react-router-dom";
import { Award, CalendarCheck, Check, Loader2, RotateCw } from "lucide-react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { buttonVariants } from "@/components/ui/variants/button-variants";
import { useAuthStore, selectIsAuthenticated } from "@/features/auth/store/authStore";
import { useChallengeCheckIn, useMyChallenge } from "@/features/community/hooks/useCommunity";
import { cn } from "@/lib/utils";

/**
 * Thử thách "7 ngày sống thuần chay": điểm danh mỗi ngày (POST /blogs/challenge/check-in), bỏ một ngày là tính lại.
 * Đủ 7 ngày BE tự cấp huy hiệu Trái Tim Xanh. Cấp lỗi (503 / 3053) thì điểm danh vẫn được lưu:
 * tải lại tiến độ, báo "Huy hiệu chưa được cấp" và cho bấm "Nhận huy hiệu" (gọi lại điểm danh, BE cấp lại).
 */
export default function ChallengeCard() {
  const isAuthenticated = useAuthStore(selectIsAuthenticated);
  const { data: progress, isPending, isError, error, refetch } = useMyChallenge();
  const checkIn = useChallengeCheckIn();
  const [badgePending, setBadgePending] = useState(false);

  const handleCheckIn = async () => {
    try {
      const result = await checkIn.mutateAsync();
      setBadgePending(false);
      if (result?.justCompleted || (badgePending && result?.completed)) {
        toast.success(`Hoàn thành thử thách! Bạn nhận được huy hiệu ${result.badgeName ?? "Trái Tim Xanh"}`);
      } else {
        toast.success("Đã điểm danh hôm nay");
      }
    } catch (err) {
      if (err.code === 3053) {
        setBadgePending(true);
        toast.warning("Huy hiệu chưa được cấp");
        return;
      }
      toast.error(err.message);
    }
  };

  const total = progress?.total ?? 7;
  const days = progress?.days ?? 0;

  return (
    <section className="rounded-3xl border border-border bg-card p-5 shadow-sm sm:p-6">
      <h2 className="flex items-center gap-2 font-heading text-lg font-bold text-ink">
        <CalendarCheck className="size-5 text-brand" />
        Thử thách 7 ngày sống thuần chay
      </h2>
      <p className="mt-1 text-sm text-subtle">
        Điểm danh mỗi ngày bạn ăn thuần chay. Đủ 7 ngày liên tiếp để nhận huy hiệu Trái Tim Xanh.
      </p>

      {!isAuthenticated ? (
        <Link to="/login" state={{ from: { pathname: "/community" } }} className={buttonVariants({ size: "md", className: "mt-4" })}>
          Đăng nhập để tham gia
        </Link>
      ) : isPending ? (
        <p className="mt-4 flex items-center gap-2 text-sm text-subtle">
          <Loader2 className="size-4 animate-spin" />
          Đang tải tiến độ...
        </p>
      ) : isError ? (
        <div className="mt-4 flex flex-col items-start gap-2">
          <p className="rounded-xl bg-destructive/10 px-3 py-2 text-sm text-destructive">{error.message}</p>
          <Button type="button" variant="outline" size="sm" onClick={() => refetch()}>
            <RotateCw className="size-4" />
            Thử lại
          </Button>
        </div>
      ) : (
        <>
          <ol className="mt-4 grid grid-cols-7 gap-2" aria-label={`Đã điểm danh ${days}/${total} ngày`}>
            {Array.from({ length: total }, (_, index) => {
              const done = index < days;
              return (
                <li
                  key={index}
                  className={cn(
                    "grid aspect-square place-items-center rounded-2xl text-sm font-semibold",
                    done ? "bg-brand text-brand-foreground" : "bg-surface text-subtle"
                  )}
                >
                  {done ? <Check className="size-4" /> : index + 1}
                </li>
              );
            })}
          </ol>
          <p className="mt-3 text-sm text-body">
            {progress.completed
              ? "Bạn đã hoàn thành thử thách."
              : progress.broken
                ? "Chuỗi ngày đã bị gián đoạn, điểm danh hôm nay để bắt đầu lại."
                : `Đã điểm danh ${days}/${total} ngày.`}
          </p>

          {badgePending && (
            <p className="mt-3 rounded-xl bg-warning/10 px-3 py-2 text-sm text-ink">
              Huy hiệu chưa được cấp. Điểm danh của bạn đã được lưu, bấm “Nhận huy hiệu” để thử lại.
            </p>
          )}

          <div className="mt-4 flex flex-wrap items-center gap-3">
            {badgePending ? (
              <Button type="button" size="md" onClick={handleCheckIn} disabled={checkIn.isPending}>
                {checkIn.isPending ? <Loader2 className="size-4 animate-spin" /> : <Award className="size-4" />}
                Nhận huy hiệu
              </Button>
            ) : progress.completed ? (
              <span className="inline-flex items-center gap-1.5 rounded-full bg-brand-soft px-3 py-1.5 text-sm font-semibold text-brand">
                <Award className="size-4" />
                {progress.badgeName ?? "Trái Tim Xanh"}
              </span>
            ) : (
              <Button type="button" size="md" onClick={handleCheckIn} disabled={checkIn.isPending || progress.checkedToday}>
                {checkIn.isPending ? <Loader2 className="size-4 animate-spin" /> : <CalendarCheck className="size-4" />}
                {progress.checkedToday ? "Hôm nay đã điểm danh" : "Điểm danh hôm nay"}
              </Button>
            )}
          </div>
        </>
      )}
    </section>
  );
}
