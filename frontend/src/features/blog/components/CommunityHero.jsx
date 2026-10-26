import { Link } from "react-router-dom";
import { BadgeCheck, BookOpen, PenLine, ShieldCheck, Sprout } from "lucide-react";

import mascot from "@/assets/img/icon_admin_page_3.png";
import { buttonVariants } from "@/components/ui/variants/button-variants";
import { broccoliQuote, communityStats } from "@/features/blog/data/mockBlog";

const STAT_ICONS = { book: BookOpen, check: BadgeCheck, shield: ShieldCheck };

export default function CommunityHero() {
  return (
    <section className="flex flex-col gap-5 rounded-3xl border border-border bg-gradient-to-br from-brand-soft to-card p-5 shadow-sm sm:p-6 lg:flex-row lg:items-center lg:justify-between">
      <div className="min-w-0">
        <span className="inline-flex items-center gap-1.5 rounded-full border border-border bg-card/80 px-3 py-1 text-xs text-subtle">
          <Sprout className="size-3.5 text-brand" />
          Không Gian Sống Lành &amp; Kết Nối Đam Mê Thuần Chay
        </span>

        <h1 className="mt-3 font-heading text-3xl font-bold text-ink sm:text-4xl">
          Cộng Đồng Bếp Xanh <span className="text-brand">VeggiePal</span>
        </h1>
        <p className="mt-2 max-w-xl text-sm leading-relaxed text-body">
          Nơi hơn 45.000 tín đồ thuần chay cùng Bé Bông Cải sẽ chia sẻ dinh dưỡng
          WFPB, biến tấu công thức ấm lòng và lan toả lối sống không rác thải.
        </p>

        <ul className="mt-4 flex flex-wrap gap-2">
          {communityStats.map(({ id, icon, value, label }) => {
            const Icon = STAT_ICONS[icon];
            return (
              <li
                key={id}
                className="flex items-center gap-1.5 rounded-full border border-border bg-card px-3 py-1.5 text-xs text-body"
              >
                <Icon className="size-3.5 text-brand" />
                <b className="text-ink">{value}</b> {label}
              </li>
            );
          })}
        </ul>

      </div>

      <div className="flex shrink-0 flex-col gap-3 rounded-2xl border border-border bg-card px-4 py-3 shadow-sm lg:max-w-md">
        <div className="flex items-center gap-3">
          <img src={mascot} alt="Bé Bông Cải" className="size-14 shrink-0 object-contain" draggable={false} />
          <div className="min-w-0">
            <p className="text-[11px] font-semibold uppercase tracking-wide text-subtle">
              {broccoliQuote.label}
            </p>
            <p className="font-heading text-base font-bold text-ink">{broccoliQuote.quote}</p>
            <p className="text-xs text-subtle">{broccoliQuote.hint}</p>
          </div>
        </div>

        {/* /blog/new cần đăng nhập: khách bấm sẽ được đưa sang trang đăng nhập rồi quay lại. */}
        <Link to="/blog/new" className={`${buttonVariants({ variant: "default", size: "md" })} w-full`}>
          <PenLine className="size-4" />
          Viết bài chia sẻ
        </Link>
      </div>
    </section>
  );
}
