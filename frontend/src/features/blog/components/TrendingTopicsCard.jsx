import { Hash } from "lucide-react";

import { trendingTopics } from "@/features/blog/data/mockBlog";

export default function TrendingTopicsCard() {
  return (
    <section className="rounded-3xl border border-border bg-card p-5 shadow-sm">
      <h2 className="flex items-center gap-2 font-heading text-base font-bold text-ink">
        <Hash className="size-4 text-brand" />
        Chủ Đề Đang Sôi Nổi
      </h2>

      <ul className="mt-4 flex flex-wrap gap-2">
        {trendingTopics.map(({ id, tag, count }) => (
          <li key={id}>
            <button
              type="button"
              className="rounded-full bg-brand-soft px-2.5 py-1 text-[11px] font-medium text-brand transition hover:opacity-80"
            >
              #{tag} <span className="text-subtle">({count})</span>
            </button>
          </li>
        ))}
      </ul>
    </section>
  );
}
