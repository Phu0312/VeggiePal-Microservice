import { Link, NavLink, Outlet } from "react-router-dom";
import { Activity, CreditCard, ExternalLink, FolderTree, LayoutDashboard, LogOut, Salad, ShieldAlert, ShieldCheck } from "lucide-react";

import logo from "@/assets/img/logo.png";
import { Button } from "@/components/ui/button";
import { usePendingModerationCases } from "@/features/admin/moderation/hooks/useModeration";
import { useAuthStore } from "@/features/auth/store/authStore";
import { cn } from "@/lib/utils";
import ThemeToggle from "@/shared/components/ThemeToggle";

const NAV_ITEMS = [
  { to: "/admin", label: "Tổng quan", icon: LayoutDashboard, end: true },
  { to: "/admin/categories", label: "Danh mục", icon: FolderTree },
  { to: "/admin/ingredients", label: "Nguyên liệu", icon: Salad },
  { to: "/admin/moderation", label: "Kiểm duyệt", icon: ShieldAlert, showBadge: true },
  { to: "/admin/ai-monitoring", label: "Giám sát AI", icon: Activity },
  { to: "/admin/payments", label: "Thanh toán", icon: CreditCard },
];

const navClass = ({ isActive }) =>
  cn(
    "flex shrink-0 items-center gap-2 rounded-full px-4 py-2 text-sm font-medium transition lg:rounded-2xl",
    isActive ? "bg-brand-soft text-brand" : "text-subtle hover:bg-surface hover:text-ink"
  );

// Khung trang quản trị: thanh trên (logo, về trang web, đổi theme, đăng xuất) + menu trái.
// Dưới lg menu chuyển thành hàng nút cuộn ngang phía trên nội dung.
export default function AdminLayout() {
  const user = useAuthStore((s) => s.user);
  const logout = useAuthStore((s) => s.logout);
  const { data: pendingCases = [] } = usePendingModerationCases();
  const pendingCount = pendingCases.length;

  return (
    <div className="min-h-dvh bg-canvas">
      <header className="sticky top-0 z-30 border-b border-border bg-card/90 backdrop-blur">
        <div className="mx-auto flex w-full max-w-[1400px] items-center gap-3 px-4 py-2 sm:px-6">
          <Link to="/admin" className="flex shrink-0 items-center gap-2">
            <img src={logo} alt="VeggiePal" className="h-10 w-auto" />
            <span className="hidden items-center gap-1 rounded-full bg-brand-soft px-2.5 py-1 text-xs font-semibold text-brand sm:flex">
              <ShieldCheck className="size-3.5" />
              Quản trị
            </span>
          </Link>

          <div className="ml-auto flex items-center gap-2">
            <Link
              to="/"
              className="hidden items-center gap-1.5 rounded-full px-3 py-2 text-sm font-medium text-subtle transition hover:bg-surface hover:text-ink sm:flex"
            >
              <ExternalLink className="size-4" />
              Xem trang web
            </Link>
            <ThemeToggle />
            <span className="hidden max-w-40 truncate text-sm font-medium text-ink md:block">
              {user?.fullName}
            </span>
            <Button type="button" variant="outline" size="sm" onClick={logout}>
              <LogOut className="size-4" />
              <span className="hidden sm:inline">Đăng xuất</span>
            </Button>
          </div>
        </div>
      </header>

      <div className="mx-auto flex w-full max-w-[1400px] flex-col gap-4 px-4 py-6 sm:px-6 lg:flex-row lg:gap-8">
        <nav
          aria-label="Menu quản trị"
          className="no-scrollbar flex gap-1 overflow-x-auto lg:sticky lg:top-20 lg:w-56 lg:shrink-0 lg:flex-col lg:self-start"
        >
          {NAV_ITEMS.map(({ to, label, icon: Icon, end, showBadge }) => (
            <NavLink key={to} to={to} end={end} className={navClass}>
              <Icon className="size-4" />
              <span className="flex-1">{label}</span>
              {showBadge && pendingCount > 0 && (
                <span className="ml-1 inline-flex size-5 items-center justify-center rounded-full bg-warning text-[10px] font-bold text-white">
                  {pendingCount > 99 ? "99+" : pendingCount}
                </span>
              )}
            </NavLink>
          ))}
        </nav>

        <main className="min-w-0 flex-1">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
