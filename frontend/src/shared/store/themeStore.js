import { create } from "zustand";

const STORAGE_KEY = "theme";

function getPreferredTheme() {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored === "light" || stored === "dark") return stored;
    return window.matchMedia("(prefers-color-scheme: dark)").matches
        ? "dark"
        : "light";
}

function applyThemeClass(theme) {
    document.documentElement.classList.toggle("dark", theme === "dark");
}

const initialTheme = getPreferredTheme();
applyThemeClass(initialTheme);

/**
 * Nguồn sự thật cho theme (light/dark) của toàn app.
 * - Đồng bộ với class `dark` trên <html> để Tailwind dark: hoạt động.
 * - Lưu lựa chọn vào localStorage để giữ theme khi F5 / mở tab mới.
 */
export const useThemeStore = create((set, get) => ({
    theme: initialTheme,

    setTheme: (theme) => {
        localStorage.setItem(STORAGE_KEY, theme);
        applyThemeClass(theme);
        set({ theme });
    },

    toggleTheme: () => {
        const next = get().theme === "dark" ? "light" : "dark";
        get().setTheme(next);
    },
}));
