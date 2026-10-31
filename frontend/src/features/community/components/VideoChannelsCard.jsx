import { Tv } from "lucide-react";

import AuthorRankList from "@/features/community/components/AuthorRankList";
import { useVideoChannels } from "@/features/community/hooks/useCommunity";

const n = (value) => Number(value ?? 0).toLocaleString("vi-VN");

// Kênh video gợi ý (GET /videos/channels).
export default function VideoChannelsCard() {
  const channels = useVideoChannels(5);

  return (
    <section className="rounded-3xl border border-border bg-card p-5 shadow-sm">
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
  );
}
