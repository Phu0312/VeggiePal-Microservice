import { Link } from "react-router-dom";
import {
  CakeSlice,
  ChefHat,
  Coffee,
  Cookie,
  CookingPot,
  LayoutGrid,
  Leaf,
  Loader2,
  PlaySquare,
  Salad,
  Sandwich,
  Soup,
  Sprout,
  Utensils,
  Video as VideoIcon,
} from "lucide-react";

import { Button } from "@/components/ui/button";
import { formatCompactNumber, formatTimeAgo, getInitials } from "@/features/blog/utils/blogFormat";
import FallbackImage from "@/shared/components/FallbackImage";
import Reveal from "@/shared/components/Reveal";
import SelectField from "@/shared/components/SelectField";

function getCategoryIcon(name) {
  if (!name) return LayoutGrid;
  const n = name.toLowerCase().trim();

  if (n.includes("tất cả")) return LayoutGrid;
  if (n.includes("chính")) return Utensils;
  if (n.includes("sáng")) return Sandwich;
  if (n.includes("salad")) return Salad;
  if (n.includes("nước") || n.includes("canh") || n.includes("súp") || n.includes("soup") || n.includes("phở")) return Soup;
  if (n.includes("healthy") || n.includes("sức khỏe")) return Sprout;
  if (n.includes("việt nam") || n.includes("truyền thống")) return CookingPot;
  if (n.includes("tráng miệng") || n.includes("bánh")) return CakeSlice;
  if (n.includes("uống") || n.includes("nước ép") || n.includes("trà") || n.includes("cà phê")) return Coffee;
  if (n.includes("vặt")) return Cookie;
  if (n.includes("chay")) return Leaf;

  return ChefHat;
}

