import { useState } from "react";
import { Trophy } from "lucide-react";

import { Button } from "@/components/ui/button";
import { leaderboard } from "@/features/blog/data/mockBlog";
import { cn } from "@/lib/utils";

// Màu huy chương cho top 3, dùng token chart để đúng cả light/dark.
const RANK_STYLES = [
  "bg-chart-4/20 text-chart-4",
  "bg-chart-2/20 text-chart-2",
  "bg-chart-5/20 text-chart-5",
];

export default function LeaderboardCard() {
  // Trạng thái theo dõi chỉ lưu tạm trong trang (chưa có API follow).
  const [following, setFollowing] = useState(
    () => new Set(leaderboard.filter((u) => u.following).map((u) => u.id))
  );

  const toggle = (id) =>
    setFollowing((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });

  return (
    <section className="rounded-3xl border border-border bg-card p-5 shadow-sm">
      <h2 className="flex items-center gap-2 font-heading text-base font-bold text-ink">
        <Trophy className="size-4 text-brand" />
        Bảng Vàng Bếp Xanh
      </h2>

      <ul className="mt-4 space-y-3">
        {leaderboard.map((user, index) => {
          const isFollowing = following.has(user.id);
          return (
            <li key={user.id} className="rounded-2xl bg-surface p-2.5">
              <div className="flex items-center gap-2.5">
                <span
                  className={cn(
                    "grid size-7 shrink-0 place-items-center rounded-full text-xs font-bold",
                    RANK_STYLES[index]
                  )}
                >
                  {index + 1}
                </span>
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-semibold text-ink">{user.name}</p>
                  <p className="truncate text-[11px] text-subtle">
                    {user.recipes != null
                      ? `${user.recipes} công thức`
                      : `${user.articles} bài viết`}{" "}
                    • {user.likes}
                  </p>
                </div>
              </div>
              {/* Nút theo dõi nằm dưới thông tin, rộng bằng cả ô. */}
              <Button
                type="button"
                size="sm"
                variant={isFollowing ? "soft" : "default"}
                className="mt-2.5 w-full"
                onClick={() => toggle(user.id)}
              >
                {isFollowing ? "Đang theo dõi" : "Theo dõi"}
              </Button>
            </li>
          );
        })}
      </ul>
    </section>
  );
}
