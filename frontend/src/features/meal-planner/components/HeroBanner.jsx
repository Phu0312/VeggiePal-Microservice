import { Broccoli, CalendarCheck, HeartHandshake, PieChart } from "lucide-react";

import GlassBanner, { GlassChip, GlassPanel } from "@/shared/components/GlassBanner";

export default function HeroBanner({ userName }) {
  return (
    <GlassBanner>
      <div className="flex flex-col items-center gap-8 lg:flex-row lg:items-center lg:justify-between lg:gap-12">
        <div className="flex max-w-2xl flex-col items-center gap-4 text-center lg:items-start lg:text-left">
          <GlassChip icon={HeartHandshake}>Đồng hành cùng bạn</GlassChip>

          <h1 className="text-3xl font-extrabold leading-tight text-ink sm:text-4xl">
            Chào {userName}! Hôm nay,{" "}
            <span className="text-gradient-brand">VeggiePal</span> đã sẵn sàng
            lên thực đơn cho bạn nè!
          </h1>

          <p className="max-w-md text-sm leading-relaxed text-body sm:text-base">
            Chỉ cần vài thao tác đơn giản, mình sẽ giúp bạn lên thực đơn
            cân bằng và phù hợp với mục tiêu dinh dưỡng của bạn!
          </p>

          <div className="mt-1 flex flex-wrap items-center justify-center gap-3 lg:justify-start">
            <a
              href="#today-meals"
              className="flex items-center gap-2 rounded-full bg-gradient-to-r from-brand to-brand-2 px-5 py-2.5 text-sm font-semibold text-white shadow-md transition hover:brightness-110"
            >
              <CalendarCheck className="size-4" />
              Khám Phá Thực Đơn Ngay
            </a>
            <a
              href="#macro-balance"
              className="glass flex items-center gap-2 rounded-full px-5 py-2.5 text-sm font-semibold text-brand-deep shadow-none transition hover:bg-white/80 dark:hover:bg-white/10"
            >
              <PieChart className="size-4" />
              Xem Phân Bổ Dinh Dưỡng
            </a>
          </div>
        </div>

        <GlassPanel className="flex w-full max-w-sm items-center gap-4">
          <span className="grid size-16 shrink-0 place-items-center rounded-2xl bg-gradient-to-br from-brand to-brand-2 text-white shadow-md">
            <Broccoli className="size-9" strokeWidth={1.6} />
          </span>
          <div className="min-w-0">
            <p className="text-[11px] font-semibold uppercase tracking-wide text-subtle">
              Góc dinh dưỡng
            </p>
            <p className="font-heading text-base font-bold text-ink">VeggiePal</p>
            <p className="text-xs text-subtle">Gợi ý thực đơn cân bằng mỗi ngày</p>
          </div>
        </GlassPanel>
      </div>
    </GlassBanner>
  );
}
