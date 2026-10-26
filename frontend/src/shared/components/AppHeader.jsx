import { useState } from "react";
import { Link, useLocation } from "react-router-dom";
import {
  Bell,
  Broccoli,
  ChevronDown,
  ChevronRight,
  CircleHelp,
  CircleUserRound,
  FileText,
  Home,
  LogOut,
  MessageSquareWarning,
  Map,
  ShieldCheck,
  Users,
  SquarePlay,
  UserRound,
  UtensilsCrossed,
  ChefHat,
  Crown,
  Receipt,
  Sparkles,
} from "lucide-react";

import logo from "@/assets/img/logo.png";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { useAuthStore, selectIsAuthenticated } from "@/features/auth/store/authStore";
import { useMySubscription } from "@/features/payment/hooks/useMySubscription";
import { formatDate } from "@/features/payment/utils/paymentFormat";
import { useProfile } from "@/features/profile/hooks/useProfile";
import FallbackImage from "@/shared/components/FallbackImage";
import ThemeToggle from "@/shared/components/ThemeToggle";
import { cn } from "@/lib/utils";

// Đăng nhập (POST /auth/login) không trả avatarUrl nên header tự nạp hồ sơ một lần
// rồi giữ trong cache; đổi avatar ở trang hồ sơ ghi thẳng vào cache này nên header đổi theo.
const PROFILE_STALE_MS = 5 * 60 * 1000;

// Avatar tròn: ảnh nếu có (hoặc ảnh lỗi) thì rơi về icon người trên nền brand.
function UserAvatar({ src, name, className, iconClassName }) {
  return (
    <span
      className={cn(
        "grid shrink-0 place-items-center overflow-hidden rounded-full border border-border bg-surface text-ink",
        className
      )}
    >
      <FallbackImage
        src={src}
        alt={name || "Ảnh đại diện"}
        className="size-full object-cover"
        draggable={false}
        fallback={<UserRound className={iconClassName} />}
      />
    </span>
  );
}

const NAV_ITEMS = [
  { id: "home", label: "Trang Chủ", icon: Home, to: "/" },
  { id: "utensils-crossed", label: "Thực Đơn", icon: UtensilsCrossed, to: "/meal-planner" },
  { id: "recipes", label: "Công Thức", icon: ChefHat, to: "/recipes" },
  { id: "square-play", label: "Khám Phá Video", icon: SquarePlay, to: "/videos" },
  { id: "users", label: "Cộng Đồng", icon: Users, to: "/blog" },
  { id: "map", label: "Bản Đồ Xanh", icon: Map, to: "/map" },
  { id: "broccoli", label: "Trợ Lý Bông Cải", icon: Broccoli, to: "/chatbot" },
];

const PROFILE_MENU_ITEMS = [
  { id: "help", label: "Trợ giúp và hỗ trợ", icon: CircleHelp },
  { id: "report", label: "Báo cáo sự cố", icon: MessageSquareWarning },
];

