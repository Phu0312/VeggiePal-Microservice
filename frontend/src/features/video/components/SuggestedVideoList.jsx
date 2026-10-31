import { useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { Loader2, PlaySquare } from "lucide-react";

import { Button } from "@/components/ui/button";
import { formatCompactNumber, formatTimeAgo } from "@/features/blog/utils/blogFormat";
import { useVideoFeed } from "@/features/video/hooks/useVideos";
import FallbackImage from "@/shared/components/FallbackImage";
import { usePublicUsers } from "@/shared/hooks/usePublicUsers";

// Hiện tối đa 5 video, mỗi lần bấm "Xem thêm" hiện thêm 5 video nữa.
const PAGE_COUNT = 5;

function SuggestedVideoSkeleton() {
  return (
    <div className="flex flex-col gap-3.5" aria-hidden="true">
      {Array.from({ length: 4 }).map((_, i) => (
        <div key={i} className="flex gap-3 p-1.5">
          <div className="h-20 w-32 shrink-0 animate-pulse rounded-xl bg-surface" />
          <div className="flex min-w-0 flex-1 flex-col justify-center gap-2">
            <div className="h-3.5 w-full animate-pulse rounded bg-surface" />
            <div className="h-3 w-2/3 animate-pulse rounded bg-surface" />
            <div className="h-2.5 w-1/3 animate-pulse rounded bg-surface" />
          </div>
        </div>
      ))}
    </div>
  );
}

export default function SuggestedVideoList({ currentVideoId, categoryId }) {
  const hasCategory = categoryId != null;

  // Lấy các video khác đã xuất bản: ưu tiên cùng chuyên mục
  const catQuery = useVideoFeed({
    categoryId: hasCategory ? categoryId : undefined,
    size: 8,
    enabled: hasCategory,
  });

  const catVideos = catQuery.videos;
  const filteredCat = useMemo(
    () => (catVideos ?? []).filter((v) => v.id !== Number(currentVideoId)),
    [catVideos, currentVideoId],
  );

  const catDone = !hasCategory || Boolean(catQuery.data) || catQuery.isError;

  // Nguồn chung chỉ gọi sau khi nguồn cùng chuyên mục xong, dùng bù cho đủ danh sách và để "Xem thêm" tải tiếp.
  const allQuery = useVideoFeed({
    categoryId: undefined,
    size: 8,
    enabled: catDone,
  });

  const allVideos = allQuery.videos;
  const allDone = !catDone || Boolean(allQuery.data) || allQuery.isError;

  // Ghép danh sách: video cùng chuyên mục trước, rồi tới nguồn chung (bỏ trùng). Chỉ nối thêm ở cuối nên thứ tự đang hiện không bị đổi.
  const suggestedList = useMemo(() => {
    const seen = new Set([Number(currentVideoId), ...filteredCat.map((v) => v.id)]);
    const additional = (allVideos ?? []).filter((v) => !seen.has(v.id));
    return [...filteredCat, ...additional];
  }, [filteredCat, allVideos, currentVideoId]);

  const [visibleCount, setVisibleCount] = useState(PAGE_COUNT);
  const visibleList = suggestedList.slice(0, visibleCount);
  const hasMore = suggestedList.length > visibleCount || Boolean(allQuery.hasNextPage);

  const showMore = () => {
    const next = visibleCount + PAGE_COUNT;
    setVisibleCount(next);
    // Danh sách đã tải chưa đủ cho lần hiện tiếp theo thì tải thêm một trang từ nguồn chung.
    if (suggestedList.length < next && allQuery.hasNextPage && !allQuery.isFetchingNextPage) {
      allQuery.fetchNextPage();
    }
  };

  const { data: authors } = usePublicUsers(visibleList.map((v) => v.authorId));

  const isLoading = !catDone || !allDone;

  return (
    <section className="flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <h2 className="text-sm font-bold text-ink sm:text-base">
          Video gợi ý tiếp theo
        </h2>
      </div>

      {isLoading ? (
        <SuggestedVideoSkeleton />
      ) : visibleList.length > 0 ? (
        <div className="flex flex-col gap-3.5">
          {visibleList.map((v) => {
            const author = authors?.get(v.authorId);
            return (
              <Link
                key={v.id}
                to={`/videos/${v.id}`}
                className="group flex gap-3 rounded-2xl p-1.5 transition hover:bg-surface"
              >
                <div className="relative h-20 w-32 shrink-0 overflow-hidden rounded-xl bg-surface">
                  <FallbackImage
                    src={v.thumbnailUrl}
                    alt={v.title}
                    className="size-full object-cover transition duration-300 group-hover:scale-105"
                    fallback={
                      <span className="grid size-full place-items-center bg-surface text-subtle">
                        <PlaySquare className="size-6 text-subtle" />
                      </span>
                    }
                  />
                  <span className="absolute bottom-1 right-1 rounded bg-black/70 px-1 py-0.5 text-[9px] font-medium text-white">
                    {v.sourceType === "YOUTUBE" ? "YouTube" : "Video"}
                  </span>
                </div>

                <div className="flex min-w-0 flex-1 flex-col justify-center gap-1">
                  <h3 className="line-clamp-2 text-xs font-bold leading-snug text-ink transition group-hover:text-brand">
                    {v.title}
                  </h3>
                  <div className="flex items-center gap-2 text-[11px]">
                    {author?.fullName && (
                      <span className="truncate text-subtle">{author.fullName}</span>
                    )}
                    {v.categoryName && (
                      <span className="shrink-0 text-brand">{v.categoryName}</span>
                    )}
                  </div>
                  <p className="text-[11px] text-subtle">
                    {formatCompactNumber(v.viewCount)} lượt xem •{" "}
                    {formatTimeAgo(v.publishedAt ?? v.createdAt)}
                  </p>
                </div>
              </Link>
            );
          })}

          {hasMore && (
            <Button
              type="button"
              variant="outline"
              size="sm"
              className="self-center"
              disabled={allQuery.isFetchingNextPage}
              onClick={showMore}
            >
              {allQuery.isFetchingNextPage ? (
                <>
                  <Loader2 className="size-4 animate-spin" />
                  Đang tải...
                </>
              ) : (
                "Xem thêm"
              )}
            </Button>
          )}
        </div>
      ) : (
        <p className="text-sm text-subtle">Chưa có video khác.</p>
      )}
    </section>
  );
}
