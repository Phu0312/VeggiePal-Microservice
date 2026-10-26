import { useEffect, useState } from "react";
import { Loader2, SearchX } from "lucide-react";

import { Button } from "@/components/ui/button";
import mascotWave from "@/assets/img/icon_map_page_1.png";
import RestaurantCard from "@/features/restaurant-map/components/RestaurantCard";
import {
  MAX_RADIUS_KM,
  RADIUS_OPTIONS_KM,
} from "@/features/restaurant-map/utils/mapConfig";
import {
  SORT_NEAREST,
  SORT_RATING,
} from "@/features/restaurant-map/utils/restaurantFormat";
import Reveal from "@/shared/components/Reveal";
import SelectField from "@/shared/components/SelectField";
import { cn } from "@/lib/utils";

const PAGE_SIZE = 5;

const SORT_OPTIONS = [
  { value: SORT_NEAREST, label: "Gần nhất" },
  { value: SORT_RATING, label: "Đánh giá cao" },
];

const RADIUS_DROPDOWN_OPTIONS = RADIUS_OPTIONS_KM.map((km) => ({
  value: km,
  label: `${km} km`,
}));

function RestaurantSkeleton() {
  return (
    <div className="flex animate-pulse gap-4 rounded-2xl border border-border bg-card p-3 sm:p-4">
      <div className="h-28 w-28 shrink-0 rounded-xl bg-surface sm:h-32 sm:w-32" />
      <div className="flex flex-1 flex-col gap-3 pt-1">
        <div className="h-4 w-2/3 rounded-full bg-surface" />
        <div className="h-3 w-full rounded-full bg-surface" />
        <div className="h-3 w-1/3 rounded-full bg-surface" />
        <div className="mt-auto h-8 w-full rounded-full bg-surface" />
      </div>
    </div>
  );
}

function StateBox({ icon, title, description, children }) {
  return (
    <div className="flex flex-col items-center gap-3 rounded-2xl border border-border bg-card px-6 py-10 text-center">
      {icon}
      <p className="text-sm font-semibold text-ink">{title}</p>
      {description && (
        <p className="max-w-xs text-xs leading-relaxed text-subtle">
          {description}
        </p>
      )}
      {children}
    </div>
  );
}

/**
 * Danh sách quán bên trái bản đồ. Toàn bộ dữ liệu và state nằm ở RestaurantMapScreen.
 * - restaurants: quán đã lọc và sắp xếp, hiện 5 quán một lần ("Xem thêm" để mở rộng)
 * - resetKey: đổi giá trị này thì số quán đang hiện quay lại 5
 * - isRefreshing: đang tải lại (đổi bán kính) trong khi vẫn hiện kết quả cũ
 */
