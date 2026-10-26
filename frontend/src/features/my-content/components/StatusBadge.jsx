import { cn } from "@/lib/utils";

// Dùng token màu nên đúng cả light lẫn dark.
const TONE_CLASS = {
  success: "bg-brand-soft text-brand",
  warning: "bg-warning/15 text-warning",
  danger: "bg-destructive/10 text-destructive",
  muted: "bg-surface text-subtle",
};

/** Nhãn trạng thái dạng viên thuốc. `info` lấy từ getBlogStatusInfo / getRecipeStatusInfo. */
export default function StatusBadge({ info }) {
  return (
    <span
      className={cn(
        "inline-block shrink-0 rounded-full px-2.5 py-1 text-[11px] font-medium",
        TONE_CLASS[info.tone]
      )}
    >
      {info.label}
    </span>
  );
}
