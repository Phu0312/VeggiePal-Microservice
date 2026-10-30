import { useState } from "react";
import { History, Loader2, RotateCcw } from "lucide-react";
import { toast } from "sonner";

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
import { useRestoreMealPlanVersion } from "@/features/meal-planner/hooks/useMealPlanMutations";
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
 * Nút "Lịch sử" + hộp thoại liệt kê các phiên bản cũ của một thực đơn, xem và khôi phục từng bản
 * (POST /ai/meal-plans/:id/versions/:version/restore; BE lưu bản hiện tại vào lịch sử trước khi khôi phục).
 * Đầu hộp thoại là phiên bản hiện tại lấy mới từ server (GET /ai/meal-plans/:id); bấm "Xem nội dung" ở một phiên bản
 * cũ để xem 7 ngày của bản đó (GET /ai/meal-plans/:id/versions/:version).
 * BE chỉ lưu phiên bản khi thực đơn được cập nhật theo sức khỏe hoặc sửa thủ công; đổi món bằng AI thì không.
 * `plan` là một MealPlan trong danh sách của useMealPlans (có `version` hiện tại).
 */
export default function PlanVersionsButton({ plan }) {
  const [open, setOpen] = useState(false);
  const [expandedVersion, setExpandedVersion] = useState(null);
  const [restoringVersion, setRestoringVersion] = useState(null);
  const { data: versions, isPending, isError, error, refetch } = useMealPlanVersions(plan.id, open);
  const { data: current } = useMealPlan(plan.id, open);
  // Phiên bản hiện tại lấy mới từ server; chưa tải xong thì dùng bản đã có trong danh sách trang.
  const currentPlan = current ?? plan;

  const handleOpenChange = (next) => {
    setOpen(next);
    if (!next) {
      setExpandedVersion(null);
      setRestoringVersion(null);
    }
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
                    <div className="mt-2 flex flex-wrap gap-2">
                      <Button
                        type="button"
                        variant="outline"
                        size="sm"
                        aria-expanded={expandedVersion === item.version}
                        onClick={() => setExpandedVersion((value) => (value === item.version ? null : item.version))}
                      >
                        {expandedVersion === item.version ? "Ẩn nội dung" : "Xem nội dung"}
                      </Button>
                      <Button
                        type="button"
                        variant="soft"
                        size="sm"
                        aria-expanded={restoringVersion === item.version}
                        onClick={() => setRestoringVersion((value) => (value === item.version ? null : item.version))}
                      >
                        <RotateCcw className="size-4" />
                        Khôi phục
                      </Button>
                    </div>
                    {restoringVersion === item.version && (
                      <RestoreConfirm
                        planId={plan.id}
                        version={item.version}
                        onCancel={() => setRestoringVersion(null)}
                        onDone={() => {
                          setRestoringVersion(null);
                          setExpandedVersion(null);
                        }}
                      />
                    )}
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

// Xác nhận khôi phục kèm ghi chú tùy chọn (tối đa 500 ký tự, bỏ trống thì BE ghi "Khôi phục từ phiên bản N").
function RestoreConfirm({ planId, version, onCancel, onDone }) {
  const [note, setNote] = useState("");
  const restore = useRestoreMealPlanVersion();

  const confirm = async () => {
    try {
      await restore.mutateAsync({ planId, version, changeSummary: note.trim() || undefined });
      toast.success(`Đã khôi phục phiên bản ${version}`);
      onDone();
    } catch (error) {
      toast.error(error.message);
    }
  };

  return (
    <div className="mt-3 flex flex-col gap-2 rounded-2xl bg-surface p-3">
      <p className="text-xs text-body">
        Thực đơn sẽ quay về nội dung của phiên bản {version}. Bản hiện tại vẫn được giữ trong lịch sử. Khẩu phần đã tự
        chỉnh ở bản hiện tại sẽ theo phiên bản được khôi phục.
      </p>
      <input
        value={note}
        maxLength={500}
        onChange={(event) => setNote(event.target.value)}
        placeholder="Ghi chú thay đổi (không bắt buộc)"
        aria-label="Ghi chú thay đổi"
        className="h-10 w-full rounded-xl border border-border bg-card px-3.5 text-sm text-ink outline-none transition placeholder:text-subtle focus:border-brand/40 focus:ring-2 focus:ring-brand/15"
      />
      <div className="flex justify-end gap-2">
        <Button type="button" variant="ghost" size="sm" onClick={onCancel} disabled={restore.isPending}>
          Hủy
        </Button>
        <Button type="button" size="sm" onClick={confirm} disabled={restore.isPending}>
          {restore.isPending && <Loader2 className="size-4 animate-spin" />}
          Xác nhận khôi phục
        </Button>
      </div>
    </div>
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
