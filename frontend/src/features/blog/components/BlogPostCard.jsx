import { Link } from "react-router-dom";
import { Eye, ImageOff } from "lucide-react";

import AuthorAvatar from "@/features/blog/components/AuthorAvatar";
import VoteButton from "@/features/blog/components/VoteButton";
import {
  FALLBACK_AUTHOR_NAME,
  formatCompactNumber,
  formatTimeAgo,
} from "@/features/blog/utils/blogFormat";
import FallbackImage from "@/shared/components/FallbackImage";

// `post` là BlogSummaryResponse của BE (GET /blogs); `author` là { fullName, avatarUrl }
// từ usePublicUsers, có thể undefined (đang tải hoặc user không còn hiển thị công khai).
// `myVote` là vote của tôi trên bài này (từ useMyVotes), undefined với khách.
export default function BlogPostCard({ post, author, myVote }) {
  const authorName = author?.fullName ?? FALLBACK_AUTHOR_NAME;
  const detailPath = `/blog/${post.id}`;

  return (
    <article className="rounded-3xl border border-border bg-card p-5 shadow-sm sm:p-6">
      <header className="flex items-center gap-3">
        <AuthorAvatar author={author} />
        <div className="min-w-0 flex-1">
          <p className="truncate text-sm font-semibold text-ink">{authorName}</p>
          <p className="text-xs text-subtle">
            {formatTimeAgo(post.publishedAt ?? post.createdAt)}
          </p>
        </div>
        {post.categoryName && (
          <span className="shrink-0 rounded-full bg-brand-soft px-2.5 py-1 text-[11px] font-medium text-brand">
            {post.categoryName}
          </span>
        )}
      </header>

      <h2 className="mt-4 font-heading text-xl font-bold leading-snug text-ink sm:text-2xl">
        <Link to={detailPath} className="transition hover:text-brand">
          {post.title}
        </Link>
      </h2>

      <Link to={detailPath} tabIndex={-1} aria-hidden className="mt-4 block">
        <FallbackImage
          src={post.thumbnailUrl}
          className="aspect-[4/3] w-full rounded-2xl object-cover sm:aspect-[16/10]"
          draggable={false}
          // Chưa có ảnh bìa hoặc ảnh tải lỗi -> khung nền nhạt để các card không lệch nhau.
          fallback={
            <div className="grid aspect-[16/7] w-full place-items-center rounded-2xl bg-surface text-subtle">
              <ImageOff className="size-8" />
            </div>
          }
        />
      </Link>

      <footer className="mt-4 flex items-center gap-5 border-t border-border pt-3 text-sm text-subtle">
        <VoteButton blog={post} myVote={myVote} />
        <span className="flex items-center gap-1.5">
          <Eye className="size-4" />
          {formatCompactNumber(post.viewCount)} lượt xem
        </span>
        <Link
          to={detailPath}
          className="ml-auto text-sm font-medium text-brand transition hover:underline"
        >
          Đọc tiếp
        </Link>
      </footer>
    </article>
  );
}
