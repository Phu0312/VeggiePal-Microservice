import { Link, useLocation, useNavigate, useParams } from "react-router-dom";
import { ArrowLeft, Eye, ImageOff } from "lucide-react";

import { Button } from "@/components/ui/button";
import { useAuthStore } from "@/features/auth/store/authStore";
import AuthorAvatar from "@/features/blog/components/AuthorAvatar";
import CommentSection from "@/features/blog/components/CommentSection";
import RelatedBlogs from "@/features/blog/components/RelatedBlogs";
import VoteButton from "@/features/blog/components/VoteButton";
import { useMyVotes } from "@/features/blog/hooks/useBlogVotes";
import { useBlog } from "@/features/blog/hooks/useBlogs";
import {
  FALLBACK_AUTHOR_NAME,
  formatCompactNumber,
  formatTimeAgo,
} from "@/features/blog/utils/blogFormat";
import StatusBadge from "@/features/my-content/components/StatusBadge";
import { canEditBlog, getBlogStatusInfo } from "@/features/my-content/utils/statusInfo";
import AppFooter from "@/shared/components/AppFooter";
import AppHeader from "@/shared/components/AppHeader";
import FallbackImage from "@/shared/components/FallbackImage";
import { usePublicUsers } from "@/shared/hooks/usePublicUsers";

// Trang đọc một bài (route /blog/:blogId), công khai. Nội dung BE lưu là text thuần,
// nên hiển thị bằng text (giữ xuống dòng) chứ không render HTML.
// Chủ bài / ADMIN (kèm token) còn mở được bài chưa đăng: lúc đó hiện nhãn trạng thái và ẩn vote,
// bình luận, bài liên quan vì những phần này chỉ dành cho bài đã đăng.
export default function BlogDetailScreen() {
  const { blogId } = useParams();
  const navigate = useNavigate();
  const location = useLocation();

  // Id không phải số nguyên dương thì không gọi API, hiện luôn "không tìm thấy".
  const id = /^[1-9]\d*$/.test(blogId ?? "") ? Number(blogId) : null;
  const user = useAuthStore((s) => s.user);
  const { data: blog, isPending, isError } = useBlog(id);
  const isPublished = blog?.status === "PUBLISHED";
  const { data: authors } = usePublicUsers(blog ? [blog.authorId] : []);
  const author = blog ? authors?.get(blog.authorId) : undefined;
  const { data: myVotes } = useMyVotes(isPublished ? [blog.id] : []);
  const statusInfo = getBlogStatusInfo(blog?.status);
  // Chỉ tác giả mới có nút sửa ở đây (admin xem để kiểm duyệt, không sửa hộ).
  const canEdit = blog && blog.authorId === user?.id && canEditBlog(blog.status);

  // Có lịch sử trong app thì quay lại (giữ nguyên bộ lọc của feed), mở thẳng link thì về /blog.
  const goBack = () => (location.key !== "default" ? navigate(-1) : navigate("/blog"));

  return (
    <div className="min-h-dvh">
      <AppHeader />

      {/* 3 cột như trang Cộng đồng: trái là nút quay lại, bài chính ở giữa, bài liên quan bên phải.
          Nút quay lại nằm ở cột trái nên khung bài chính và khung bài liên quan bắt đầu cùng một mức.
          Hai cột bên rộng gần bằng nhau nên bài luôn nằm đúng giữa trang, kể cả khi chưa có bài
          liên quan. Dưới lg chỉ còn 1 cột: nút quay lại, bài, rồi bài liên quan. */}
      <main className="mx-auto w-full max-w-[1280px] px-6 py-6">
        <div className="grid grid-cols-1 items-start gap-6 lg:grid-cols-[250px_minmax(0,1fr)_300px]">
          <aside>
            <Button type="button" variant="ghost" size="sm" onClick={goBack}>
              <ArrowLeft className="size-4" />
              Quay lại Cộng đồng
            </Button>
          </aside>

          <div className="flex min-w-0 flex-col gap-6">
            {id === null || isError ? (
              <NotFound />
            ) : isPending ? (
              <ArticleSkeleton />
            ) : (
              <>
                {!isPublished && (
                  <div className="flex flex-wrap items-center gap-3 rounded-2xl bg-warning/10 px-4 py-3 text-sm text-body ring-1 ring-warning/30">
                    <StatusBadge info={statusInfo} />
                    <span className="min-w-0 flex-1 text-subtle">
                      {statusInfo.hint || "Bài viết này chưa được đăng công khai."}
                    </span>
                    {canEdit && (
                      <Link
                        to={`/blog/${blog.id}/edit`}
                        className="shrink-0 font-semibold text-brand underline-offset-2 hover:underline"
                      >
                        Sửa bài
                      </Link>
                    )}
                  </div>
                )}

                <article className="rounded-3xl border border-border bg-card p-5 shadow-sm sm:p-8">
                  <div className="flex items-center gap-3">
                    <AuthorAvatar author={author} />
                    <div className="min-w-0">
                      <p className="truncate text-sm font-semibold text-ink">
                        {author?.fullName ?? FALLBACK_AUTHOR_NAME}
                      </p>
                      <p className="text-xs text-subtle">
                        {formatTimeAgo(blog.publishedAt ?? blog.createdAt)}
                      </p>
                    </div>
                    {/* Bên phải: danh mục, và ngay dưới là tim + lượt xem cỡ nhỏ (không chen vào hàng tiêu đề,
                        vì tiêu đề dài sẽ đẩy chúng xuống dòng). */}
                    <div className="ml-auto flex shrink-0 flex-col items-end gap-1.5">
                      {blog.categoryName && (
                        <span className="rounded-full bg-brand-soft px-2.5 py-1 text-[11px] font-medium text-brand">
                          {blog.categoryName}
                        </span>
                      )}
                      {isPublished && (
                        <div className="flex items-center gap-3 text-sm font-medium text-body">
                          <VoteButton blog={blog} myVote={myVotes?.get(blog.id)} />
                          <span className="flex items-center gap-1.5">
                            <Eye className="size-4 text-brand" />
                            {formatCompactNumber(blog.viewCount)}
                          </span>
                        </div>
                      )}
                    </div>
                  </div>

                  <h1 className="mt-5 font-heading text-2xl font-bold leading-tight text-ink sm:text-4xl">
                    {blog.title}
                  </h1>

                  <FallbackImage
                    src={blog.thumbnailUrl}
                    alt={blog.title}
                    className="mt-6 aspect-[16/9] w-full rounded-2xl object-cover"
                    draggable={false}
                    fallback={
                      <div className="mt-6 grid aspect-[16/6] w-full place-items-center rounded-2xl bg-surface text-subtle">
                        <ImageOff className="size-8" />
                      </div>
                    }
                  />

                  <div className="mt-6 whitespace-pre-line break-words text-base leading-relaxed text-body">
                    {blog.content}
                  </div>
                </article>

                {isPublished && <CommentSection blogId={blog.id} />}
              </>
            )}
          </div>

          {isPublished && (
            <aside className="lg:sticky lg:top-24">
              <RelatedBlogs blogId={blog.id} />
            </aside>
          )}
        </div>
      </main>

      <AppFooter />
    </div>
  );
}

