import { cva } from "class-variance-authority";

// Tách khỏi input.jsx cho cùng kiểu với button.jsx / button-variants.js.
//
// - default: ô nhập trên nền sáng/tối của app (trang Profile).
// - auth: ô chỉ có đường kẻ chân, chữ trắng trên nền kính mờ (các form đăng nhập/đăng ký).
//   Chỉnh riêng từng ô (chiều cao, màu viền...) qua className.
export const inputVariants = cva("w-full outline-none transition", {
  variants: {
    variant: {
      default:
        "h-11 rounded-xl border border-border bg-surface px-3.5 text-sm text-ink placeholder:text-subtle focus:border-brand/40 focus:ring-2 focus:ring-brand/15 aria-[invalid=true]:border-destructive/50 aria-[invalid=true]:ring-2 aria-[invalid=true]:ring-destructive/20",
      auth: "auth-input h-11 border-b border-white/20 bg-transparent pr-8 text-[15px] text-white placeholder:text-white/80 focus:border-white aria-[invalid=true]:border-destructive",
    },
  },
  defaultVariants: {
    variant: "default",
  },
});
