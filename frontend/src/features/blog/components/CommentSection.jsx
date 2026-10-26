import { Link, useLocation } from "react-router-dom";
import { Loader2, MessageCircle } from "lucide-react";

import { Button } from "@/components/ui/button";
import { useRequireLogin } from "@/features/auth/hooks/useRequireLogin";
import CommentComposer from "@/features/blog/components/CommentComposer";
import CommentItem from "@/features/blog/components/CommentItem";
import { useComments } from "@/features/blog/hooks/useComments";
import { usePublicUsers } from "@/shared/hooks/usePublicUsers";

// Bình luận của một bài. `total` là số comment cấp 1 (không gồm reply).
// Đã đăng nhập thì có ô viết bình luận; khách thấy lời mời đăng nhập.
export default function CommentSection({ blogId }) {
  const { isAuthenticated } = useRequireLogin();
  const location = useLocation();
  const {
    comments,
    total,
    isPending,
    isError,
    error,
    hasNextPage,
    fetchNextPage,
    isFetchingNextPage,
  } = useComments(blogId);
  const { data: authors } = usePublicUsers(comments.map((c) => c.authorId));

  return (
    <section className="rounded-3xl border border-border bg-card p-5 shadow-sm sm:p-6">
      <h2 className="flex items-center gap-2 font-heading text-lg font-bold text-ink">
        <MessageCircle className="size-5 text-brand" />
        Bình luận{!isPending && !isError && ` (${total})`}
      </h2>

      <div className="mt-4">
        {isAuthenticated ? (
          <CommentComposer blogId={blogId} />
        ) : (
          <p className="rounded-2xl bg-surface px-4 py-3 text-sm text-subtle">
            <Link
              to="/login"
              state={{ from: location }}
              className="font-medium text-brand hover:underline"
            >
              Đăng nhập
            </Link>{" "}
            để tham gia bình luận.
          </p>
        )}
      </div>

      {isError ? (
        <p className="mt-5 rounded-xl bg-destructive/10 px-3 py-2 text-sm text-destructive">
          {error.message}
        </p>
      ) : isPending ? (
        <p className="mt-5 flex items-center gap-2 text-sm text-subtle">
          <Loader2 className="size-4 animate-spin" />
          Đang tải bình luận...
        </p>
      ) : comments.length === 0 ? (
        <p className="mt-5 text-sm text-subtle">Chưa có bình luận nào cho bài viết này.</p>
      ) : (
        <>
          <ul className="mt-5 space-y-5">
            {comments.map((comment) => (
              <CommentItem
                key={comment.id}
                comment={comment}
                author={authors?.get(comment.authorId)}
              />
            ))}
          </ul>

          {hasNextPage && (
            <Button
              type="button"
              variant="outline"
              size="sm"
              className="mt-5"
              disabled={isFetchingNextPage}
              onClick={() => fetchNextPage()}
            >
              {isFetchingNextPage ? (
                <>
                  <Loader2 className="size-4 animate-spin" />
                  Đang tải...
                </>
              ) : (
                "Xem thêm bình luận"
              )}
            </Button>
          )}
        </>
      )}
    </section>
  );
}
