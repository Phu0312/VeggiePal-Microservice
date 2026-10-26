import { useState } from "react";
import { zodResolver } from "@hookform/resolvers/zod";
import { HeartPulse, Loader2 } from "lucide-react";
import { useForm, useWatch } from "react-hook-form";
import { Link } from "react-router-dom";
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
import NutritionTargetFields from "@/features/meal-planner/components/NutritionTargetFields";
import { useApplyHealthUpdate, usePreviewHealthUpdate } from "@/features/meal-planner/hooks/useMealPlanMutations";
import { HEALTH_UPDATE_LIMITS, healthUpdateSchema } from "@/features/meal-planner/schema";
import { useProfile } from "@/features/profile/hooks/useProfile";
import {
  averageDailyTotals,
  buildNutritionTarget,
  countMissedDays,
  goalLabel,
  MACRO_ROWS,
  missingProfileFields,
  profileFixState,
  sameTarget,
  TARGET_FIELDS,
  targetRangeLines,
} from "@/features/meal-planner/utils/mealPlan";

const formatNumber = (value) => (value == null ? "—" : Number(value).toLocaleString("vi-VN"));

const noteClass =
  "h-10 w-full rounded-xl border border-border bg-card px-3 text-sm text-ink outline-none transition placeholder:text-subtle focus:border-brand/40 focus:ring-2 focus:ring-brand/15 aria-[invalid=true]:border-destructive/50 aria-[invalid=true]:ring-2 aria-[invalid=true]:ring-destructive/20";

function emptyValues() {
  return { ...Object.fromEntries(TARGET_FIELDS.map((field) => [field, ""])), changeSummary: "" };
}

/**
 * Nút "Cập nhật theo chỉ số mới" + hộp thoại xem trước của một thực đơn.
 * Bấm nút: BE tính lại mục tiêu dinh dưỡng theo chỉ số sức khỏe mới nhất (và ngày sinh, giới tính, mức vận động trong
 * hồ sơ, theo mục tiêu giảm / duy trì / tăng cân đã lưu của thực đơn) rồi co giãn lại khẩu phần, nhưng CHƯA lưu
 * (update-from-health với confirm=false). Người dùng xem so sánh rồi bấm "Áp dụng" mới lưu (confirm=true);
 * BE giữ bản cũ trong lịch sử phiên bản. `plan` là một MealPlan trong danh sách của useMealPlans.
 * Hồ sơ thiếu thông tin thì BE báo 6020 (hiện liên kết sang hồ sơ); dưới 18 tuổi báo 6021 (gợi ý tự đặt mục tiêu riêng).
 *
 * Tùy chọn: tự đặt mục tiêu dinh dưỡng riêng (BE dùng thay hẳn mục tiêu tính từ chỉ số sức khỏe) và ghi chú thay đổi.
 * Bản lưu phải dùng đúng mục tiêu của bản xem trước người dùng vừa thấy, nên đổi ô nhập thì phải xem trước lại
 * mới được áp dụng (`previewTarget` là mục tiêu của lần xem trước gần nhất).
 */
