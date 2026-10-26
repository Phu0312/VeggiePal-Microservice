import { useState } from "react";
import { History, Loader2 } from "lucide-react";

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
import { useMealPlan, useMealPlanVersion, useMealPlanVersions } from "@/features/meal-planner/hooks/useMealPlans";
import { averageDailyTotals, formatDateTime } from "@/features/meal-planner/utils/mealPlan";

/** "TB mỗi ngày: 1.650 kcal · đạm 51g · tinh bột 201g · béo 41g" hoặc chuỗi rỗng khi bản cũ không có số liệu. */
function describeAverage(plan) {
  const average = averageDailyTotals(plan);
  if (!average) return "";
  const n = (value) => value.toLocaleString("vi-VN");
  return `TB mỗi ngày: ${n(average.calories)} kcal · đạm ${n(average.protein)}g · tinh bột ${n(
    average.carbohydrate,
  )}g · béo ${n(average.fat)}g`;
}

/**
 * Nút "Lịch sử" + hộp thoại liệt kê các phiên bản cũ của một thực đơn (chỉ xem, BE chưa có API khôi phục).
 * Đầu hộp thoại là phiên bản hiện tại lấy mới từ server (GET /ai/meal-plans/:id); bấm "Xem nội dung" ở một phiên bản
 * cũ để xem 7 ngày của bản đó (GET /ai/meal-plans/:id/versions/:version).
 * BE chỉ lưu phiên bản khi thực đơn được cập nhật theo sức khỏe hoặc sửa thủ công; đổi món bằng AI thì không.
 * `plan` là một MealPlan trong danh sách của useMealPlans (có `version` hiện tại).
 */
export default function PlanVersionsButton({ plan }) {
  const [open, setOpen] = useState(false);
  const [expandedVersion, setExpandedVersion] = useState(null);
  const { data: versions, isPending, isError, error, refetch } = useMealPlanVersions(plan.id, open);
  const { data: current } = useMealPlan(plan.id, open);
  // Phiên bản hiện tại lấy mới từ server; chưa tải xong thì dùng bản đã có trong danh sách trang.
  const currentPlan = current ?? plan;

  const handleOpenChange = (next) => {
    setOpen(next);
    if (!next) setExpandedVersion(null);
  };

  return (
    <>
      <Button type="button" variant="outline" size="sm" onClick={() => setOpen(true)}>
        <History className="size-4" />
        Lịch sử
      </Button>

      <Dialog open={open} onOpenChange={handleOpenChange}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Lịch sử phiên bản</DialogTitle>
            <DialogDescription>
              “{currentPlan.name}” đang ở phiên bản {currentPlan.version ?? 1}
              {currentPlan.updatedAt && ` (cập nhật lúc ${formatDateTime(currentPlan.updatedAt)})`}. Mỗi lần cập nhật
              theo chỉ số sức khỏe hoặc sửa thủ công, bản trước đó được lưu lại ở đây.
            </DialogDescription>
          </DialogHeader>

          {isPending && (
            <p className="flex items-center gap-2 py-6 text-sm text-subtle">
              <Loader2 className="size-4 animate-spin" />
              Đang tải lịch sử...
            </p>
          )}

          {isError && (
            <div className="flex flex-col items-start gap-3 rounded-2xl bg-destructive/10 px-4 py-3">
              <p className="text-sm text-destructive">{error.message}</p>
              <Button type="button" variant="outline" size="sm" onClick={() => refetch()}>
                Thử lại
              </Button>
            </div>
          )}

          {versions && versions.length === 0 && (
            <p className="rounded-2xl bg-surface px-4 py-6 text-center text-sm text-subtle">
              Thực đơn này chưa có phiên bản cũ nào.
            </p>
          )}

          {versions && versions.length > 0 && (
            <ul className="flex flex-col gap-2">
              {versions.map((item) => {
                const average = describeAverage(item.plan);
                return (
                  <li key={item.id ?? item.version} className="rounded-2xl border border-border px-4 py-3 text-sm">
                    <div className="flex flex-wrap items-baseline justify-between gap-x-3">
                      <span className="font-semibold text-ink">Phiên bản {item.version}</span>
                      <span className="text-xs text-subtle">Thay thế lúc {formatDateTime(item.createdAt)}</span>
                    </div>
                    {item.changeSummary && <p className="mt-1 text-body">{item.changeSummary}</p>}
                    {average && <p className="mt-1 text-xs text-subtle">{average}</p>}
                    <Button
                      type="button"
                      variant="outline"
                      size="sm"
                      className="mt-2"
                      aria-expanded={expandedVersion === item.version}
                      onClick={() => setExpandedVersion((value) => (value === item.version ? null : item.version))}
                    >
                      {expandedVersion === item.version ? "Ẩn nội dung" : "Xem nội dung"}
                    </Button>
                    {expandedVersion === item.version && <VersionDetail planId={plan.id} version={item.version} />}
                  </li>
                );
              })}
            </ul>
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

// Tách riêng để chỉ gọi GET /ai/meal-plans/:id/versions/:version khi người dùng mở phiên bản đó.
function VersionDetail({ planId, version }) {
  const { data, isPending, isError, error, refetch } = useMealPlanVersion(planId, version, true);

  return (
    <div className="mt-3">
      {isPending && (
        <p className="flex items-center gap-2 py-2 text-xs text-subtle">
          <Loader2 className="size-4 animate-spin" />
          Đang tải phiên bản...
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
