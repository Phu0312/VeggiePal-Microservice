import { Link } from "react-router-dom";
import { Eye, ImageOff } from "lucide-react";

import { useRelatedBlogs } from "@/features/blog/hooks/useBlogs";
import { formatCompactNumber, formatTimeAgo } from "@/features/blog/utils/blogFormat";
import FallbackImage from "@/shared/components/FallbackImage";

// Tối đa 5 bài cùng danh mục (GET /blogs/:id/related). Không có bài liên quan thì ẩn cả khối.
export default function RelatedBlogs({ blogId }) {
  const { data: related, isPending, isError } = useRelatedBlogs(blogId);

  if (isError || (!isPending && related.length === 0)) return null;

  return (
    <section className="rounded-3xl border border-border bg-card p-5 shadow-sm">
      <h2 className="font-heading text-base font-bold text-ink">Bài viết liên quan</h2>

      {isPending ? (
        <div aria-hidden className="mt-4 space-y-3">
          {[0, 1, 2].map((i) => (
            <div key={i} className="flex animate-pulse gap-3">
              <div className="size-16 shrink-0 rounded-xl bg-surface" />
              <div className="flex-1 space-y-2 py-1">
                <div className="h-3 w-full rounded bg-surface" />
                <div className="h-3 w-2/3 rounded bg-surface" />
              </div>
            </div>
          ))}
        </div>
      ) : (
        <ul className="mt-4 space-y-3">
          {related.map((post) => (
            <li key={post.id}>
              <Link to={`/blog/${post.id}`} className="group flex gap-3">
                <FallbackImage
                  src={post.thumbnailUrl}
                  className="size-16 shrink-0 rounded-xl object-cover"
                  draggable={false}
                  fallback={
                    <span className="grid size-16 shrink-0 place-items-center rounded-xl bg-surface text-subtle">
                      <ImageOff className="size-5" />
                    </span>
                  }
                />
                <div className="min-w-0">
                  <h3 className="line-clamp-2 text-sm font-semibold leading-snug text-ink transition group-hover:text-brand">
                    {post.title}
                  </h3>
                  <p className="mt-1 flex items-center gap-1.5 text-xs text-subtle">
                    <Eye className="size-3" />
                    {formatCompactNumber(post.viewCount)} • {formatTimeAgo(post.publishedAt ?? post.createdAt)}
                  </p>
                </div>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}
