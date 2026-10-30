import { useState } from "react";
import { Link } from "react-router-dom";
import { Bookmark, BookOpen, ChefHat, Loader2, Trash2, Video } from "lucide-react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { useFavorites, useToggleFavorite } from "@/features/profile/hooks/useProfileExtras";
import { cn } from "@/lib/utils";
import FallbackImage from "@/shared/components/FallbackImage";

const TABS = [
  { value: undefined, label: "Tất cả" },
  { value: "RECIPE", label: "Công thức" },
  { value: "BLOG", label: "Bài viết" },
  { value: "VIDEO", label: "Video" },
];

const TARGETS = {
  RECIPE: { label: "Công thức", icon: ChefHat, path: (id) => `/recipes/${id}` },
  BLOG: { label: "Bài viết", icon: BookOpen, path: (id) => `/blog/${id}` },
  VIDEO: { label: "Video", icon: Video, path: (id) => `/videos/${id}` },
};

/** Bộ sưu tập yêu thích ở trang Hồ sơ (GET /users/me/favorites), lọc theo loại, bỏ lưu từng mục. */
export default function FavoritesCard() {
  const [type, setType] = useState(undefined);
  const { data: favorites, isPending, isError, error } = useFavorites(type);
  const toggle = useToggleFavorite();

  const remove = async (item) => {
    try {
      await toggle.mutateAsync({ favorite: false, targetType: item.targetType, targetId: item.targetId });
      toast.success("Đã bỏ khỏi yêu thích");
    } catch (err) {
      toast.error(err.message);
    }
  };

  return (
    <section className="rounded-3xl border border-border bg-card p-5 shadow-sm sm:p-6">
      <h2 className="flex items-center gap-2 font-heading text-lg font-bold text-ink">
        <Bookmark className="size-5 text-brand" />
        Yêu thích của tôi
      </h2>

      <div role="tablist" className="mt-4 flex flex-wrap gap-2">
        {TABS.map((tab) => (
          <button
            key={tab.label}
            type="button"
            role="tab"
            aria-selected={type === tab.value}
            onClick={() => setType(tab.value)}
            className={cn(
              "rounded-full px-3.5 py-1.5 text-xs font-medium transition",
              type === tab.value ? "bg-brand text-brand-foreground" : "bg-surface text-subtle hover:text-ink"
            )}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {isPending ? (
        <p className="mt-4 flex items-center gap-2 text-sm text-subtle">
          <Loader2 className="size-4 animate-spin" />
          Đang tải...
        </p>
      ) : isError ? (
        <p className="mt-4 rounded-xl bg-destructive/10 px-3 py-2 text-sm text-destructive">{error.message}</p>
      ) : favorites.length === 0 ? (
        <p className="mt-4 rounded-2xl bg-surface px-4 py-6 text-center text-sm text-subtle">
          Chưa lưu mục nào. Bấm “Lưu” ở công thức, bài viết hoặc video để xem lại tại đây.
        </p>
      ) : (
        <ul className="mt-4 flex flex-col gap-2">
          {favorites.map((item) => {
            const target = TARGETS[item.targetType];
            const Icon = target?.icon ?? Bookmark;
            return (
              <li key={item.id ?? `${item.targetType}-${item.targetId}`} className="flex items-center gap-3 rounded-2xl bg-surface p-2.5">
                <FallbackImage
                  src={item.imageUrl}
                  alt=""
                  className="size-12 shrink-0 rounded-xl object-cover"
                  fallback={
                    <div className="grid size-12 shrink-0 place-items-center rounded-xl bg-brand-soft text-brand">
                      <Icon className="size-5" />
                    </div>
                  }
                />
                <div className="min-w-0 flex-1">
                  {target ? (
                    <Link to={target.path(item.targetId)} className="block truncate text-sm font-semibold text-ink hover:text-brand">
                      {item.title || `${target.label} #${item.targetId}`}
                    </Link>
                  ) : (
                    <p className="truncate text-sm font-semibold text-ink">{item.title || `#${item.targetId}`}</p>
                  )}
                  <p className="text-xs text-subtle">{target?.label ?? item.targetType}</p>
                </div>
                <Button
                  type="button"
                  variant="ghost"
                  size="icon-sm"
                  aria-label="Bỏ khỏi yêu thích"
                  onClick={() => remove(item)}
                  disabled={toggle.isPending}
                >
                  <Trash2 className="size-4 text-destructive" />
                </Button>
              </li>
            );
          })}
        </ul>
      )}
    </section>
  );
}
