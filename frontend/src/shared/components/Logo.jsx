import { useId } from "react";

import { cn } from "@/lib/utils";

/**
 * Biểu tượng VeggiePal: hai chiếc lá nảy mầm trên chiếc tô — vẽ lại bằng SVG theo logo của app mobile
 * (assets/images/icon_app.png) nên không cần file ảnh và co giãn không vỡ nét.
 * Kích thước điều khiển qua className (vd. "size-10").
 */
export function LogoMark({ className, ...props }) {
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
          <stop offset="0.45" stopColor="#2e7d32" />
          <stop offset="1" stopColor="#6aa84f" />
        </linearGradient>
        <linearGradient id={leafLeft} x1="0" y1="0" x2="1" y2="1">
          <stop offset="0.55" stopColor="#2e7d32" />
          <stop offset="1" stopColor="#7cb342" />
        </linearGradient>
        <linearGradient id={leafRight} x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#8bb83a" />
          <stop offset="1" stopColor="#e0c92e" />
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
      <ellipse cx="50" cy="97" rx="24" ry="2.6" fill="#2e7d32" fillOpacity="0.18" />
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
      <LogoMark className={cn("size-10", markClassName)} />
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
