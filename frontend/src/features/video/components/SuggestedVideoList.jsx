import { useMemo } from "react";
import { Link } from "react-router-dom";
import { PlaySquare } from "lucide-react";

import { formatCompactNumber, formatTimeAgo } from "@/features/blog/utils/blogFormat";
import { useVideoFeed } from "@/features/video/hooks/useVideos";
import FallbackImage from "@/shared/components/FallbackImage";
import { usePublicUsers } from "@/shared/hooks/usePublicUsers";

const TARGET_COUNT = 5;

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
  const needMore = !hasCategory || (catDone && filteredCat.length < TARGET_COUNT);

  // Chỉ gọi nguồn chung khi không có chuyên mục HOẶC khi nguồn cùng chuyên mục chưa đủ 5 video
  const allQuery = useVideoFeed({
    categoryId: undefined,
    size: 8,
    enabled: needMore,
  });

  const allVideos = allQuery.videos;
  const allDone = !needMore || Boolean(allQuery.data) || allQuery.isError;

  // Ghép danh sách: ưu tiên cùng chuyên mục, bù thêm từ nguồn chung cho đủ 5 video
  const suggestedList = useMemo(() => {
    const list = filteredCat.slice(0, TARGET_COUNT);
    if (list.length < TARGET_COUNT) {
      const existingIds = new Set([Number(currentVideoId), ...list.map((v) => v.id)]);
      const additional = (allVideos ?? []).filter((v) => !existingIds.has(v.id));
      return [...list, ...additional.slice(0, TARGET_COUNT - list.length)];
    }
    return list;
  }, [filteredCat, allVideos, currentVideoId]);

  const { data: authors } = usePublicUsers(suggestedList.map((v) => v.authorId));

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
      ) : suggestedList.length > 0 ? (
        <div className="flex flex-col gap-3.5">
          {suggestedList.map((v) => {
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
        </div>
      ) : (
        <p className="text-sm text-subtle">Chưa có video khác.</p>
      )}
    </section>
  );
}
