import { useNavigate, Link } from "react-router-dom";
import { Edit3, Video, Activity, Crown, History } from "lucide-react";

import { Button } from "@/components/ui/button";
import { useProfileStats } from "@/features/profile/hooks/useProfileStats";
import { useMySubscription } from "@/features/payment/hooks/useMySubscription";
import { formatDate } from "@/features/payment/utils/paymentFormat";

const DEFAULT_AVATAR =
  "https://ui-avatars.com/api/?name=User&background=10b981&color=fff&size=256";

export default function ProfileBanner({ profile }) {
  const navigate = useNavigate();
  const stats = useProfileStats();
  const { subscription } = useMySubscription();

  const displayName = profile?.fullName?.trim() || "Người dùng VeggiePal";
  const avatarUrl = profile?.avatarUrl || DEFAULT_AVATAR;

  const { latest } = stats;
  const totalPosts = stats.loading ? "…" : stats.blogTotal + stats.recipeTotal;

  return (
    <div className="mb-2">
      {/* Ảnh bìa: nền gradient thương hiệu (không có ảnh bìa từ BE) */}
      <div
        aria-hidden
        className="h-40 w-full rounded-3xl bg-gradient-to-br from-[#1b5e20] via-brand to-brand-2 shadow-sm sm:h-52"
      />

      {/* Profile Card Container */}
      <div className="relative z-10 -mt-16 mx-2 rounded-3xl border border-border bg-card p-5 shadow-sm sm:-mt-20 sm:mx-6 sm:p-7">
        <div className="flex flex-col items-center justify-between gap-5 md:flex-row md:items-start">
          <div className="flex flex-col items-center gap-4 text-center sm:flex-row sm:items-start sm:text-left">
            <div className="h-24 w-24 shrink-0 overflow-hidden rounded-full border-4 border-card bg-surface shadow-md sm:h-28 sm:w-28">
              <img
                src={avatarUrl}
                alt={displayName}
                className="h-full w-full object-cover"
                onError={(e) => {
                  e.currentTarget.src = DEFAULT_AVATAR;
                }}
              />
            </div>

            <div>
              <div className="mb-1 flex flex-wrap items-center justify-center gap-2 sm:justify-start">
                <h1 className="text-2xl font-bold text-ink">{displayName}</h1>
                {/* Gói thành viên hiện tại */}
                <Link
                  to="/pricing"
                  className="inline-flex items-center gap-1.5 rounded-full border border-amber-500/30 bg-amber-500/10 px-3 py-0.5 text-xs font-semibold text-amber-700 dark:text-amber-400 hover:opacity-85 transition"
                >
                  <Crown className="size-3.5 text-amber-500" />
                  Gói {subscription?.planCode || "FREE"}
                  {subscription?.expiresAt && ` (Hạn: ${formatDate(subscription.expiresAt)})`}
                </Link>
              </div>
              {/* @username: chỉ hiển thị khi có trường username */}
              {profile?.username && (
                <p className="mb-2 text-xs font-medium text-subtle">
                  @{profile.username}
                </p>
              )}
            </div>
          </div>

          <div className="flex shrink-0 items-center gap-2 flex-wrap justify-center">
            {/* Nút Sửa hồ sơ -> điều hướng sang /profile/edit */}
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={() => navigate("/profile/edit")}
              className="rounded-full gap-2 cursor-pointer font-semibold"
            >
              <Edit3 className="h-4 w-4" />
              Sửa hồ sơ
            </Button>

            {/* Nút Lịch sử thanh toán */}
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={() => navigate("/payment/history")}
              className="rounded-full gap-1.5 cursor-pointer font-medium text-subtle hover:text-ink"
            >
              <History className="h-4 w-4" />
              Lịch sử gói
            </Button>
          </div>
        </div>

        {/* Thống kê: tổng thật từ /blogs/me, /recipes/me và bản ghi sức khỏe mới nhất */}
        <div className="mt-6 grid grid-cols-2 gap-3 border-t border-border pt-5">
          <div className="flex items-center gap-3 rounded-2xl border border-border bg-surface p-3">
            <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-brand-soft text-brand">
              <Video className="h-5 w-5" />
            </div>
            <div>
              <div className="text-base font-bold text-ink">{totalPosts}</div>
              <div className="text-xs text-subtle">Bài viết &amp; Công thức</div>
            </div>
          </div>

          {/* Thẻ BMI: lấy từ health record mới nhất */}
          <div className="flex items-center gap-3 rounded-2xl border border-border bg-surface p-3">
            <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-teal-50 text-teal-700 dark:bg-teal-950/60 dark:text-teal-400">
              <Activity className="h-5 w-5" />
            </div>
            <div>
              <div className="text-base font-bold text-ink">
                {latest?.bmi != null ? Number(latest.bmi).toFixed(1) : "—"}
              </div>
              <div className="text-xs font-normal text-subtle">BMI</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