export default function TrendingVideoGrid({
  videos = [],
  authors,
  isPending,
  isError,
  error,
  hasNextPage,
  fetchNextPage,
  isFetchingNextPage,
  onClearFilter,
  hasFilter,
  categories = [],
  activeCategoryId,
  onCategoryChange,
}) {
  const categoryOptions = [
    { value: undefined, label: "Tất cả danh mục", icon: LayoutGrid },
    ...categories.map((cat) => ({
      value: cat.id,
      label: cat.name,
      icon: getCategoryIcon(cat.name),
    })),
  ];

  return (
    <section className="flex flex-col gap-5">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h2 className="text-xl font-bold text-ink sm:text-2xl">
          Video nấu ăn mới nhất
        </h2>
        {categories.length > 0 && (
          <SelectField
            aria-label="Lọc theo danh mục"
            options={categoryOptions}
            value={activeCategoryId ?? undefined}
            onValueChange={onCategoryChange}
            align="end"
            active={Boolean(activeCategoryId)}
          />
        )}
      </div>

      {isError ? (
        <p className="rounded-xl bg-destructive/10 px-4 py-3 text-sm text-destructive">
          {error?.message ?? "Không thể tải danh sách video"}
        </p>
      ) : isPending ? (
        <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3">
          {[0, 1, 2, 3, 4, 5].map((i) => (
            <VideoCardSkeleton key={i} />
          ))}
        </div>
      ) : videos.length === 0 ? (
        <div className="rounded-3xl border border-border bg-card p-8 text-center text-subtle">
          <PlaySquare className="mx-auto size-12 text-subtle/50" />
          <h3 className="mt-3 font-heading text-lg font-bold text-ink">
            {hasFilter
              ? "Không có video nào trong danh mục này"
              : "Chưa có video nào được đăng"}
          </h3>
          <p className="mt-1 text-sm">
            {hasFilter
              ? "Hãy thử chọn danh mục khác hoặc xóa bộ lọc."
              : "Hãy là người đầu tiên chia sẻ công thức nấu ăn bằng video nhé!"}
          </p>
          {hasFilter && onClearFilter && (
            <Button
              type="button"
              variant="outline"
              size="sm"
              className="mt-4"
              onClick={onClearFilter}
            >
              Xem tất cả video
            </Button>
          )}
        </div>
      ) : (
        <>
          <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3">
            {videos.map((video, index) => {
              const author = authors?.get(video.authorId);
              const authorName = author?.fullName ?? "Thành viên VeggiePal";

              return (
                <Reveal key={video.id} delay={index * 60}>
                  <Link
                    to={`/videos/${video.id}`}
                    className="group flex flex-col overflow-hidden rounded-2xl border border-border bg-card shadow-[0_1px_2px_rgba(16,24,40,0.04)] transition hover:shadow-md"
                  >
                    <div className="relative h-48 w-full overflow-hidden bg-surface">
                      <FallbackImage
                        src={video.thumbnailUrl}
                        alt={video.title}
                        className="size-full object-cover transition duration-300 group-hover:scale-105"
                        draggable={false}
                        fallback={
                          <div className="grid size-full place-items-center bg-gradient-to-br from-brand-soft to-surface text-brand">
                            <VideoIcon className="size-10 opacity-70" />
                          </div>
                        }
                      />
                      <span className="absolute left-3 top-3 rounded-full bg-black/60 px-2.5 py-1 text-[11px] font-semibold text-white backdrop-blur-sm">
                        {video.sourceType === "YOUTUBE" ? "YouTube" : "Video"}
                      </span>
                      {video.categoryName && (
                        <span className="absolute right-3 top-3 rounded-full bg-black/60 px-2.5 py-1 text-[11px] font-semibold text-white backdrop-blur-sm">
                          {video.categoryName}
                        </span>
                      )}
                    </div>

                    <div className="flex flex-1 gap-3 p-4">
                      <FallbackImage
                        src={author?.avatarUrl}
                        alt={authorName}
                        className="size-9 shrink-0 rounded-full object-cover"
                        draggable={false}
                        fallback={
                          <span className="grid size-9 shrink-0 place-items-center rounded-full bg-brand-soft text-xs font-bold text-brand">
                            {getInitials(authorName)}
                          </span>
                        }
                      />
                      <div className="min-w-0 flex-1">
                        <h3 className="line-clamp-2 text-sm font-bold leading-snug text-ink transition group-hover:text-brand">
                          {video.title}
                        </h3>
                        <p className="mt-1 truncate text-xs text-subtle">
                          {authorName}
                        </p>
                        <p className="mt-0.5 text-xs text-subtle">
                          {formatCompactNumber(video.viewCount)} lượt xem •{" "}
                          {formatTimeAgo(video.publishedAt ?? video.createdAt)}
                        </p>
                      </div>
                    </div>
                  </Link>
                </Reveal>
              );
            })}
          </div>

          {hasNextPage && (
            <div className="mt-4 flex justify-center">
              <Button
                type="button"
                variant="outline"
                disabled={isFetchingNextPage}
                onClick={() => fetchNextPage()}
              >
                {isFetchingNextPage ? (
                  <>
                    <Loader2 className="size-4 animate-spin" />
                    Đang tải thêm...
                  </>
                ) : (
                  "Xem thêm video"
                )}
              </Button>
            </div>
          )}
        </>
      )}
    </section>
  );
}

function VideoCardSkeleton() {
  return (
    <div
      aria-hidden
      className="flex animate-pulse flex-col overflow-hidden rounded-2xl border border-border bg-card"
    >
      <div className="h-48 w-full bg-surface" />
      <div className="flex gap-3 p-4">
        <div className="size-9 shrink-0 rounded-full bg-surface" />
        <div className="flex-1 space-y-2 py-1">
          <div className="h-4 w-4/5 rounded bg-surface" />
          <div className="h-3 w-1/2 rounded bg-surface" />
          <div className="h-3 w-1/3 rounded bg-surface" />
        </div>
      </div>
    </div>
  );
}
