import { lazy, Suspense, useEffect, useMemo, useState } from "react";
import { Loader2 } from "lucide-react";
import { toast } from "sonner";

import AppFooter from "@/shared/components/AppFooter";
import AppHeader from "@/shared/components/AppHeader";
import MapBanner from "@/features/restaurant-map/components/MapBanner";
import MapFrame from "@/features/restaurant-map/components/MapFrame";
import MapSearchBar from "@/features/restaurant-map/components/MapSearchBar";
import RestaurantList from "@/features/restaurant-map/components/RestaurantList";
import { useNearbyRestaurants } from "@/features/restaurant-map/hooks/useNearbyRestaurants";
import { useUserLocation } from "@/features/restaurant-map/hooks/useUserLocation";
import { DEFAULT_RADIUS_KM } from "@/features/restaurant-map/utils/mapConfig";
import {
  SORT_NEAREST,
  filterRestaurants,
  sortRestaurants,
} from "@/features/restaurant-map/utils/restaurantFormat";
import Reveal from "@/shared/components/Reveal";

// Mapbox nặng nên chỉ tải khi vào trang này, không làm phình bundle của các trang khác.
const MapPanel = lazy(
  () => import("@/features/restaurant-map/components/MapPanel"),
);

const LOCATION_FAILED_MESSAGES = {
  denied:
    "Bạn chưa cho phép truy cập vị trí. Đang dùng vị trí mặc định (Quận 1, TP.HCM).",
  unavailable:
    "Không xác định được vị trí của bạn. Đang dùng vị trí mặc định (Quận 1, TP.HCM).",
  unsupported:
    "Trình duyệt không hỗ trợ định vị. Đang dùng vị trí mặc định (Quận 1, TP.HCM).",
};

// Trang Bản đồ quán chay (location-service: GET /restaurants/nearby).
// Màn hình giữ toàn bộ state; danh sách và bản đồ cùng đọc một mảng quán đã lọc.
export default function RestaurantMapScreen() {
  const { location, isDefaultLocation, status, request, resetToDefault } =
    useUserLocation();
  const [radiusKm, setRadiusKm] = useState(DEFAULT_RADIUS_KM);
  const [keyword, setKeyword] = useState("");
  const [sort, setSort] = useState(SORT_NEAREST);
  const [selectedId, setSelectedId] = useState(null);

  const { restaurants, isLoading, isError, error, refetch, isFetching } =
    useNearbyRestaurants({
      lat: location.lat,
      lng: location.lng,
      radiusKm,
    });

  // BE chưa tìm theo tên nên lọc từ khóa và sắp xếp lại ngay trên danh sách đã tải.
  const visible = useMemo(
    () => sortRestaurants(filterRestaurants(restaurants, keyword), sort),
    [restaurants, keyword, sort],
  );

  // Mỗi lần kết quả hiển thị đổi (vị trí, bán kính, từ khóa, cách xếp) danh sách quay về 10 quán đầu.
  const resetKey = `${location.lat},${location.lng},${radiusKm},${keyword},${sort}`;

  useEffect(() => {
    const message = LOCATION_FAILED_MESSAGES[status];
    if (message) toast.info(message, { id: "restaurant-map-location" });
  }, [status]);

  return (
    <div className="min-h-dvh">
      <AppHeader />

      <main className="mx-auto flex w-full max-w-[1280px] flex-col gap-6 px-6 py-6">
        <MapBanner />
        <Reveal>
          <MapSearchBar keyword={keyword} onKeywordChange={setKeyword} />
        </Reveal>

        {/* RestaurantList tự có <Reveal> cho từng quán. Không bọc MapPanel vì nó dùng sticky. */}
        <section className="grid grid-cols-1 gap-6 lg:grid-cols-2">
          <RestaurantList
            restaurants={visible}
            isLoading={isLoading}
            isRefreshing={isFetching && !isLoading}
            errorMessage={isError ? error.message : null}
            onRetry={refetch}
            resetKey={resetKey}
            radiusKm={radiusKm}
            onRadiusChange={setRadiusKm}
            sort={sort}
            onSortChange={setSort}
            selectedId={selectedId}
            onSelect={setSelectedId}
            isDefaultLocation={isDefaultLocation}
            onResetLocation={resetToDefault}
            hasKeyword={keyword.trim() !== ""}
          />

          <Suspense
            fallback={
              <MapFrame>
                <div className="absolute inset-0 grid place-items-center">
                  <Loader2 className="size-6 animate-spin text-brand" />
                </div>
              </MapFrame>
            }
          >
            <MapPanel
              restaurants={visible}
              location={location}
              isDefaultLocation={isDefaultLocation}
              radiusKm={radiusKm}
              selectedId={selectedId}
              onSelect={setSelectedId}
              onLocate={request}
              locating={status === "loading"}
            />
          </Suspense>
        </section>
      </main>

      <AppFooter />
    </div>
  );
}
