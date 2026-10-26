import iconBanner from "@/assets/img/icon_banner.png";
import tag from "@/assets/img/tag.png"

export default function HeroBanner({ userName }) {
  return (
    <section className="relative overflow-hidden rounded-[32px] px-2 py-4 sm:px-4">
      <div
        aria-hidden
        className="pointer-events-none absolute -left-20 -top-24 h-72 w-72 rounded-full bg-brand-2/25 blur-3xl dark:bg-brand-2/30"
      />
      <div
        aria-hidden
        className="pointer-events-none absolute -right-16 bottom-0 h-80 w-80 rounded-full bg-brand-2/30 blur-3xl dark:bg-brand-2/35"
      />

      <div className="relative flex flex-col items-center gap-10 lg:flex-row lg:items-center lg:justify-center lg:gap-16">
        <div className="flex max-w-2xl flex-col items-center gap-4 text-center lg:items-start lg:text-left">
          <img
            src={tag}
            alt="Đồng hành cùng bạn"
            className="h-16 w-auto select-none sm:h-20"
            draggable={false}
          />

          <h1 className="text-3xl font-bold leading-tight text-ink sm:text-4xl">
            Chào {userName}! Hôm nay,{" "}
            <span className="text-brand">Bé Bông Cải</span> đã sẵn sàng
            lên thực đơn cho bạn nè!
          </h1>

          <p className="max-w-md text-sm leading-relaxed text-subtle sm:text-base">
            Chỉ cần vài thao tác đơn giản, mình sẽ giúp bạn lên thực đơn
            cân bằng và phù hợp với mục tiêu dinh dưỡng của bạn!
          </p>

          <div className="mt-1 flex flex-wrap items-center justify-center gap-3 lg:justify-start">
            <a
              href="#today-meals"
              className="flex items-center gap-2 rounded-full bg-brand px-5 py-2.5 text-sm font-semibold text-brand-foreground shadow-sm transition hover:bg-brand/90"
            >
              Khám Phá Thực Đơn Ngay
            </a>
            <a
              href="#macro-balance"
              className="flex items-center gap-2 rounded-full bg-brand-soft px-5 py-2.5 text-sm font-semibold text-brand transition hover:brightness-95"
            >
              Xem Phân Bổ Dinh Dưỡng
            </a>
          </div>
        </div>

        <img
          src={iconBanner}
          alt="Bé Bông Cải chào đón bạn"
          className="h-56 w-auto shrink-0 select-none drop-shadow-sm sm:h-72 lg:h-80"
          draggable={false}
        />
      </div>
    </section>
  );
}
