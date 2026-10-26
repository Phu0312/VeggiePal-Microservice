import { useState } from "react";
import { Link } from "react-router-dom";
import { Eye, Heart, ImageOff, Loader2 } from "lucide-react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { buttonVariants } from "@/components/ui/variants/button-variants";
import { useDeleteBlog, useSubmitBlog } from "@/features/blog/hooks/useBlogMutations";
import { useMyBlogs } from "@/features/blog/hooks/useMyBlogs";
import { formatCompactNumber, formatTimeAgo } from "@/features/blog/utils/blogFormat";
import { describeBlogOutcome } from "@/features/blog/utils/blogForm";
import StatusBadge from "@/features/my-content/components/StatusBadge";
import {
  BLOG_STATUS_FILTERS,
  canEditBlog,
  canSubmitBlog,
  getBlogStatusInfo,
} from "@/features/my-content/utils/statusInfo";
import { cn } from "@/lib/utils";
import ConfirmDialog from "@/shared/components/ConfirmDialog";
import FallbackImage from "@/shared/components/FallbackImage";

// Tab "Bài viết": lọc theo trạng thái (GET /blogs/me?status=) + danh sách "Xem thêm",
// mỗi dòng có Sửa / Gửi duyệt / Xóa tùy trạng thái.
export default function MyBlogList() {
  const [status, setStatus] = useState("");
  const { posts, total, isPending, isError, error, hasNextPage, fetchNextPage, isFetchingNextPage } =
    useMyBlogs({ status });

  return (
    <div className="flex flex-col gap-4">
      <div className="no-scrollbar flex items-center gap-1 overflow-x-auto">
        {BLOG_STATUS_FILTERS.map(({ value, label }) => (
          <button
            key={label}
            type="button"
            onClick={() => setStatus(value)}
            aria-pressed={status === value}
            className={cn(
              "shrink-0 rounded-full px-3.5 py-1.5 text-sm font-medium transition",
              status === value
                ? "bg-brand-soft text-brand"
                : "text-subtle hover:bg-surface hover:text-ink"
            )}
          >
            {label}
          </button>
        ))}
      </div>

      {isError ? (
        <p className="rounded-xl bg-destructive/10 px-3 py-2 text-sm text-destructive">
          {error.message}
        </p>
      ) : isPending ? (
        <RowSkeletons />
      ) : posts.length === 0 ? (
        <p className="rounded-3xl border border-border bg-card p-6 text-sm text-subtle">
          {status ? "Không có bài viết nào ở trạng thái này." : "Bạn chưa có bài viết nào."}
        </p>
      ) : (
        <>
          <p className="text-xs text-subtle">{total} bài viết</p>
          <ul className="flex flex-col gap-3">
            {posts.map((post) => (
              <BlogRow key={post.id} post={post} />
            ))}
          </ul>
          {hasNextPage && (
            <Button
              type="button"
              variant="outline"
              className="self-center"
              disabled={isFetchingNextPage}
              onClick={() => fetchNextPage()}
            >
              {isFetchingNextPage ? (
                <>
                  <Loader2 className="size-4 animate-spin" />
                  Đang tải...
                </>
              ) : (
                "Xem thêm"
              )}
            </Button>
          )}
        </>
      )}
    </div>
  );
}

function BlogRow({ post }) {
  const [confirmDelete, setConfirmDelete] = useState(false);
  const submitBlog = useSubmitBlog();
  const deleteBlog = useDeleteBlog();

  const info = getBlogStatusInfo(post.status);
  const isPublished = post.status === "PUBLISHED";

  const handleSubmit = () =>
    submitBlog.mutate(post.id, {
      onSuccess: (result) => {
        const { tone, message } = describeBlogOutcome(result);
        if (tone === "error") toast.error(message);
        else if (tone === "info") toast.info(message);
        else toast.success(message);
      },
      onError: (error) => toast.error(error.message),
    });

  const handleDelete = () =>
    deleteBlog.mutate(post.id, {
      onSuccess: () => {
        setConfirmDelete(false);
        toast.success("Đã xóa bài viết");
      },
      onError: (error) => toast.error(error.message),
    });

  const summary = (
    <>
      <FallbackImage
        src={post.thumbnailUrl}
        className="size-20 shrink-0 rounded-2xl object-cover"
        draggable={false}
        fallback={
          <span className="grid size-20 shrink-0 place-items-center rounded-2xl bg-surface text-subtle">
            <ImageOff className="size-6" />
          </span>
        }
      />

      <div className="min-w-0 flex-1">
        <div className="flex flex-wrap items-center gap-2">
          <StatusBadge info={info} />
          {post.categoryName && <span className="text-xs text-subtle">{post.categoryName}</span>}
        </div>
        <h3 className="mt-1.5 line-clamp-2 font-heading text-base font-bold leading-snug text-ink">
          {post.title}
        </h3>
        <p className="mt-1 flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-subtle">
          <span>{formatTimeAgo(post.publishedAt ?? post.createdAt)}</span>
          {isPublished ? (
            <>
              <span className="flex items-center gap-1">
                <Heart className="size-3.5 text-destructive" />
                {post.voteScore.toLocaleString("vi-VN")}
              </span>
              <span className="flex items-center gap-1">
                <Eye className="size-3.5" />
                {formatCompactNumber(post.viewCount)}
              </span>
            </>
          ) : (
            info.hint && <span>{info.hint}</span>
          )}
        </p>
      </div>
    </>
  );

  return (
    <li className="rounded-3xl border border-border bg-card p-4 shadow-sm">
      {/* Chủ bài đọc được cả bài chưa đăng (trang đọc sẽ hiện nhãn trạng thái). */}
      <Link to={`/blog/${post.id}`} className="flex gap-4">
        {summary}
      </Link>

      <div className="mt-3 flex flex-wrap justify-end gap-2 border-t border-border pt-3">
        {canEditBlog(post.status) && (
          <Link
            to={`/blog/${post.id}/edit`}
            className={buttonVariants({ variant: "outline", size: "xs" })}
          >
            Sửa
          </Link>
        )}
        {canSubmitBlog(post.status) && (
          <Button type="button" size="xs" disabled={submitBlog.isPending} onClick={handleSubmit}>
            {submitBlog.isPending && <Loader2 className="size-3 animate-spin" />}
            Gửi duyệt
          </Button>
        )}
        <Button type="button" size="xs" variant="ghost" onClick={() => setConfirmDelete(true)}>
          <span className="text-destructive">Xóa</span>
        </Button>
      </div>

      <ConfirmDialog
        open={confirmDelete}
        onOpenChange={setConfirmDelete}
        title="Xóa bài viết?"
        description={`“${post.title}” sẽ bị xóa vĩnh viễn cùng các bình luận và lượt thích. Hành động này không thể hoàn tác.`}
        loading={deleteBlog.isPending}
        onConfirm={handleDelete}
      />
    </li>
  );
}

function RowSkeletons() {
  return (
    <div aria-hidden className="flex flex-col gap-3">
      {[0, 1, 2].map((i) => (
        <div
          key={i}
          className="flex animate-pulse gap-4 rounded-3xl border border-border bg-card p-4 shadow-sm"
        >
          <div className="size-20 shrink-0 rounded-2xl bg-surface" />
          <div className="flex-1 space-y-2.5 py-1">
            <div className="h-4 w-20 rounded-full bg-surface" />
            <div className="h-4 w-4/5 rounded bg-surface" />
            <div className="h-3 w-1/3 rounded bg-surface" />
          </div>
        </div>
      ))}
    </div>
  );
}
