import ThemeToggle from "@/shared/components/ThemeToggle";
import bg from "@/assets/img/bg.png";
import { cn } from "@/lib/utils";

export default function AuthLayout({ className, children }) {
  return (
    <div className={cn("relative flex min-h-dvh items-center justify-center overflow-hidden", className)}>
      <img
        src={bg}
        alt=""
        className="absolute inset-0 -z-20 h-full w-full scale-110 object-cover blur-sm brightness-90 dark:brightness-75"
      />
      <div className="absolute inset-0 -z-10 bg-gradient-to-br from-[#eef3df]/70 via-white/40 to-[#bfe08f]/70 dark:from-[#0d2a1c]/85 dark:via-[#0a140f]/75 dark:to-[#0d1f1a]/85" />

      <ThemeToggle className="absolute right-6 top-6 z-10 bg-white/70 hover:bg-white dark:bg-black/30 dark:hover:bg-black/50" />

      {children}
    </div>
  );
}