export default function RestaurantList({
  restaurants,
  isLoading,
  isRefreshing,
  errorMessage,
  onRetry,
  resetKey,
  radiusKm,
  onRadiusChange,
  sort,
  onSortChange,
  selectedId,
  onSelect,
  isDefaultLocation,
  onResetLocation,
  hasKeyword,
}) {
  // Số quán đang hiện gắn với resetKey: bộ lọc đổi thì tự về PAGE_SIZE, không cần effect.
  const [limitState, setLimitState] = useState({
    key: resetKey,
    limit: PAGE_SIZE,
  });
  const baseLimit = limitState.key === resetKey ? limitState.limit : PAGE_SIZE;

  // Quán được chọn từ marker có thể nằm ngoài phần đang hiện: mở rộng để thẻ của nó xuất hiện.
  const selectedIndex = restaurants.findIndex((r) => r.id === selectedId);
  const limit = Math.max(baseLimit, selectedIndex + 1);
  const shown = restaurants.slice(0, limit);

  // Chọn quán từ marker: cuộn danh sách tới thẻ. Chỉ làm ở màn rộng (2 cột), vì ở màn hẹp
  // bản đồ nằm dưới danh sách và cuộn lên sẽ kéo người dùng rời khỏi bản đồ.
  useEffect(() => {
    if (selectedId == null) return;
    if (!window.matchMedia("(min-width: 1024px)").matches) return;
    document
      .getElementById(`restaurant-card-${selectedId}`)
      ?.scrollIntoView({ block: "nearest", behavior: "smooth" });
  }, [selectedId]);

  const renderBody = () => {
    if (isLoading) {
      return (
        <div className="flex flex-col gap-4">
          <RestaurantSkeleton />
          <RestaurantSkeleton />
          <RestaurantSkeleton />
        </div>
      );
    }

    if (errorMessage) {
      return (
        <StateBox
          icon={<SearchX className="size-8 text-destructive" />}
          title="Không tải được danh sách quán"
          description={errorMessage}
        >
          <Button type="button" variant="outline" onClick={onRetry}>
            Thử lại
          </Button>
        </StateBox>
      );
    }

    if (restaurants.length === 0) {
      return (
        <StateBox
          icon={<SearchX className="size-8 text-subtle" />}
          title={
            hasKeyword
              ? "Không có quán nào khớp từ khóa"
              : `Chưa có quán chay trong bán kính ${radiusKm} km`
          }
          description={
            hasKeyword
              ? "Hãy thử từ khóa khác hoặc xóa từ khóa để xem tất cả quán."
              : "Hãy thử mở rộng bán kính tìm kiếm hoặc xem quán quanh khu vực mặc định."
          }
        >
          <div className="flex flex-wrap justify-center gap-2">
            {!hasKeyword && radiusKm < MAX_RADIUS_KM && (
              <Button
                type="button"
                variant="soft"
                onClick={() => onRadiusChange(MAX_RADIUS_KM)}
              >
                Mở rộng lên {MAX_RADIUS_KM} km
              </Button>
            )}
            {!hasKeyword && !isDefaultLocation && (
              <Button type="button" variant="outline" onClick={onResetLocation}>
                Xem quán quanh Quận 1
              </Button>
            )}
          </div>
        </StateBox>
      );
    }

    return (
      <>
        <div
          className={cn(
            "flex flex-col gap-4 transition-opacity",
            isRefreshing && "opacity-60",
          )}
        >
          {shown.map((restaurant, index) => (
            <Reveal key={restaurant.id} delay={(index % PAGE_SIZE) * 80}>
              <RestaurantCard
                restaurant={restaurant}
                selected={restaurant.id === selectedId}
                onSelect={onSelect}
              />
            </Reveal>
          ))}
        </div>

        {shown.length < restaurants.length && (
          <Button
            type="button"
            variant="outline"
            className="self-center"
            onClick={() =>
              setLimitState({ key: resetKey, limit: limit + PAGE_SIZE })
            }
          >
            Xem thêm ({restaurants.length - shown.length} quán)
          </Button>
        )}
      </>
    );
  };

  return (
    <section className="flex flex-col gap-4">
      <div className="flex items-center justify-between gap-3">
        <div className="flex min-w-0 items-center gap-2">
          <span className="grid size-15 shrink-0 place-items-center overflow-hidden rounded-full bg-brand-soft">
            <img
              src={mascotWave}
              alt=""
              className="h-15 w-15 select-none object-contain"
              draggable={false}
            />
          </span>
          <div className="min-w-0">
            <h2 className="text-lg font-bold leading-tight text-ink">
              {isLoading
                ? "Đang tìm quán chay..."
                : `${restaurants.length} Điểm Ăn Chay Tuyệt Vời`}
            </h2>
            <p className="flex items-center gap-1.5 text-xs text-subtle">
              {isRefreshing && <Loader2 className="size-3 animate-spin" />}
              <span className="truncate">
                {isDefaultLocation
                  ? "Quanh Quận 1 (vị trí mặc định)"
                  : "Quanh vị trí của bạn"}
              </span>
            </p>
          </div>
        </div>

        <div className="flex shrink-0 items-center gap-2">
          <SelectField
            aria-label="Bán kính tìm kiếm"
            options={RADIUS_DROPDOWN_OPTIONS}
            value={radiusKm}
            onValueChange={onRadiusChange}
            className="h-9 px-3 shadow-sm"
          />
          <SelectField
            aria-label="Sắp xếp"
            options={SORT_OPTIONS}
            value={sort}
            onValueChange={onSortChange}
            className="h-9 px-3 shadow-sm"
          />
        </div>
      </div>

      {renderBody()}
    </section>
  );
}
