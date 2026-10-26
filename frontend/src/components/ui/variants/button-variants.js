import { cva } from "class-variance-authority";

// Tách khỏi button.jsx để file component chỉ export component (Fast Refresh),
// đồng thời cho phép style <Link> giống nút: className={buttonVariants({ ... })}.
//
// Quy ước của app: nút mặc định bo tròn hẳn (rounded-full). Nút nào cần bo khác
// (rounded-xl, rounded-2xl...) thì truyền qua className. Icon trong nút nên dùng
// `size-*` thay vì `h-* w-*`, vì base ép icon không có `size-*` về size-4.
export const buttonVariants = cva(
  "group/button inline-flex shrink-0 items-center justify-center rounded-full border border-transparent bg-clip-padding whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4",
  {
    variants: {
      variant: {
        // Nút chính: nền xanh thương hiệu.
        default: "bg-brand text-brand-foreground font-semibold hover:bg-brand/90",
        // Nút viền: nền card, viền mảnh.
        outline: "border-border bg-card text-ink font-medium hover:bg-surface",
        // Nút phụ: nền surface xám nhạt.
        secondary:
          "bg-surface text-ink font-semibold hover:bg-black/5 dark:hover:bg-white/10",
        // Nút nền xanh nhạt, chữ xanh.
        soft: "bg-brand-soft text-brand font-semibold hover:brightness-95",
        // Nút icon/ chữ không nền, chỉ hiện nền khi hover.
        ghost: "text-subtle hover:bg-surface hover:text-ink",
        destructive:
          "bg-destructive/10 text-destructive hover:bg-destructive/20 focus-visible:border-destructive/40 focus-visible:ring-destructive/20 dark:bg-destructive/20 dark:hover:bg-destructive/30 dark:focus-visible:ring-destructive/40",
        link: "text-brand underline-offset-4 hover:underline",
        // Nút CTA nền gradient xanh — nút submit ở các form auth.
        gradient:
          "bg-gradient-to-r from-brand to-brand-2 font-bold text-white shadow-lg hover:brightness-110 disabled:opacity-60",
        // Nút kính mờ trên nền tối/ảnh (vd. "Tiếp tục với Google" ở màn auth).
        glass:
          "border-white/20 bg-white/10 bg-clip-border font-semibold text-white/90 backdrop-blur-sm hover:bg-white/20",
      },
      size: {
        xs: "h-6 gap-1 px-2 text-xs",
        sm: "h-7 gap-1.5 px-3 text-xs",
        default: "h-8 gap-1.5 px-3.5 text-sm",
        md: "h-10 gap-2 px-4 text-sm",
        lg: "h-11 gap-2 px-5 text-sm",
        xl: "h-12 gap-2 px-4 text-[15px]",
        icon: "size-8",
        "icon-xs": "size-6",
        "icon-sm": "size-7",
        "icon-lg": "size-9",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
)
