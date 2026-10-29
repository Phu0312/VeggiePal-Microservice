import { Broccoli, MapPinned, Navigation, Star, Store } from "lucide-react";

import GlassBanner, { GlassChip, GlassPanel } from "@/shared/components/GlassBanner";

// Cùng bố cục kính mờ với HeroBanner của meal-planner.
export default function MapBanner() {
  return (
    <GlassBanner>
      <div className="flex flex-col items-center gap-8 lg:flex-row lg:items-center lg:justify-between lg:gap-12">
        <div className="flex max-w-2xl flex-col items-center gap-4 text-center lg:items-start lg:text-left">
          <GlassChip icon={Navigation}>Đồng hành cùng bạn</GlassChip>

          <h1 className="text-3xl font-extrabold leading-tight text-ink sm:text-4xl">
            Khám phá các quán ăn "ngon lành" quanh bạn cùng{" "}
            <span className="text-gradient-brand">VeggiePal</span> nhé.
          </h1>

          <p className="max-w-md text-sm leading-relaxed text-body sm:text-base">
            Tìm quán chay gần bạn, xem đánh giá và chọn nơi phù hợp nhất cho
            bữa ăn xanh hôm nay!
          </p>
        </div>

        <GlassPanel className="flex w-full max-w-sm flex-col gap-3">
          <div className="flex items-center gap-3">
            <span className="grid size-14 shrink-0 place-items-center rounded-2xl bg-gradient-to-br from-brand to-brand-2 text-white shadow-md">
              <MapPinned className="size-8" strokeWidth={1.6} />
            </span>
            <div className="min-w-0">
              <p className="font-heading text-base font-bold text-ink">Bản đồ quán chay</p>
              <p className="text-xs text-subtle">Quán xanh quanh vị trí của bạn</p>
            </div>
          </div>
          <ul className="flex flex-wrap gap-2 text-xs font-medium text-body">
            <li className="flex items-center gap-1.5 rounded-full bg-brand-soft px-3 py-1.5">
              <Store className="size-3.5 text-brand" />
              Quán chay
            </li>
            <li className="flex items-center gap-1.5 rounded-full bg-brand-soft px-3 py-1.5">
              <Star className="size-3.5 text-brand" />
              Đánh giá
            </li>
            <li className="flex items-center gap-1.5 rounded-full bg-brand-soft px-3 py-1.5">
              <Broccoli className="size-3.5 text-brand" />
              VeggiePal
            </li>
          </ul>
        </GlassPanel>
      </div>
    </GlassBanner>
  );
}
