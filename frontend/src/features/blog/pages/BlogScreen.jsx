import { useState } from "react";
import { useSearchParams } from "react-router-dom";
import { Loader2 } from "lucide-react";

import { Button } from "@/components/ui/button";
import AskBroccoliCard from "@/features/blog/components/AskBroccoliCard";
import BlogFilterBar from "@/features/blog/components/BlogFilterBar";
import BlogPostCard from "@/features/blog/components/BlogPostCard";
import CommunityHero from "@/features/blog/components/CommunityHero";
import { useMyVotes } from "@/features/blog/hooks/useBlogVotes";
import { useBlogFeed } from "@/features/blog/hooks/useBlogs";
import {
  hasActiveFilters,
  parseFeedFilters,
  toFeedSearchParams,
} from "@/features/blog/utils/feedFilters";
import ChallengeCard from "@/features/community/components/ChallengeCard";
import LeaderboardCard from "@/features/community/components/LeaderboardCard";
import TrendingTopicsCard from "@/features/community/components/TrendingTopicsCard";
import AppHeader from "@/shared/components/AppHeader";
import Reveal from "@/shared/components/Reveal";
import { usePublicUsers } from "@/shared/hooks/usePublicUsers";

// Từ xl hai cột bên dính theo khi cuộn (dưới header sticky); cột cao hơn màn hình thì tự cuộn bên trong, ẩn thanh cuộn.
const stickyAsideClass =
  "flex flex-col gap-6 xl:sticky xl:top-24 xl:max-h-[calc(100dvh-7rem)] xl:overflow-y-auto xl:[scrollbar-width:none] xl:[&::-webkit-scrollbar]:hidden";

// Trang Cộng đồng (route /blog). Bài viết lấy từ API thật (GET /blogs).
// Từ xl là 3 cột: thử thách / chủ đề ở trái, bài viết ở giữa, trợ lý AI / bảng vàng ở phải.
// Dưới xl bài viết lên trước, hai cột phụ xếp xuống dưới (order-*). Trang /community cũ đã gộp vào đây.
export default function BlogScreen() {
  // Bộ lọc nằm trên URL (?q=&sort=&category=) để quay lại từ trang chi tiết vẫn giữ nguyên.
  const [searchParams, setSearchParams] = useSearchParams();
  const filters = parseFeedFilters(searchParams);
  // Tăng khi xóa bộ lọc để remount thanh lọc, xóa luôn chữ đang gõ trong ô tìm kiếm.
  const [filterBarKey, setFilterBarKey] = useState(0);

  const updateFilters = (patch) =>
    setSearchParams(
      (prev) => toFeedSearchParams({ ...parseFeedFilters(prev), ...patch }),
      { replace: true }
    );

  const clearFilters = () => {
    setSearchParams({}, { replace: true });
    setFilterBarKey((k) => k + 1);
  };

  const {
    posts,
    isPending,
    isError,
    error,
    hasNextPage,
    fetchNextPage,
    isFetchingNextPage,
  } = useBlogFeed({ ...filters, size: 10 });

  // BE chỉ trả authorId -> gom id của mọi bài đang hiển thị rồi lấy tên + avatar một lượt.
  const { data: authors } = usePublicUsers(posts.map((p) => p.authorId));
  // Phủ vote của tôi lên feed (chỉ gọi khi đã đăng nhập).
  const { data: myVotes } = useMyVotes(posts.map((p) => p.id));

  return (
    <div className="min-h-dvh">
      <AppHeader />

      <main className="mx-auto flex w-full max-w-[1280px] flex-col gap-6 px-6 py-6">
        <Reveal>
          <CommunityHero />
        </Reveal>

        <div className="grid grid-cols-1 items-start gap-6 xl:grid-cols-[280px_minmax(0,1fr)_300px]">
          <aside className={`order-2 xl:order-1 ${stickyAsideClass}`}>
            <ChallengeCard />
            <TrendingTopicsCard />
          </aside>

          <div className="order-1 flex min-w-0 flex-col gap-6 xl:order-2">
            <BlogFilterBar key={filterBarKey} filters={filters} onChange={updateFilters} />

            {isError ? (
              <p className="rounded-xl bg-destructive/10 px-3 py-2 text-sm text-destructive">
                {error.message}
              </p>
            ) : isPending ? (
              <>
                <PostSkeleton />
                <PostSkeleton />
              </>
            ) : posts.length === 0 ? (
              <div className="rounded-3xl border border-border bg-card p-6 text-sm text-subtle">
                {hasActiveFilters(filters) ? (
                  <>
                    <p>Không tìm thấy bài viết phù hợp với bộ lọc hiện tại.</p>
                    <Button
                      type="button"
                      variant="outline"
                      size="sm"
                      className="mt-3"
                      onClick={clearFilters}
                    >
                      Xóa bộ lọc
                    </Button>
                  </>
                ) : (
                  <p>Chưa có bài viết nào được đăng.</p>
                )}
              </div>
            ) : (
              <>
                {posts.map((post) => (
                  <Reveal key={post.id}>
                    <BlogPostCard
                      post={post}
                      author={authors?.get(post.authorId)}
                      myVote={myVotes?.get(post.id)}
                    />
                  </Reveal>
                ))}

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
                      "Xem thêm bài viết"
                    )}
                  </Button>
                )}
              </>
            )}
          </div>

          <aside className={`order-3 ${stickyAsideClass}`}>
            <AskBroccoliCard />
            <LeaderboardCard />
          </aside>
        </div>
      </main>

    </div>
  );
}

function PostSkeleton() {
  return (
    <div
      aria-hidden
      className="animate-pulse rounded-3xl border border-border bg-card p-5 shadow-sm sm:p-6"
    >
      <div className="flex items-center gap-3">
        <div className="size-11 rounded-full bg-surface" />
        <div className="space-y-2">
          <div className="h-3 w-32 rounded bg-surface" />
          <div className="h-3 w-20 rounded bg-surface" />
        </div>
      </div>
      <div className="mt-4 h-6 w-4/5 rounded bg-surface" />
      <div className="mt-4 aspect-[16/10] w-full rounded-2xl bg-surface" />
    </div>
  );
}