export default function AppHeader() {
  const [menuOpen, setMenuOpen] = useState(false);
  const isAuthenticated = useAuthStore(selectIsAuthenticated);
  const user = useAuthStore((s) => s.user);
  const logout = useAuthStore((s) => s.logout);
  const location = useLocation();
  const { subscription } = useMySubscription();
  const { profile } = useProfile({ enabled: isAuthenticated, staleTime: PROFILE_STALE_MS });

  const displayName = (profile?.fullName ?? user?.fullName)?.trim();
  const displayEmail = profile?.email ?? user?.email;
  const avatarUrl = profile?.avatarUrl ?? user?.avatarUrl;

  return (
    <header className="sticky top-4 z-30 mb-4 px-6 sm:px-8">
      <div className="mx-auto flex w-full max-w-[1560px] items-center justify-between gap-4 rounded-full border border-border bg-card/90 px-6 py-1 shadow-sm backdrop-blur lg:grid lg:grid-cols-[auto_1fr_auto]">
        <div className="flex items-center justify-start">
          <Link to="/" className="flex shrink-0 items-center gap-2">
            <img src={logo} alt="VeggiePal" className="h-12 w-auto mt-1 mb-1" />
          </Link>
        </div>

        <nav className="hidden items-center justify-center gap-1 lg:flex">
          {NAV_ITEMS.map(({ id, label, icon: Icon, to }) => (
            <Link
              key={id}
              to={to}
              className={cn(
                "flex items-center gap-1.5 rounded-full px-2.5 py-1.5 font-display-serif text-sm font-medium transition xl:px-3.5 xl:py-2 xl:text-base",
                // Trang con (vd /blog/5) cũng tính là đang ở mục cha (/blog).
                location.pathname === to ||
                  (to !== "/" && location.pathname.startsWith(`${to}/`))
                  ? "bg-brand-soft text-brand"
                  : "text-subtle hover:bg-surface hover:text-ink"
              )}
            >
              <Icon className="h-4 w-4" />
              {label}
            </Link>
          ))}
        </nav>

        <div className="flex items-center justify-end gap-3">
          {isAuthenticated && (
            <Button
              type="button"
              variant="ghost"
              size="icon-lg"
              aria-label="Thông báo"
              className="relative"
            >
              <Bell className="size-5" />
              <span className="absolute right-2 top-2 size-1.5 rounded-full bg-[#EF6461]" />
            </Button>
          )}

          {/* Khách: icon gói dịch vụ + chữ Đăng nhập / Đăng ký. */}
          {!isAuthenticated && (
            <div className="flex shrink-0 items-center gap-2">
              <Link
                to="/pricing"
                aria-label="Gói dịch vụ"
                title="Gói dịch vụ"
                className="grid size-9 place-items-center rounded-full bg-amber-500/10 text-amber-600 transition hover:bg-amber-500/20 dark:text-amber-400"
              >
                <Crown className="size-5" />
              </Link>
              <Link
                to="/login"
                className="px-2 text-sm font-medium text-subtle transition hover:text-ink"
              >
                Đăng Nhập
              </Link>
              <Link
                to="/register"
                className="rounded-full bg-brand px-4 py-1.5 text-sm font-medium text-brand-foreground transition hover:opacity-90"
              >
                Đăng Ký
              </Link>
            </div>
          )}

          {isAuthenticated && (
            <DropdownMenu open={menuOpen} onOpenChange={setMenuOpen}>
              <DropdownMenuTrigger
                aria-label="Menu tài khoản"
                className="relative size-9 rounded-full outline-none transition hover:opacity-90 focus-visible:ring-2 focus-visible:ring-brand/50"
              >
                <UserAvatar
                  src={avatarUrl}
                  name={displayName}
                  className="size-9"
                  iconClassName="size-5"
                />
                <span className="absolute -bottom-0.5 -right-0.5 grid size-4 place-items-center rounded-full bg-card text-ink shadow ring-1 ring-border">
                  <ChevronDown
                    className={cn(
                      "h-3 w-3 transition-transform",
                      menuOpen && "rotate-180"
                    )}
                  />
                </span>
              </DropdownMenuTrigger>

              <DropdownMenuContent
                align="end"
                sideOffset={12}
                className="w-80 rounded-2xl p-3 shadow-xl"
              >
                <div className="flex items-center gap-3 px-1 py-1.5">
                  <UserAvatar
                    src={avatarUrl}
                    name={displayName}
                    className="size-12"
                    iconClassName="size-6"
                  />
                  <div className="min-w-0">
                    <p className="truncate text-lg font-bold text-ink">
                      {displayName}
                    </p>
                    <p className="truncate text-sm text-subtle">
                      {displayEmail}
                    </p>
                    {subscription && (
                      <div className="mt-1 flex items-center gap-1.5 flex-wrap">
                        <span className="inline-flex items-center gap-1 rounded-full bg-brand/10 border border-brand/20 px-2 py-0.5 text-[11px] font-bold text-brand">
                          <Sparkles className="size-2.5" />
                          Gói {subscription.planCode || "FREE"}
                        </span>
                        {subscription.expiresAt && (
                          <span className="text-[11px] text-subtle">
                            Hạn: {formatDate(subscription.expiresAt)}
                          </span>
                        )}
                      </div>
                    )}
                  </div>
                </div>

                <DropdownMenuItem
                  render={<Link to="/profile" />}
                  className="mt-3 cursor-pointer justify-center gap-2 rounded-full bg-[#E8ECFB] px-4 py-2.5 font-medium text-ink focus:bg-[#DEE3FA] dark:bg-brand-soft dark:focus:bg-[#1c3d27]"
                >
                  <CircleUserRound className="h-4 w-4 text-brand" />
                  Xem trang cá nhân
                </DropdownMenuItem>

                {user?.role === "ADMIN" && (
                  <DropdownMenuItem
                    render={<Link to="/admin" />}
                    className="mt-3 cursor-pointer gap-3 rounded-xl px-1 py-2"
                  >
                    <span className="grid size-9 shrink-0 place-items-center rounded-full bg-brand-soft text-brand">
                      <ShieldCheck className="h-4 w-4" />
                    </span>
                    <span className="flex-1 text-sm font-medium text-ink">Trang quản trị</span>
                    <ChevronRight className="h-4 w-4 text-subtle" />
                  </DropdownMenuItem>
                )}

                <DropdownMenuItem
                  render={<Link to="/my-content" />}
                  className="mt-3 cursor-pointer gap-3 rounded-xl px-1 py-2"
                >
                  <span className="grid size-9 shrink-0 place-items-center rounded-full bg-[#E8ECFB] text-ink dark:bg-brand-soft">
                    <FileText className="h-4 w-4" />
                  </span>
                  <span className="flex-1 text-sm font-medium text-ink">Nội dung của tôi</span>
                  <ChevronRight className="h-4 w-4 text-subtle" />
                </DropdownMenuItem>

                {/* Mục Gói thành viên và Lịch sử thanh toán */}
                <DropdownMenuItem
                  render={<Link to="/pricing" />}
                  className="mt-1 cursor-pointer gap-3 rounded-xl px-1 py-2"
                >
                  <span className="grid size-9 shrink-0 place-items-center rounded-full bg-amber-500/10 text-amber-600 dark:text-amber-400">
                    <Crown className="h-4 w-4" />
                  </span>
                  <span className="flex-1 text-sm font-medium text-ink">Gói thành viên</span>
                  <ChevronRight className="h-4 w-4 text-subtle" />
                </DropdownMenuItem>

                <DropdownMenuItem
                  render={<Link to="/payment/history" />}
                  className="mt-1 cursor-pointer gap-3 rounded-xl px-1 py-2"
                >
                  <span className="grid size-9 shrink-0 place-items-center rounded-full bg-[#E8ECFB] text-ink dark:bg-brand-soft">
                    <Receipt className="h-4 w-4" />
                  </span>
                  <span className="flex-1 text-sm font-medium text-ink">Lịch sử thanh toán</span>
                  <ChevronRight className="h-4 w-4 text-subtle" />
                </DropdownMenuItem>

                <DropdownMenuSeparator className="my-3" />

                {PROFILE_MENU_ITEMS.map(({ id, label, icon: Icon }) => (
                  <DropdownMenuItem
                    key={id}
                    className="cursor-pointer gap-3 rounded-xl px-1 py-2"
                  >
                    <span className="grid size-9 shrink-0 place-items-center rounded-full bg-[#E8ECFB] text-ink dark:bg-brand-soft">
                      <Icon className="h-4 w-4" />
                    </span>
                    <span className="flex-1 text-sm font-medium text-ink">
                      {label}
                    </span>
                    <ChevronRight className="h-4 w-4 text-subtle" />
                  </DropdownMenuItem>
                ))}

                <DropdownMenuSeparator className="my-3" />

                <DropdownMenuItem
                  variant="destructive"
                  onClick={logout}
                  className="cursor-pointer gap-3 rounded-xl px-1 py-2"
                >
                  <span className="grid size-9 shrink-0 place-items-center rounded-full bg-[#FDECEC] text-[#D5443B] dark:bg-[#3a1616] dark:text-[#ff8a80]">
                    <LogOut className="h-4 w-4" />
                  </span>
                  <span className="text-sm font-semibold text-[#D5443B] dark:text-[#ff8a80]">
                    Đăng xuất
                  </span>
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          )}
        </div>
      </div>

      <ThemeToggle className="fixed bottom-6 right-6 z-40 size-11 border border-border bg-card text-ink shadow-lg hover:bg-brand-soft" />
    </header>
  );
}
