import { flushSync } from "react-dom";
import { Moon, Sun } from "lucide-react";

import { useThemeStore } from "@/shared/store/themeStore";
import { cn } from "@/lib/utils";

const TRANSITION_DURATION = 500;

/**
 * Nút bật/tắt dark mode với hiệu ứng "Circular Reveal" mở rộng từ vị trí
 * con trỏ chuột, dựa trên View Transitions API. Trình duyệt không hỗ trợ
 * `startViewTransition` sẽ chuyển theme ngay lập tức, không hiệu ứng.
 */
export default function ThemeToggle({ className }) {
    const theme = useThemeStore((s) => s.theme);
    const toggleTheme = useThemeStore((s) => s.toggleTheme);
    const isDark = theme === "dark";

    const handleClick = (event) => {
        const x = event.clientX;
        const y = event.clientY;

        if (!document.startViewTransition) {
            toggleTheme();
            return;
        }

        const endRadius = Math.hypot(
            Math.max(x, window.innerWidth - x),
            Math.max(y, window.innerHeight - y)
        );

        const transition = document.startViewTransition(() => {
            flushSync(() => {
                toggleTheme();
            });
        });

        transition.ready
            .then(() => {
                document.documentElement.animate(
                    {
                        clipPath: [
                            `circle(0px at ${x}px ${y}px)`,
                            `circle(${endRadius}px at ${x}px ${y}px)`,
                        ],
                    },
                    {
                        duration: TRANSITION_DURATION,
                        easing: "ease-in-out",
                        pseudoElement: "::view-transition-new(root)",
                    }
                );
            })
            .catch(() => {
                // Transition bị hủy (vd. đổi theme quá nhanh) — bỏ qua an toàn.
            });
    };

    return (
        <button
            type="button"
            onClick={handleClick}
            aria-label={isDark ? "Chuyển sang chế độ sáng" : "Chuyển sang chế độ tối"}
            className={cn(
                "grid size-9 shrink-0 place-items-center rounded-full text-subtle transition hover:bg-surface hover:text-ink",
                className
            )}
        >
            {isDark ? <Sun className="h-5 w-5" /> : <Moon className="h-5 w-5" />}
        </button>
    );
}
