import { Apple, Carrot, Leaf, Salad, Sprout, Wheat } from "lucide-react";

import { cn } from "@/lib/utils";

// Icon lucide xếp mờ ở nửa phải banner, thay cho ảnh nền (đồ ăn / rau củ).
const BACKDROP_ICONS = [
  { Icon: Salad, className: "right-[6%] top-[8%] size-40 rotate-[-8deg] sm:size-52" },
  { Icon: Leaf, className: "right-[34%] top-[2%] size-24 rotate-[24deg]" },
  { Icon: Carrot, className: "right-[24%] bottom-[4%] size-28 rotate-[-18deg] sm:size-36" },
  { Icon: Wheat, className: "right-[2%] bottom-[6%] size-24 rotate-[12deg]" },
  { Icon: Sprout, className: "right-[46%] bottom-[10%] size-20 rotate-[-6deg]" },
  { Icon: Apple, className: "right-[18%] top-[44%] size-16 rotate-[16deg]" },
];

/**
 * Khung banner "kính trong suốt": nền gradient xanh nhạt, các icon lucide mờ ở bên phải
 * và lớp phủ trắng mờ dần về bên trái để chữ luôn đọc rõ. Nội dung đặt trong `children`
 * (thường là chữ bên trái + một <GlassPanel> bên phải).
 */
export default function GlassBanner({ className, children }) {
  return (
    <section
      className={cn(
        "relative isolate overflow-hidden rounded-[28px] border border-white/60 bg-gradient-to-br from-brand-soft via-card to-brand-2/20 p-5 shadow-[0_10px_40px_rgb(27_94_32/0.10)] dark:border-white/10 dark:from-brand-soft dark:via-card dark:to-brand/15 sm:rounded-[32px] sm:p-8",
        className
      )}
    >
      <div aria-hidden className="pointer-events-none absolute inset-0 -z-10">
        <div className="absolute -right-24 -top-24 size-80 rounded-full bg-brand-2/30 blur-3xl" />
        <div className="absolute -bottom-28 right-1/3 size-72 rounded-full bg-brand/15 blur-3xl" />
        {BACKDROP_ICONS.map(({ Icon, className: iconClass }) => (
          <Icon
            key={iconClass}
            strokeWidth={1.2}
            className={cn("absolute hidden text-brand/15 sm:block dark:text-brand/20", iconClass)}
          />
        ))}
        <div className="absolute inset-0 bg-gradient-to-r from-card/95 via-card/70 to-transparent dark:from-card/90 dark:via-card/50" />
      </div>
      {children}
    </section>
  );
}

/** Thẻ kính mờ nổi trên banner (góc phải): nền bán trong suốt + blur + viền sáng. */
export function GlassPanel({ className, children }) {
  return (
    <div className={cn("glass-strong rounded-3xl p-4 sm:p-5", className)}>{children}</div>
  );
}

/** Huy hiệu pill nhỏ phía trên tiêu đề (eyebrow). */
export function GlassChip({ icon: Icon, className, children }) {
  return (
    <span
      className={cn(
        "glass inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-xs font-semibold text-brand-deep shadow-none",
        className
      )}
    >
      {Icon && <Icon className="size-3.5 text-brand" />}
      {children}
    </span>
  );
}
