import { Link } from "react-router-dom";
import { ChevronRight, Gauge, NotebookPen, Trophy } from "lucide-react";

import AppHeader from "@/shared/components/AppHeader";
import Reveal from "@/shared/components/Reveal";
import QuotaUsageList from "@/features/payment/components/QuotaUsageList";
import { useProfile } from "@/features/profile/hooks/useProfile";

import ProfileBanner from "@/features/profile/components/ProfileBanner";
import EmailVerifyBanner from "@/features/profile/components/EmailVerifyBanner";
import CreatePostBox from "@/features/profile/components/CreatePostBox";
import RecipeFeedCard from "@/features/profile/components/RecipeFeedCard";
import BmiTrackerCard from "@/features/profile/components/BmiTrackerCard";
import BadgesCard from "@/features/profile/components/BadgesCard";
import FavoritesCard from "@/features/profile/components/FavoritesCard";

// Lối tắt tới các trang cá nhân không có trên thanh menu.
const SHORTCUTS = [
  {
    to: "/diary",
    icon: NotebookPen,
    title: "Nhật ký dinh dưỡng",
    description: "Ghi món đã ăn, nước và vận động mỗi ngày",
  },
  {
    to: "/blog",
    icon: Trophy,
    title: "Thử thách 7 ngày",
    description: "Điểm danh sống thuần chay, xem bảng vàng cộng đồng",
  },
];

export default function ProfileScreen() {
  const { profile } = useProfile();

  return (
    <div className="min-h-dvh bg-canvas transition-colors duration-200">
      <AppHeader />

      <main className="mx-auto flex w-full max-w-4xl flex-col gap-6 px-4 py-6 sm:px-6 lg:px-8">
        <Reveal>
          <ProfileBanner profile={profile} />
        </Reveal>

        <EmailVerifyBanner profile={profile} />

        <Reveal>
          <div className="grid gap-3 sm:grid-cols-2">
            {SHORTCUTS.map(({ to, icon: Icon, title, description }) => (
              <Link
                key={to}
                to={to}
                className="group flex items-center gap-3 rounded-3xl border border-border bg-card p-4 shadow-sm transition hover:border-brand/40"
              >
                <span className="grid size-11 shrink-0 place-items-center rounded-2xl bg-brand-soft text-brand">
                  <Icon className="size-5" />
                </span>
                <span className="min-w-0 flex-1">
                  <span className="block text-sm font-semibold text-ink">{title}</span>
                  <span className="block text-xs text-subtle">{description}</span>
                </span>
                <ChevronRight className="size-4 text-subtle transition group-hover:translate-x-0.5" />
              </Link>
            ))}
          </div>
        </Reveal>

        <Reveal>
          <section className="rounded-3xl border border-border bg-card p-5 shadow-sm sm:p-6">
            <h2 className="mb-4 flex items-center gap-2 font-heading text-lg font-bold text-ink">
              <Gauge className="size-5 text-brand" />
              Hạn mức sử dụng
            </h2>
            <QuotaUsageList />
          </section>
        </Reveal>

        <Reveal><CreatePostBox profile={profile} /></Reveal>
        <Reveal><RecipeFeedCard /></Reveal>
        <Reveal><BmiTrackerCard /></Reveal>
        <Reveal><BadgesCard /></Reveal>
        <Reveal><FavoritesCard /></Reveal>
      </main>

    </div>
  );
}
