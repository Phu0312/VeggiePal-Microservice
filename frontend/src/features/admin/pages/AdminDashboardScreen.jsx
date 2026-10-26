import { Link } from "react-router-dom";
import { Activity, ArrowRight, Eye, EyeOff, FolderTree, Leaf, Salad, ShieldAlert, TriangleAlert } from "lucide-react";

import { useAuthStore } from "@/features/auth/store/authStore";
import { usePendingModerationCases } from "@/features/admin/moderation/hooks/useModeration";
import { useCategories } from "@/features/blog/hooks/useCategories";
import { useIngredients } from "@/features/ingredient/hooks/useIngredients";
import { cn } from "@/lib/utils";

// Trang tổng quan quản trị (/admin): số liệu nhanh + lối tắt tới các trang quản lý.
// Số liệu lấy từ các API công khai có sẵn (đếm qua totalElements, size=1 cho nhẹ).
export default function AdminDashboardScreen() {
  const user = useAuthStore((s) => s.user);

  const categories = useCategories({ activeOnly: false });
  const allIngredients = useIngredients({ size: 1 });
  const veganIngredients = useIngredients({ vegan: true, size: 1 });
  const allergenIngredients = useIngredients({ allergen: true, size: 1 });
  const pendingModerations = usePendingModerationCases();

  // Cây 2 cấp: đếm cả danh mục gốc lẫn con; đang ẩn = active false.
  const allCategories = (categories.data ?? []).flatMap((root) => [root, ...(root.children ?? [])]);
  const hiddenCount = allCategories.filter((c) => !c.active).length;
  const pendingCount = pendingModerations.data?.length ?? 0;

  return (
    <div className="flex flex-col gap-8">
      <div>
        <h1 className="font-heading text-3xl font-bold text-ink">Tổng quan quản trị</h1>
        <p className="mt-1 text-sm text-subtle">
          Xin chào{user?.fullName ? `, ${user.fullName}` : ""}. Đây là tình hình dữ liệu hiện tại của VeggiePal.
        </p>
      </div>

      <section aria-label="Số liệu nhanh" className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-5">
        <StatCard
          icon={FolderTree}
          label="Danh mục"
          value={categories.isPending ? null : allCategories.length}
          error={categories.isError}
          note={categories.data ? `${hiddenCount} đang ẩn` : undefined}
          noteIcon={hiddenCount > 0 ? EyeOff : Eye}
          tone="brand"
        />
        <StatCard
          icon={Salad}
          label="Nguyên liệu đang dùng"
          value={allIngredients.data?.totalElements}
          loading={allIngredients.isPending}
          error={allIngredients.isError}
          tone="chart-2"
        />
        <StatCard
          icon={Leaf}
          label="Nguyên liệu thuần chay"
          value={veganIngredients.data?.totalElements}
          loading={veganIngredients.isPending}
          error={veganIngredients.isError}
          tone="chart-5"
        />
        <StatCard
          icon={TriangleAlert}
          label="Có thể gây dị ứng"
          value={allergenIngredients.data?.totalElements}
          loading={allergenIngredients.isPending}
          error={allergenIngredients.isError}
          tone="chart-4"
        />
        <StatCard
          icon={ShieldAlert}
          label="Chờ kiểm duyệt AI"
          value={pendingModerations.isPending ? null : pendingCount}
          loading={pendingModerations.isPending}
          error={pendingModerations.isError}
          note={pendingCount > 0 ? "Cần admin xử lý" : "Hàng đợi trống"}
          noteIcon={ShieldAlert}
          tone={pendingCount > 0 ? "warning" : "brand"}
        />
      </section>

      <section aria-label="Lối tắt" className="grid grid-cols-1 gap-4 md:grid-cols-2">
        <ShortcutCard
          to="/admin/moderation"
          icon={ShieldAlert}
          title="Kiểm duyệt nội dung"
          description="Xem xét và duyệt các bài viết, video, bình luận bị AI gắn cờ vi phạm."
        />
        <ShortcutCard
          to="/admin/categories"
          icon={FolderTree}
          title="Quản lý danh mục"
          description="Thêm, sửa, ẩn hoặc xóa danh mục bài viết (tối đa 2 cấp)."
        />
        <ShortcutCard
          to="/admin/ingredients"
          icon={Salad}
          title="Quản lý nguyên liệu"
          description="Cập nhật nguyên liệu và dinh dưỡng trên 100g để tính kcal công thức."
        />
        <ShortcutCard
          to="/admin/ai-monitoring"
          icon={Activity}
          title="Giám sát AI"
          description="Lượt dùng, token, độ trễ, lỗi và nhật ký các tính năng AI."
        />
      </section>

      <p className="rounded-2xl bg-surface px-4 py-3 text-sm text-subtle">
        Hệ thống kiểm duyệt nội dung tự động AI và giám sát hạn ngạch đã được tích hợp đầy đủ.
      </p>
    </div>
  );
}

const TONE_CLASS = {
  brand: "bg-brand-soft text-brand",
  warning: "bg-warning/15 text-warning",
  "chart-2": "bg-chart-2/15 text-chart-2",
  "chart-4": "bg-chart-4/15 text-chart-4",
  "chart-5": "bg-chart-5/15 text-chart-5",
};

function StatCard({ icon: Icon, label, value, loading, error, note, noteIcon: NoteIcon, tone }) {
  const isLoading = loading ?? value === null;

  return (
    <div className="rounded-3xl border border-border bg-card p-5 shadow-sm">
      <span className={cn("grid size-10 place-items-center rounded-2xl", TONE_CLASS[tone])}>
        <Icon className="size-5" />
      </span>
      <p className="mt-4 text-3xl font-bold tabular-nums text-ink">
        {error ? "—" : isLoading ? <span className="inline-block h-8 w-12 animate-pulse rounded bg-surface align-middle" /> : value}
      </p>
      <p className="mt-1 text-sm text-subtle">{label}</p>
      {note && !error && (
        <p className="mt-2 flex items-center gap-1 text-xs text-subtle">
          {NoteIcon && <NoteIcon className="size-3" />}
          {note}
        </p>
      )}
      {error && <p className="mt-2 text-xs text-destructive">Không tải được số liệu</p>}
    </div>
  );
}

function ShortcutCard({ to, icon: Icon, title, description }) {
  return (
    <Link
      to={to}
      className="group flex items-center gap-4 rounded-3xl border border-border bg-card p-5 shadow-sm transition hover:shadow-md"
    >
      <span className="grid size-12 shrink-0 place-items-center rounded-2xl bg-brand-soft text-brand">
        <Icon className="size-6" />
      </span>
      <span className="min-w-0 flex-1">
        <span className="block font-heading text-lg font-bold text-ink">{title}</span>
        <span className="block text-sm text-subtle">{description}</span>
      </span>
      <ArrowRight className="size-5 shrink-0 text-subtle transition group-hover:translate-x-1 group-hover:text-brand" />
    </Link>
  );
}
