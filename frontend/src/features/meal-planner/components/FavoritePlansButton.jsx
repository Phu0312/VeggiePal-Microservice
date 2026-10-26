import { useState } from "react";
import { ChevronLeft, ChevronRight, Heart, Loader2 } from "lucide-react";

import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import PlanDaysPreview from "@/features/meal-planner/components/PlanDaysPreview";
import { useFavoriteMealPlan, useFavoriteMealPlans } from "@/features/meal-planner/hooks/useMealPlans";
import { averageDailyTotals, formatDateTime, planGoalSummary } from "@/features/meal-planner/utils/mealPlan";

const PAGE_SIZE = 5;

const formatNumber = (value) => Number(value).toLocaleString("vi-VN");

/**
 * Nút "Yêu thích của tôi" + hộp thoại liệt kê các thực đơn đã yêu thích (GET /ai/meal-plans/favorites, phân trang).
 * Mỗi mục bấm "Xem chi tiết" để mở 7 ngày của thực đơn (GET /ai/meal-plans/favorites/:id), hoặc "Mở trên trang" để
 * chuyển trang thực đơn sang thực đơn đó. `plans` là danh sách thực đơn đã tải của trang; `onSelectPlan(id)` chọn một cái.
 */
export default function FavoritePlansButton({ plans, onSelectPlan }) {
  const [open, setOpen] = useState(false);
  const [page, setPage] = useState(0);
  const [expandedId, setExpandedId] = useState(null);
  const { data, isPending, isError, error, refetch, isFetching } = useFavoriteMealPlans(page, PAGE_SIZE, open);

  const handleOpenChange = (next) => {
    setOpen(next);
    if (!next) {
      setPage(0);
      setExpandedId(null);
    }
  };

  const goToPage = (next) => {
    setPage(next);
    setExpandedId(null);
  };

  const handleOpenOnPage = (planId) => {
    onSelectPlan(planId);
    handleOpenChange(false);
    document.getElementById("today-meals")?.scrollIntoView({ behavior: "smooth" });
  };

  const items = data?.content ?? [];
  const loadedIds = new Set(plans.map((plan) => plan.id));

  return (
    <>
      <Button type="button" variant="outline" size="sm" onClick={() => setOpen(true)}>
        <Heart className="size-4" />
        Yêu thích của tôi
      </Button>

      <Dialog open={open} onOpenChange={handleOpenChange}>
        <DialogContent className="sm:max-w-xl">
          <DialogHeader>
            <DialogTitle>Thực đơn yêu thích</DialogTitle>
            <DialogDescription>Các thực đơn bạn đã bấm “Yêu thích”, mới yêu thích hiện trước.</DialogDescription>
          </DialogHeader>

          {isPending && (
            <p className="flex items-center gap-2 py-6 text-sm text-subtle">
              <Loader2 className="size-4 animate-spin" />
              Đang tải danh sách...
            </p>
          )}

          {isError && !data && (
            <div className="flex flex-col items-start gap-3 rounded-2xl bg-destructive/10 px-4 py-3">
              <p className="text-sm text-destructive">{error.message}</p>
              <Button type="button" variant="outline" size="sm" onClick={() => refetch()}>
                Thử lại
              </Button>
            </div>
          )}

          {data && items.length === 0 && (
            <p className="rounded-2xl bg-surface px-4 py-6 text-center text-sm text-subtle">
              Bạn chưa yêu thích thực đơn nào. Bấm “Yêu thích” ở thực đơn đang xem để lưu lại đây.
            </p>
          )}

          {items.length > 0 && (
            <ul className="flex flex-col gap-2" aria-busy={isFetching}>
              {items.map((item) => (
                <FavoriteItem
                  key={item.id}
                  item={item}
                  expanded={expandedId === item.id}
                  canOpenOnPage={loadedIds.has(item.id)}
                  onToggle={() => setExpandedId((current) => (current === item.id ? null : item.id))}
                  onOpenOnPage={() => handleOpenOnPage(item.id)}
                />
              ))}
            </ul>
          )}

          {data && data.totalPages > 1 && (
            <div className="flex items-center justify-between text-sm text-subtle">
              <Button
                type="button"
                variant="ghost"
                size="sm"
                disabled={data.first || isFetching}
                onClick={() => goToPage(page - 1)}
              >
                <ChevronLeft className="size-4" />
                Trước
              </Button>
              <span>
                Trang {data.page + 1} / {data.totalPages} · {data.totalElements} thực đơn
              </span>
              <Button
                type="button"
                variant="ghost"
                size="sm"
                disabled={data.last || isFetching}
                onClick={() => goToPage(page + 1)}
              >
                Sau
                <ChevronRight className="size-4" />
              </Button>
            </div>
          )}

          <DialogFooter>
            <Button type="button" variant="ghost" onClick={() => handleOpenChange(false)}>
              Đóng
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}

function FavoriteItem({ item, expanded, canOpenOnPage, onToggle, onOpenOnPage }) {
  const average = averageDailyTotals(item.plan);
  return (
    <li className="rounded-2xl border border-border px-4 py-3 text-sm">
      <div className="flex flex-wrap items-baseline justify-between gap-x-3">
        <span className="font-semibold text-ink">{item.name}</span>
        <span className="text-xs text-subtle">Tạo lúc {formatDateTime(item.createdAt)}</span>
      </div>
      {planGoalSummary(item) && (
        <p className="mt-1 line-clamp-1 text-xs text-subtle">Mục tiêu: {planGoalSummary(item)}</p>
      )}
      {average && (
        <p className="mt-1 text-xs text-subtle">
          TB mỗi ngày: {formatNumber(average.calories)} kcal · đạm {formatNumber(average.protein)}g · tinh bột{" "}
          {formatNumber(average.carbohydrate)}g · béo {formatNumber(average.fat)}g
        </p>
      )}

      <div className="mt-2 flex flex-wrap gap-2">
        <Button type="button" variant="outline" size="sm" aria-expanded={expanded} onClick={onToggle}>
          {expanded ? "Ẩn chi tiết" : "Xem chi tiết"}
        </Button>
        {canOpenOnPage && (
          <Button type="button" size="sm" onClick={onOpenOnPage}>
            Mở trên trang
          </Button>
        )}
      </div>

      {expanded && <FavoriteDetail planId={item.id} />}
    </li>
  );
}

// Tách riêng để chỉ gọi GET /ai/meal-plans/favorites/:id khi người dùng mở mục đó.
function FavoriteDetail({ planId }) {
  const { data, isPending, isError, error, refetch } = useFavoriteMealPlan(planId, true);

  return (
    <div className="mt-3">
      {isPending && (
        <p className="flex items-center gap-2 py-2 text-xs text-subtle">
          <Loader2 className="size-4 animate-spin" />
          Đang tải thực đơn...
        </p>
      )}
      {isError && (
        <div className="flex flex-col items-start gap-2 rounded-2xl bg-destructive/10 px-3 py-2">
          <p className="text-xs text-destructive">{error.message}</p>
          <Button type="button" variant="outline" size="sm" onClick={() => refetch()}>
            Thử lại
          </Button>
        </div>
      )}
      {data && <PlanDaysPreview plan={data.plan} />}
    </div>
  );
}
