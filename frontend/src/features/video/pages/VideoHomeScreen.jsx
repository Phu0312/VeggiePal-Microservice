import { useSearchParams } from "react-router-dom";
import { Clapperboard, PlayCircle, Plus, Video } from "lucide-react";

import { Button } from "@/components/ui/button";
import { useCategories } from "@/features/blog/hooks/useCategories";
import { flattenCategories } from "@/features/blog/utils/feedFilters";
import TrendingVideoGrid from "@/features/video/components/TrendingVideoGrid";
import { useVideoFeed } from "@/features/video/hooks/useVideos";
import AppHeader from "@/shared/components/AppHeader";
import GlassBanner, { GlassChip, GlassPanel } from "@/shared/components/GlassBanner";
import { useContentForm } from "@/shared/hooks/useContentForm";
import { usePublicUsers } from "@/shared/hooks/usePublicUsers";

// Trang video chính (route /videos, công khai): danh sách video đã duyệt (GET /videos),
// hỗ trợ lọc theo danh mục trên URL (?category=) và phân trang "Xem thêm".
export default function VideoHomeScreen() {
  const [searchParams, setSearchParams] = useSearchParams();
  const { openForm } = useContentForm();
  const categoryParam = searchParams.get("category");
  const activeCategoryId =
    categoryParam && /^[1-9]\d*$/.test(categoryParam)
      ? Number(categoryParam)
      : null;

  const { data: categoryTree } = useCategories({ activeOnly: true });
  const categories = flattenCategories(categoryTree);

  const {
    videos,
    isPending,
    isError,
    error,
    hasNextPage,
    fetchNextPage,
    isFetchingNextPage,
  } = useVideoFeed({ categoryId: activeCategoryId, size: 12 });

  const { data: authors } = usePublicUsers(videos.map((v) => v.authorId));

  const setCategory = (id) => {
    if (!id) {
      setSearchParams({}, { replace: true });
    } else {
      setSearchParams({ category: String(id) }, { replace: true });
    }
  };

  return (
    <div className="min-h-dvh">
      <AppHeader />

      <main className="mx-auto flex w-full max-w-[1280px] flex-col gap-6 px-6 py-6">
        {/* Banner tiêu đề & nút đăng video */}
        <GlassBanner>
          <div className="flex flex-col gap-6 lg:flex-row lg:items-center lg:justify-between lg:gap-12">
            <div className="flex max-w-2xl flex-col items-start gap-4">
              <GlassChip icon={Clapperboard}>Video ẩm thực</GlassChip>
              <h1 className="font-heading text-3xl font-extrabold leading-tight text-ink sm:text-4xl">
                Khám Phá <span className="text-gradient-brand">Video Ẩm Thực</span>
              </h1>
              <p className="max-w-md text-sm leading-relaxed text-body sm:text-base">
                Cùng học nấu các món chay ngon, thanh lành từ cộng đồng yêu bếp VeggiePal.
              </p>
              <Button
                type="button"
                variant="gradient"
                size="md"
                className="shadow-md"
                onClick={() => openForm("video")}
              >
                <Plus className="size-4" />
                Đăng video
              </Button>
            </div>

            <GlassPanel className="flex w-full max-w-sm items-center gap-4">
              <span className="relative grid size-16 shrink-0 place-items-center rounded-2xl bg-gradient-to-br from-brand to-brand-2 text-white shadow-md">
                <Video className="size-8" strokeWidth={1.6} />
                <PlayCircle className="absolute -bottom-1.5 -right-1.5 size-6 rounded-full bg-card text-brand" />
              </span>
              <div className="min-w-0">
                <p className="text-[11px] font-semibold uppercase tracking-wide text-subtle">
                  Học nấu cùng VeggiePal
                </p>
                <p className="font-heading text-base font-bold text-ink">Xem, học và nấu ngay</p>
                <p className="text-xs text-subtle">Video đã được kiểm duyệt từ cộng đồng</p>
              </div>
            </GlassPanel>
          </div>
        </GlassBanner>

        <TrendingVideoGrid
          videos={videos}
          authors={authors}
          isPending={isPending}
          isError={isError}
          error={error}
          hasNextPage={hasNextPage}
          fetchNextPage={fetchNextPage}
          isFetchingNextPage={isFetchingNextPage}
          hasFilter={activeCategoryId !== null}
          onClearFilter={() => setCategory(null)}
          categories={categories}
          activeCategoryId={activeCategoryId}
          onCategoryChange={setCategory}
        />
      </main>

    </div>
  );
}
