import { Link } from "react-router-dom";
import { FileText, Hash, Loader2, MessageCircle, SquarePlay, Trophy, Tv, Users } from "lucide-react";

import { buttonVariants } from "@/components/ui/variants/button-variants";
import AuthorRankList from "@/features/community/components/AuthorRankList";
import ChallengeCard from "@/features/community/components/ChallengeCard";
import {
  useCommunityStats,
  useLeaderboard,
  useTrendingTopics,
  useVideoChannels,
} from "@/features/community/hooks/useCommunity";
import AppHeader from "@/shared/components/AppHeader";
import GlassBanner, { GlassChip } from "@/shared/components/GlassBanner";
import Reveal from "@/shared/components/Reveal";

const cardClass = "rounded-3xl border border-border bg-card p-5 shadow-sm sm:p-6";
const n = (value) => Number(value ?? 0).toLocaleString("vi-VN");

const STATS = [
  { key: "publishedBlogs", label: "Bài viết", icon: FileText },
  { key: "publishedVideos", label: "Video", icon: SquarePlay },
  { key: "activeAuthors", label: "Tác giả", icon: Users },
  { key: "totalComments", label: "Bình luận", icon: MessageCircle },
];

// Trang "Cộng đồng" (route /community, khách xem được): số liệu chung, chủ đề nổi bật, bảng vàng tác giả,
// kênh video gợi ý và thử thách 7 ngày (thử thách và theo dõi cần đăng nhập).
export default function CommunityScreen() {
  const stats = useCommunityStats();
  const topics = useTrendingTopics(8);
  const leaderboard = useLeaderboard(5);
  const channels = useVideoChannels(5);

  return (
    <div className="min-h-dvh bg-canvas">
      <AppHeader />

      <main className="mx-auto flex w-full max-w-6xl flex-col gap-6 px-4 py-6 sm:px-6 lg:px-8">
        <GlassBanner>
          <GlassChip icon={Users}>Cộng Đồng VeggiePal</GlassChip>
          <h1 className="mt-3 font-heading text-3xl font-extrabold text-ink sm:text-4xl">Bảng Vàng &amp; Thử Thách</h1>
          <p className="mt-2 max-w-xl text-sm leading-relaxed text-body">
            Xem ai đang chia sẻ nhiều nhất, chủ đề được quan tâm và cùng nhau giữ chuỗi 7 ngày sống thuần chay.
          </p>
          <Link to="/blog" className={buttonVariants({ variant: "outline", size: "sm", className: "mt-4" })}>
            Đọc bài viết cộng đồng
          </Link>
        </GlassBanner>

        <Reveal>
          {stats.isPending ? (
            <p className="flex items-center gap-2 text-sm text-subtle">
              <Loader2 className="size-4 animate-spin" />
              Đang tải số liệu...
            </p>
          ) : stats.isError ? (
            <p className="rounded-xl bg-destructive/10 px-3 py-2 text-sm text-destructive">{stats.error.message}</p>
          ) : (
            <dl className="grid grid-cols-2 gap-3 sm:grid-cols-4">
              {STATS.map(({ key, label, icon: Icon }) => (
                <div key={key} className="rounded-3xl border border-border bg-card p-4 shadow-sm">
                  <dt className="flex items-center gap-1.5 text-xs font-semibold text-subtle">
                    <Icon className="size-4 text-brand" />
                    {label}
                  </dt>
                  <dd className="mt-1 font-heading text-2xl font-extrabold text-ink">{n(stats.data?.[key])}</dd>
                </div>
              ))}
            </dl>
          )}
        </Reveal>

        <div className="grid gap-6 lg:grid-cols-2">
          <Reveal>
            <ChallengeCard />
          </Reveal>

          <Reveal>
            <section className={cardClass}>
              <h2 className="flex items-center gap-2 font-heading text-lg font-bold text-ink">
                <Hash className="size-5 text-brand" />
                Chủ đề nổi bật
              </h2>
              {topics.isPending ? (
                <p className="mt-4 flex items-center gap-2 text-sm text-subtle">
                  <Loader2 className="size-4 animate-spin" />
                  Đang tải...
                </p>
              ) : topics.isError ? (
                <p className="mt-4 rounded-xl bg-destructive/10 px-3 py-2 text-sm text-destructive">
                  {topics.error.message}
                </p>
              ) : topics.data.length === 0 ? (
                <p className="mt-4 text-sm text-subtle">Chưa có chủ đề nào.</p>
              ) : (
                <ul className="mt-4 flex flex-wrap gap-2">
                  {topics.data.map((topic) => (
                    <li key={topic.categoryId ?? topic.tag}>
                      <Link
                        to={topic.categoryId ? `/blog?category=${topic.categoryId}` : "/blog"}
                        className="inline-flex items-center gap-1.5 rounded-full bg-brand-soft px-3 py-1.5 text-sm font-medium text-brand-deep transition hover:bg-brand/15"
                      >
                        {topic.tag || `#${topic.name}`}
                        <span className="text-xs text-subtle">{n(topic.count)}</span>
                      </Link>
                    </li>
                  ))}
                </ul>
              )}
            </section>
          </Reveal>

          <Reveal>
            <section className={cardClass}>
              <h2 className="mb-4 flex items-center gap-2 font-heading text-lg font-bold text-ink">
                <Trophy className="size-5 text-warning" />
                Bảng vàng tác giả
              </h2>
              <AuthorRankList
                query={leaderboard}
                emptyText="Chưa có tác giả nào trên bảng vàng."
                describe={(entry) =>
                  `${n(entry.articlesCount)} bài · ${n(entry.videosCount)} video · ${n(entry.totalLikes)} lượt thích · ${n(entry.followersCount)} người theo dõi`
                }
              />
            </section>
          </Reveal>

          <Reveal>
            <section className={cardClass}>
              <h2 className="mb-4 flex items-center gap-2 font-heading text-lg font-bold text-ink">
                <Tv className="size-5 text-chart-2" />
                Kênh video gợi ý
              </h2>
              <AuthorRankList
                query={channels}
                emptyText="Chưa có kênh video nào."
                describe={(entry) =>
                  `${n(entry.videoCount)} video · ${n(entry.totalViews)} lượt xem · ${n(entry.followersCount)} người theo dõi`
                }
              />
            </section>
          </Reveal>
        </div>
      </main>
    </div>
  );
}
