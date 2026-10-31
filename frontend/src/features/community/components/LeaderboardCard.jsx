import { Trophy } from "lucide-react";

import AuthorRankList from "@/features/community/components/AuthorRankList";
import { useLeaderboard } from "@/features/community/hooks/useCommunity";

const n = (value) => Number(value ?? 0).toLocaleString("vi-VN");

// Bảng vàng tác giả (GET /blogs/community/leaderboard).
export default function LeaderboardCard() {
  const leaderboard = useLeaderboard(5);

  return (
    <section className="rounded-3xl border border-border bg-card p-5 shadow-sm">
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
  );
}
