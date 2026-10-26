import { useState } from "react";
import { Heart, ShieldAlert } from "lucide-react";

import AppHeader from "@/shared/components/AppHeader";
import AppFooter from "@/shared/components/AppFooter";
import Reveal from "@/shared/components/Reveal";
import { useProfile } from "@/features/profile/hooks/useProfile";

import ProfileBanner from "@/features/profile/components/ProfileBanner";
import ProfileTabs from "@/features/profile/components/ProfileTabs";
import DailyNutritionCard from "@/features/profile/components/DailyNutritionCard";
import FavoritesCard from "@/features/profile/components/FavoritesCard";
import GreenBadgesCard from "@/features/profile/components/GreenBadgesCard";
import CreatePostBox from "@/features/profile/components/CreatePostBox";
import RecipeFeedCard from "@/features/profile/components/RecipeFeedCard";
import BmiTrackerCard from "@/features/profile/components/BmiTrackerCard";

export default function ProfileScreen() {
  const { profile } = useProfile();
  const [activeTab, setActiveTab] = useState("posts");

  return (
    <div className="min-h-dvh bg-canvas transition-colors duration-200">
      <AppHeader />

      <main className="mx-auto flex w-full max-w-6xl flex-col gap-6 px-4 py-6 sm:px-6 lg:px-8">
        <Reveal>
          <ProfileBanner profile={profile} />
        </Reveal>

        <Reveal>
          <ProfileTabs activeTab={activeTab} setActiveTab={setActiveTab} />
        </Reveal>

        <div className="grid grid-cols-1 items-start gap-6 lg:grid-cols-12">
          {/* Cột trái (4/12) */}
          <div className="space-y-5 lg:col-span-4 lg:sticky lg:top-24 lg:self-start">
            <Reveal><DailyNutritionCard /></Reveal>
            <Reveal><FavoritesCard /></Reveal>
            <Reveal><GreenBadgesCard /></Reveal>
          </div>

          {/* Cột phải (8/12) — Nội dung thay đổi theo activeTab */}
          <div className="space-y-5 lg:col-span-8">
            {activeTab === "posts" && (
              <>
                <Reveal><CreatePostBox profile={profile} /></Reveal>
                <Reveal><RecipeFeedCard /></Reveal>
                <Reveal><BmiTrackerCard /></Reveal>
              </>
            )}

            {activeTab === "moderation" && (
              <Reveal>
                <div className="rounded-3xl border border-border bg-card p-12 text-center shadow-sm">
                  <ShieldAlert className="mx-auto h-10 w-10 text-warning mb-3" />
                  <h3 className="font-bold text-base text-ink">
                    Trạng thái kiểm duyệt AI
                  </h3>
                  <p className="mt-1 text-xs text-subtle max-w-sm mx-auto">
                    Tính năng đang được phát triển và sẽ sớm ra mắt trong các phiên bản tiếp theo.
                  </p>
                </div>
              </Reveal>
            )}

            {activeTab === "favorites" && (
              <Reveal>
                <div className="rounded-3xl border border-border bg-card p-12 text-center shadow-sm">
                  <Heart className="mx-auto h-10 w-10 text-rose-500 mb-3" />
                  <h3 className="font-bold text-base text-ink">
                    Đánh giá &amp; Yêu thích
                  </h3>
                  <p className="mt-1 text-xs text-subtle max-w-sm mx-auto">
                    Tính năng đang được phát triển và sẽ sớm ra mắt trong các phiên bản tiếp theo.
                  </p>
                </div>
              </Reveal>
            )}
          </div>
        </div>
      </main>

      <AppFooter />
    </div>
  );
}
