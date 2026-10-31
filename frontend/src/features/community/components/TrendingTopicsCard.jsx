import { Link } from "react-router-dom";
import { Hash, Loader2 } from "lucide-react";

import { useTrendingTopics } from "@/features/community/hooks/useCommunity";

const n = (value) => Number(value ?? 0).toLocaleString("vi-VN");

// Chủ đề nổi bật (GET /blogs/community/trending-topics); bấm một chủ đề thì lọc feed theo danh mục đó.
export default function TrendingTopicsCard() {
  const topics = useTrendingTopics(8);

  return (
    <section className="rounded-3xl border border-border bg-card p-5 shadow-sm">
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
        <p className="mt-4 rounded-xl bg-destructive/10 px-3 py-2 text-sm text-destructive">{topics.error.message}</p>
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
  );
}
