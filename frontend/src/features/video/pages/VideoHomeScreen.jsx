import { Link, useSearchParams } from "react-router-dom";
import { Plus } from "lucide-react";

import { buttonVariants } from "@/components/ui/variants/button-variants";
import { useCategories } from "@/features/blog/hooks/useCategories";
import { flattenCategories } from "@/features/blog/utils/feedFilters";
import TrendingVideoGrid from "@/features/video/components/TrendingVideoGrid";
import VideoChannelBar from "@/features/video/components/VideoChannelBar";
import { useVideoFeed } from "@/features/video/hooks/useVideos";
import AppFooter from "@/shared/components/AppFooter";
import AppHeader from "@/shared/components/AppHeader";
import Reveal from "@/shared/components/Reveal";
import { usePublicUsers } from "@/shared/hooks/usePublicUsers";

// Trang video chính (route /videos, công khai): danh sách video đã duyệt (GET /videos),
// hỗ trợ lọc theo danh mục trên URL (?category=) và phân trang "Xem thêm".
export default function VideoHomeScreen() {
  const [searchParams, setSearchParams] = useSearchParams();
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
        {/* Tiêu đề & Nút đăng video */}
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div>
            <h1 className="font-heading text-3xl font-bold text-ink">
              Khám Phá Video Ẩm Thực
            </h1>
            <p className="mt-1 text-sm text-subtle">
              Cùng học nấu các món chay ngon, thanh lành từ cộng đồng yêu bếp VeggiePal.
            </p>
          </div>
          <Link
            to="/videos/new"
            className={buttonVariants({ variant: "default", size: "md" })}
          >
            <Plus className="size-4" />
            Đăng video
          </Link>
        </div>

        <Reveal>
          <VideoChannelBar />
        </Reveal>

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

      <AppFooter />
    </div>
  );
}
