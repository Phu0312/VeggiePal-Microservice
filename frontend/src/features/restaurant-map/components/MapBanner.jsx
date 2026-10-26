import mapIllustration from "@/assets/img/icon_map_page_2.png";
import tag from "@/assets/img/tag.png";

// Cùng bố cục với HeroBanner của meal-planner, nhưng nằm trong container và không có gradient nền.
export default function MapBanner() {
  return (
    <section className="rounded-[28px] border border-border bg-brand-soft/40 px-6 py-6 sm:px-8">
      <div className="flex flex-col items-center gap-8 lg:flex-row lg:items-center lg:justify-center lg:gap-16">
        <div className="flex max-w-2xl flex-col items-center gap-4 text-center lg:items-start lg:text-left">
          <img
            src={tag}
            alt="Đồng hành cùng bạn"
            className="h-16 w-auto select-none sm:h-20"
            draggable={false}
          />

          <h1 className="text-3xl font-bold leading-tight text-ink sm:text-4xl">
            Khám phá các quán ăn "ngon lành" quanh bạn cùng{" "}
            <span className="text-brand">Bé Bông Cải</span> nhé.
          </h1>

          <p className="max-w-md text-sm leading-relaxed text-subtle sm:text-base">
            Tìm quán chay gần bạn, xem đánh giá và chọn nơi phù hợp nhất cho
            bữa ăn xanh hôm nay!
          </p>
        </div>

        <img
          src={mapIllustration}
          alt="Bản đồ quán chay cùng Bé Bông Cải"
          className="h-auto w-full max-w-xs shrink-0 select-none drop-shadow-sm sm:max-w-sm lg:max-w-md"
          draggable={false}
        />
      </div>
    </section>
  );
}
