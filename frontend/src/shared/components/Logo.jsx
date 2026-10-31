import { useId } from "react";

import { cn } from "@/lib/utils";

/**
 * Biểu tượng VeggiePal: hai chiếc lá nảy mầm trên chiếc tô — vẽ lại bằng SVG theo logo của app mobile
 * (assets/images/icon_app.png) nên không cần file ảnh và co giãn không vỡ nét.
 * Kích thước điều khiển qua className (vd. "size-10").
 * `light` đổi sang tông sáng (tô trắng, lá xanh non) để không chìm vào nền xanh đậm của màn đăng nhập.
 */
const MARK_COLORS = {
  default: { bowl: ["#2e7d32", "#6aa84f"], leafLeft: ["#2e7d32", "#7cb342"], leafRight: ["#8bb83a", "#e0c92e"], shadow: "#2e7d32" },
  light: { bowl: ["#ffffff", "#d9edc8"], leafLeft: ["#b7e07a", "#8fcf4a"], leafRight: ["#d4ea6a", "#f5e66b"], shadow: "#ffffff" },
};

export function LogoMark({ className, light = false, ...props }) {
  const colors = MARK_COLORS[light ? "light" : "default"];
  const uid = useId();
  const bowl = `${uid}-bowl`;
  const leafLeft = `${uid}-leaf-l`;
  const leafRight = `${uid}-leaf-r`;

  return (
    <svg
      viewBox="0 0 100 100"
      role="img"
      aria-label="VeggiePal"
      className={cn("shrink-0", className)}
      {...props}
    >
      <defs>
        <linearGradient id={bowl} x1="0" y1="0" x2="1" y2="1">
          <stop offset="0.45" stopColor={colors.bowl[0]} />
          <stop offset="1" stopColor={colors.bowl[1]} />
        </linearGradient>
        <linearGradient id={leafLeft} x1="0" y1="0" x2="1" y2="1">
          <stop offset="0.55" stopColor={colors.leafLeft[0]} />
          <stop offset="1" stopColor={colors.leafLeft[1]} />
        </linearGradient>
        <linearGradient id={leafRight} x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor={colors.leafRight[0]} />
          <stop offset="1" stopColor={colors.leafRight[1]} />
        </linearGradient>
      </defs>
      <path
        d="M37.5 0.5C28 4 27 22 33 31C38 38 44 42 50 44.5C52 30 49 8 37.5 0.5Z"
        fill={`url(#${leafLeft})`}
      />
      <path
        d="M62 4.5C74 9 72 24 64 33C59 39 54 42 50 45C49 28 52 12 62 4.5Z"
        fill={`url(#${leafRight})`}
      />
      <path
        fillRule="evenodd"
        fill={`url(#${bowl})`}
        d="M1.5 47H98.5A48.5 45 0 0 1 1.5 47ZM50 56A4 4 0 1 0 50 64A4 4 0 1 0 50 56Z"
      />
      <ellipse cx="50" cy="97" rx="24" ry="2.6" fill={colors.shadow} fillOpacity="0.18" />
    </svg>
  );
}

/**
 * Logo đầy đủ: biểu tượng + chữ "VeggiePal" (+ dòng slogan nếu `tagline`).
 * `light` dùng chữ trắng cho nền tối/kính màu (màn đăng nhập).
 */
export default function Logo({ className, markClassName, tagline = false, light = false }) {
  return (
    <span className={cn("inline-flex items-center gap-2", className)}>
      <LogoMark light={light} className={cn("size-10", markClassName)} />
      <span className="flex flex-col leading-none">
        <span className="font-heading text-xl font-extrabold tracking-tight">
          <span className={light ? "text-white" : "text-brand-deep"}>Veggie</span>
          <span className="text-brand-2">Pal</span>
        </span>
        {tagline && (
          <span
            className={cn(
              "mt-1 text-[9px] font-semibold uppercase tracking-[0.18em]",
              light ? "text-white/80" : "text-brand"
            )}
          >
            Healthy &amp; Vegan Nutrition
          </span>
        )}
      </span>
    </span>
  );
}