export default function HealthUpdateButton({ plan }) {
  const [open, setOpen] = useState(false);
  const [previewTarget, setPreviewTarget] = useState(undefined);
  const preview = usePreviewHealthUpdate();
  const apply = useApplyHealthUpdate();
  // Hồ sơ để biết trường nào đang thiếu khi BE báo 6020 (gắn vào liên kết sang trang hồ sơ).
  const { profile, loading: profileLoading, error: profileError } = useProfile();

  const {
    register,
    handleSubmit,
    reset,
    getValues,
    control,
    formState: { errors },
  } = useForm({ resolver: zodResolver(healthUpdateSchema), defaultValues: emptyValues() });
  const typedTarget = buildNutritionTarget(useWatch({ control }));
  const targetChanged = !sameTarget(typedTarget, previewTarget);

  const requestPreview = (customTarget) => {
    setPreviewTarget(customTarget);
    preview.mutate({ planId: plan.id, customTarget });
  };

  const resetDialog = () => {
    preview.reset();
    reset(emptyValues());
    setPreviewTarget(undefined);
  };

  const openDialog = () => {
    setOpen(true);
    requestPreview(undefined);
  };

  const handleOpenChange = (next) => {
    // Đang lưu thì không cho đóng, tránh người dùng tưởng đã hủy.
    if (apply.isPending) return;
    setOpen(next);
    if (!next) resetDialog();
  };

  const handleApply = async () => {
    try {
      await apply.mutateAsync({
        planId: plan.id,
        customTarget: previewTarget,
        changeSummary: getValues("changeSummary"),
      });
      toast.success("Đã cập nhật thực đơn theo chỉ số sức khỏe mới");
      setOpen(false);
      resetDialog();
    } catch (err) {
      toast.error(err.message);
    }
  };

  const result = preview.data;
  const before = averageDailyTotals(result?.currentPlan);
  const after = averageDailyTotals(result?.proposedPlan);
  const targetLines = targetRangeLines(result?.recalculatedTarget);
  const missedDays = result?.proposedPlan ? countMissedDays({ plan: result.proposedPlan }) : 0;

  return (
    <>
      <Button type="button" variant="outline" size="sm" onClick={openDialog}>
        <HeartPulse className="size-4" />
        Cập nhật theo chỉ số mới
      </Button>

      <Dialog open={open} onOpenChange={handleOpenChange}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Cập nhật theo chỉ số sức khỏe</DialogTitle>
            <DialogDescription>
              Tính lại mục tiêu dinh dưỡng theo chiều cao, cân nặng mới nhất của bạn
              {goalLabel(plan.goalType) && ` và mục tiêu "${goalLabel(plan.goalType)}" của thực đơn`} rồi điều chỉnh khẩu
              phần các món.
            </DialogDescription>
          </DialogHeader>

          {preview.isPending && (
            <p className="flex items-center gap-2 py-6 text-sm text-subtle">
              <Loader2 className="size-4 animate-spin" />
              Đang tính lại thực đơn theo chỉ số mới...
            </p>
          )}

          {preview.isError && (
            <div className="flex flex-col items-start gap-3 rounded-2xl bg-destructive/10 px-4 py-3">
              <p className="text-sm text-destructive">{preview.error.message}</p>
              {[6010, 6020].includes(preview.error.code) && (
                <Link
                  to="/profile/edit"
                  state={profileFixState(profileLoading || profileError ? [] : missingProfileFields(profile))}
                  className="rounded-full bg-brand px-4 py-2 text-xs font-semibold text-brand-foreground transition hover:bg-brand/90"
                >
                  Cập nhật hồ sơ
                </Link>
              )}
              <Button type="button" variant="outline" size="sm" onClick={() => requestPreview(previewTarget)}>
                Thử lại
              </Button>
            </div>
          )}

          {result && (
            <div className="flex flex-col gap-4 text-sm">
              <section>
                <h3 className="font-semibold text-ink">
                  {previewTarget ? "Mục tiêu riêng của bạn mỗi ngày" : "Mục tiêu mỗi ngày sau khi cập nhật"}
                </h3>
                {targetLines.length > 0 ? (
                  <ul className="mt-1 list-inside list-disc text-subtle">
                    {targetLines.map((line) => (
                      <li key={line.key}>
                        {line.label}: {line.range}
                      </li>
                    ))}
                  </ul>
                ) : (
                  <p className="mt-1 text-subtle">Không có mục tiêu cụ thể.</p>
                )}
              </section>

              {before && after && (
                <section>
                  <h3 className="font-semibold text-ink">Trung bình mỗi ngày</h3>
                  <div className="mt-2 overflow-hidden rounded-2xl border border-border">
                    <div className="grid grid-cols-3 bg-surface px-3 py-2 text-xs font-semibold text-subtle">
                      <span />
                      <span className="text-right">Hiện tại</span>
                      <span className="text-right">Sau khi cập nhật</span>
                    </div>
                    {MACRO_ROWS.map((row) => (
                      <div key={row.key} className="grid grid-cols-3 border-t border-border px-3 py-2">
                        <span className="text-body">{row.label}</span>
                        <span className="text-right text-subtle">
                          {formatNumber(before[row.key])} {row.unit}
                        </span>
                        <span className="text-right font-semibold text-ink">
                          {formatNumber(after[row.key])} {row.unit}
                        </span>
                      </div>
                    ))}
                  </div>
                </section>
              )}

              {missedDays > 0 && (
                <p className="rounded-xl bg-warning/10 px-3 py-2 text-warning">
                  {missedDays}/7 ngày vẫn chưa đạt hết mục tiêu mới, bạn xem chi tiết từng ngày sau khi áp dụng.
                </p>
              )}

              <p className="text-xs text-subtle">
                Mục tiêu dinh dưỡng bạn đặt trước đó sẽ được thay bằng mục tiêu mới ở trên. Thực đơn hiện tại được lưu lại
                thành phiên bản cũ.
              </p>
              <p className="rounded-xl bg-warning/10 px-3 py-2 text-xs text-warning">
                Khẩu phần của mọi bữa được tính lại theo mục tiêu mới, nên khẩu phần bạn đã tự chỉnh (nếu có) sẽ bị đặt lại.
                Bản cũ vẫn xem được trong mục Lịch sử.
              </p>
            </div>
          )}

          <form
            onSubmit={handleSubmit((values) => requestPreview(buildNutritionTarget(values)))}
            noValidate
            className="flex flex-col gap-3"
          >
            <p className="text-xs leading-relaxed text-subtle">
              Mặc định mục tiêu được tính từ chỉ số sức khỏe của bạn. Muốn tự đặt mục tiêu riêng thì điền khoảng bên
              dưới rồi xem trước lại. Mục tiêu riêng sẽ thay hoàn toàn mục tiêu tính tự động, chất nào bỏ trống thì
              không bị giới hạn.
            </p>
            <NutritionTargetFields register={register} errors={errors} />
            <div className="flex flex-wrap items-center gap-x-3 gap-y-1">
              <Button
                type="submit"
                variant="outline"
                size="sm"
                disabled={preview.isPending || apply.isPending}
              >
                Xem trước lại
              </Button>
              {targetChanged && (
                <span className="text-xs text-warning">
                  Bạn đã đổi mục tiêu, hãy xem trước lại trước khi áp dụng.
                </span>
              )}
            </div>
          </form>

          <div>
            <label htmlFor={`${plan.id}-health-note`} className="mb-1.5 block text-sm font-semibold text-ink">
              Ghi chú thay đổi <span className="text-xs font-normal text-subtle">(không bắt buộc)</span>
            </label>
            <input
              id={`${plan.id}-health-note`}
              type="text"
              maxLength={HEALTH_UPDATE_LIMITS.changeSummary}
              placeholder="Ví dụ: giảm calo vì đã tăng cân"
              aria-invalid={Boolean(errors.changeSummary)}
              className={noteClass}
              {...register("changeSummary")}
            />
            {errors.changeSummary && <p className="mt-1 text-xs text-destructive">{errors.changeSummary.message}</p>}
            <p className="mt-1 text-xs text-subtle">Hiện trong mục Lịch sử, kèm phiên bản cũ được lưu lại.</p>
          </div>

          <DialogFooter>
            <Button type="button" variant="ghost" disabled={apply.isPending} onClick={() => handleOpenChange(false)}>
              Hủy
            </Button>
            <Button
              type="button"
              disabled={!result || preview.isPending || apply.isPending || targetChanged}
              onClick={handleApply}
            >
              {apply.isPending && <Loader2 className="size-4 animate-spin" />}
              Áp dụng
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}