function NotFound() {
  return (
    <div className="rounded-3xl border border-border bg-card p-8 text-center shadow-sm">
      <h1 className="font-heading text-xl font-bold text-ink">Không tìm thấy bài viết</h1>
      <p className="mt-2 text-sm text-subtle">
        Bài viết không tồn tại, chưa được đăng, đã bị gỡ hoặc bạn không có quyền xem.
      </p>
      <Link
        to="/blog"
        className="mt-4 inline-block rounded-full bg-brand px-5 py-2 text-sm font-medium text-brand-foreground transition hover:opacity-90"
      >
        Về trang Cộng đồng
      </Link>
    </div>
  );
}

function ArticleSkeleton() {
  return (
    <div
      aria-hidden
      className="animate-pulse rounded-3xl border border-border bg-card p-5 shadow-sm sm:p-8"
    >
      <div className="flex items-center gap-3">
        <div className="size-11 rounded-full bg-surface" />
        <div className="h-4 w-40 rounded bg-surface" />
        <div className="ml-auto space-y-1.5">
          <div className="ml-auto h-5 w-20 rounded-full bg-surface" />
          <div className="ml-auto h-4 w-16 rounded bg-surface" />
        </div>
      </div>
      <div className="mt-5 h-8 w-4/5 rounded bg-surface" />
      <div className="mt-6 aspect-[16/9] w-full rounded-2xl bg-surface" />
      <div className="mt-6 space-y-3">
        <div className="h-4 w-full rounded bg-surface" />
        <div className="h-4 w-full rounded bg-surface" />
        <div className="h-4 w-2/3 rounded bg-surface" />
      </div>
    </div>
  );
}
