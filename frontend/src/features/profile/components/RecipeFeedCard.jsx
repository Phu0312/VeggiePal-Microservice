import { Link } from "react-router-dom";
import { Eye, ImageOff, Loader2, ArrowRight, Clock, Sprout } from "lucide-react";

import BlogPostCard from "@/features/blog/components/BlogPostCard";
import AuthorAvatar from "@/features/blog/components/AuthorAvatar";
import { useMyBlogs } from "@/features/blog/hooks/useMyBlogs";
import { useMyVotes } from "@/features/blog/hooks/useBlogVotes";
import { useMyRecipes } from "@/features/recipe/hooks/useMyRecipes";
import { useProfile } from "@/features/profile/hooks/useProfile";
import { formatCompactNumber, formatTimeAgo } from "@/features/blog/utils/blogFormat";
import FallbackImage from "@/shared/components/FallbackImage";
import {
  getStatusBadgeText,
  mergeAndSortContent,
} from "@/features/profile/utils/feedHelpers";

export default function RecipeFeedCard() {
  const { profile } = useProfile();
  const blogsQuery = useMyBlogs({ size: 10 });
  const recipesQuery = useMyRecipes({ size: 10 });

  const blogIds = (blogsQuery.posts || []).map((p) => p.id);
  const { data: myVotes } = useMyVotes(blogIds);

  const loading = blogsQuery.isPending || recipesQuery.isPending;
  const error = blogsQuery.error || recipesQuery.error;

  const displayName = profile?.fullName?.trim() || "Người dùng VeggiePal";
  const author = profile
    ? { fullName: displayName, avatarUrl: profile.avatarUrl }
    : undefined;

  const items = mergeAndSortContent(blogsQuery.posts, recipesQuery.recipes);

  if (loading) {
    return (
      <div className="bg-card rounded-3xl p-8 shadow-sm border border-border flex items-center justify-center gap-2 text-xs text-subtle">
        <Loader2 className="w-4 h-4 animate-spin text-brand" />
        Đang tải bài viết &amp; công thức…
      </div>
    );
  }

  if (error) {
    return (
      <div className="rounded-3xl bg-destructive/10 p-5 text-xs text-destructive">
        {error.message || "Không tải được danh sách bài viết & công thức"}
      </div>
    );
  }

  if (items.length === 0) {
    return (
      <div className="bg-card rounded-3xl p-8 shadow-sm border border-dashed border-border text-center text-xs text-subtle">
        Bạn chưa có bài viết hoặc công thức nào. Hãy chia sẻ món ăn thuần chay đầu tiên của bạn!
      </div>
    );
  }

  return (
    <div className="space-y-5">
      {items.map((item) => {
        // Bài viết (blog): hiển thị đúng giao diện BlogPostCard của trang Cộng đồng
        if (item.type === "blog") {
          return (
            <BlogPostCard
              key={item.id}
              post={item.rawBlog}
              author={author}
              myVote={myVotes?.get(item.originalId)}
            />
          );
        }

        // Công thức (recipe): áp dụng cùng layout thẻ chuẩn của trang cộng đồng
        const totalMinutes = (item.prepTime || 0) + (item.cookTime || 0);

        return (
          <article
            key={item.id}
            className="rounded-3xl border border-border bg-card p-5 shadow-sm sm:p-6"
          >
            <header className="flex items-center gap-3">
              <AuthorAvatar author={author} />
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-semibold text-ink">{displayName}</p>
                <p className="text-xs text-subtle">
                  {formatTimeAgo(item.date)}
                </p>
              </div>
              <span className="shrink-0 rounded-full bg-brand-soft px-2.5 py-1 text-[11px] font-medium text-brand">
                {item.categoryName || getStatusBadgeText(item.status) || "Công thức"}
              </span>
            </header>

            <h2 className="mt-4 font-heading text-xl font-bold leading-snug text-ink sm:text-2xl">
              <Link to={item.link} className="transition hover:text-brand">
                {item.title}
              </Link>
            </h2>

            {item.description && (
              <p className="mt-2 text-xs sm:text-sm text-subtle leading-relaxed line-clamp-2">
                {item.description}
              </p>
            )}

            {(item.servings != null || totalMinutes > 0) && (
              <div className="mt-3 flex flex-wrap items-center gap-2 text-xs font-semibold">
                {item.servings != null && (
                  <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-brand-soft text-brand">
                    <Sprout className="size-3.5" /> {item.servings} khẩu phần
                  </span>
                )}
                {totalMinutes > 0 && (
                  <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-sky-50 dark:bg-sky-950/60 text-sky-700 dark:text-sky-300">
                    <Clock className="size-3.5" /> {totalMinutes} phút
                  </span>
                )}
              </div>
            )}

            {item.imageUrl && (
              <Link to={item.link} tabIndex={-1} aria-hidden className="mt-4 block">
                <FallbackImage
                  src={item.imageUrl}
                  alt={item.title}
                  className="aspect-[4/3] w-full rounded-2xl object-cover sm:aspect-[16/10]"
                  draggable={false}
                  fallback={
                    <div className="grid aspect-[16/7] w-full place-items-center rounded-2xl bg-surface text-subtle">
                      <ImageOff className="size-8" />
                    </div>
                  }
                />
              </Link>
            )}

            {item.ingredients && item.ingredients.length > 0 && (
              <div className="mt-3 p-3 bg-surface rounded-xl text-[11px] text-body flex flex-wrap items-center gap-2">
                <strong className="text-ink">Nguyên liệu chính:</strong>
                {item.ingredients.map((ing, idx) => (
                  <span key={idx}>
                    • {ing.quantity ? `${ing.quantity} ` : ""}
                    {ing.unit ? `${ing.unit} ` : ""}
                    {ing.ingredientName || ing.name}
                  </span>
                ))}
              </div>
            )}

            <footer className="mt-4 flex items-center gap-5 border-t border-border pt-3 text-sm text-subtle">
              {item.viewCount != null && (
                <span className="flex items-center gap-1.5">
                  <Eye className="size-4" />
                  {formatCompactNumber(item.viewCount)} lượt xem
                </span>
              )}
              <Link
                to={item.link}
                className="ml-auto inline-flex items-center gap-1 text-sm font-medium text-brand transition hover:underline"
              >
                Xem chi tiết <ArrowRight className="size-4" />
              </Link>
            </footer>
          </article>
        );
      })}
    </div>
  );
}
