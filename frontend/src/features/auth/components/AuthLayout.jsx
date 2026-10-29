import { Apple, Carrot, Leaf, Salad, Sprout, Wheat } from "lucide-react";

import ThemeToggle from "@/shared/components/ThemeToggle";
import { cn } from "@/lib/utils";

// Icon lucide mờ rải trên nền, thay cho ảnh nền cũ.
const BACKDROP_ICONS = [
  { Icon: Leaf, className: "left-[6%] top-[10%] size-24 rotate-[-18deg]" },
  { Icon: Salad, className: "right-[8%] top-[14%] size-36 rotate-[10deg]" },
  { Icon: Carrot, className: "left-[10%] bottom-[12%] size-32 rotate-[22deg]" },
  { Icon: Wheat, className: "right-[14%] bottom-[10%] size-28 rotate-[-12deg]" },
  { Icon: Sprout, className: "left-[44%] top-[4%] size-20 rotate-[8deg]" },
  { Icon: Apple, className: "right-[40%] bottom-[4%] size-20 rotate-[-20deg]" },
];

export default function AuthLayout({ className, children }) {
  return (
    <div className={cn("relative flex min-h-dvh items-center justify-center overflow-hidden", className)}>
      <div aria-hidden className="absolute inset-0 -z-10 bg-gradient-to-br from-brand-soft via-background to-brand-2/30 dark:from-[#0d2410] dark:via-background dark:to-[#10230f]">
        <div className="absolute -left-24 -top-24 size-96 rounded-full bg-brand-2/40 blur-3xl dark:bg-brand-2/15" />
        <div className="absolute -bottom-32 -right-24 size-[28rem] rounded-full bg-brand/25 blur-3xl dark:bg-brand/20" />
        {BACKDROP_ICONS.map(({ Icon, className: iconClass }) => (
          <Icon
            key={iconClass}
            strokeWidth={1.1}
            className={cn("absolute hidden text-brand/15 md:block dark:text-brand/20", iconClass)}
          />
        ))}
      </div>

      <ThemeToggle className="absolute right-4 top-4 z-10 bg-white/70 hover:bg-white sm:right-6 sm:top-6 dark:bg-black/30 dark:hover:bg-black/50" />

      {children}
    </div>
  );
}
