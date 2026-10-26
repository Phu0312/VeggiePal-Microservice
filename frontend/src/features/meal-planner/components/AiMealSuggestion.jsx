import { useId, useState } from "react";
import { zodResolver } from "@hookform/resolvers/zod";
import {
  ArrowRight,
  HeartPulse,
  Leaf,
  Loader2,
  Plus,
  Scale,
  Sparkles,
  TrendingDown,
  TrendingUp,
  Wand2,
  X,
} from "lucide-react";
import { Controller, useForm, useWatch } from "react-hook-form";
import { Link } from "react-router-dom";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import iconChatbot from "@/assets/img/icon_chatbot_1.png";
import GoalCombobox from "@/features/meal-planner/components/GoalCombobox";
import NutritionTargetCard from "@/features/meal-planner/components/NutritionTargetCard";
import NutritionTargetFields from "@/features/meal-planner/components/NutritionTargetFields";
import { flavorPreferences, healthGoalSuggestions } from "@/features/meal-planner/data/mockMealPlanner";
import { useCreateMealPlan } from "@/features/meal-planner/hooks/useMealPlanMutations";
import { useNutritionTarget } from "@/features/meal-planner/hooks/useMealPlans";
import { MEAL_PLAN_LIMITS, mealPlanSchema } from "@/features/meal-planner/schema";
import {
  buildGeneratePayload,
  buildNutritionTarget,
  countMissedDays,
  defaultPlanName,
  GOAL_OPTIONS,
  missingProfileFields,
  profileFixState,
  profileTargetIssue,
  TARGET_FIELDS,
} from "@/features/meal-planner/utils/mealPlan";
import { useMySubscription } from "@/features/payment/hooks/useMySubscription";
import { PLAN_DETAILS } from "@/features/payment/utils/paymentFormat";
import { useLatestHealthRecord } from "@/features/profile/hooks/useHealthRecords";
import { useProfile } from "@/features/profile/hooks/useProfile";
import IngredientPicker from "@/features/recipe/components/IngredientPicker";
import { cn } from "@/lib/utils";

const fieldClass =
  "w-full rounded-xl border border-border bg-card px-3.5 text-sm text-ink outline-none transition placeholder:text-subtle focus:border-brand/40 focus:ring-2 focus:ring-brand/15 aria-[invalid=true]:border-destructive/50 aria-[invalid=true]:ring-2 aria-[invalid=true]:ring-destructive/20";
const labelClass = "mb-1.5 block text-sm font-semibold text-ink";
const errorClass = "mt-1.5 text-xs text-destructive";

function emptyTarget() {
  return Object.fromEntries(TARGET_FIELDS.map((field) => [field, ""]));
}

const GOAL_ICONS = { LOSE: TrendingDown, MAINTAIN: Scale, GAIN: TrendingUp };

// BE từ chối chắc chắn (hồ sơ thiếu thông tin / dưới 18 tuổi) khi phải tự tính mục tiêu: khóa nút thay vì để người
// dùng bấm rồi mới thấy lỗi (mã này là lỗi BE trả về khi hồ sơ đã đổi sau lần kiểm tra ở FE). Có mục tiêu tự đặt
// thì BE không đọc hồ sơ nên không bị chặn.
const AUTO_TARGET_BLOCKING_CODES = new Set([6020, 6021]);

/**
 * Form nhờ AI lên thực đơn 7 ngày (POST /ai/meal-plans).
 * - Mục tiêu (giảm / duy trì / tăng cân) là `goalType` bắt buộc; ô "Mô tả thêm" là tùy chọn và được ghép vào `healthGoal`.
 * - Mục tiêu dinh dưỡng mỗi ngày: mặc định BE tự tính từ hồ sơ (thẻ NutritionTargetCard cho xem trước); điền các ô
 *   "Tự đặt mục tiêu riêng" thì gửi `dailyNutritionTarget` thay thế.
 * - Nguyên liệu có sẵn: chọn từ danh mục nguyên liệu; BE chỉ ưu tiên các món dùng chúng (không loại món khác).
 * - Cần có chỉ số sức khỏe (chiều cao, cân nặng) mới tạo được thực đơn: thiếu thì khóa nút và dẫn tới hồ sơ.
 * - Khẩu vị: gửi nhãn các lựa chọn đang bật qua `preferences`.
 * - Tên, mục tiêu, mô tả, mục tiêu dinh dưỡng: react-hook-form + zod.
 * `onCreated(plan)` được gọi khi tạo xong để trang chuyển sang xem thực đơn mới.
 */
export default function AiMealSuggestion({ onCreated }) {
  const idPrefix = useId();
  const createPlan = useCreateMealPlan();
  // BE trả lỗi 6010 nếu chưa có bản ghi sức khỏe nên chặn sớm. Chỉ khóa khi chắc chắn là chưa có
  // (đã tải xong, không lỗi); nếu không tải được thì vẫn cho thử, BE sẽ là bên quyết định.
  const healthRecord = useLatestHealthRecord();
  const missingHealthRecord = !healthRecord.isPending && !healthRecord.isError && healthRecord.data == null;
  // Gói quy định số thực đơn được tạo mỗi tháng (BE báo lỗi 6003 khi hết). Chưa biết gói (đang tải / lỗi) thì
  // không chặn, để BE quyết định; BE chưa có API số lượt đã dùng nên chỉ hiện được tổng lượt của gói.
  const { subscription } = useMySubscription();
  const noQuota = subscription?.mealPlansPerMonth === 0;

  const [ingredients, setIngredients] = useState([]);
  const [pickerOpen, setPickerOpen] = useState(false);
  const [activePrefs, setActivePrefs] = useState(() => new Set());
  const [targetOpen, setTargetOpen] = useState(false);

  const {
    register,
    handleSubmit,
    control,
    setValue,
    formState: { errors },
  } = useForm({
    resolver: zodResolver(mealPlanSchema),
    defaultValues: { name: defaultPlanName(), goalType: "", healthNote: "", ...emptyTarget() },
  });

  const watched = useWatch({ control });
  const customTarget = buildNutritionTarget(watched);

  // Hồ sơ thiếu ngày sinh / giới tính / mức vận động hoặc dưới 18 tuổi thì BE chắc chắn từ chối mục tiêu tự tính
  // (6020 / 6021): báo ngay, không gọi API. Hồ sơ chưa tải xong hoặc tải lỗi thì chưa kết luận, để BE quyết định.
  const { profile, loading: profileLoading, error: profileError } = useProfile();
  const profileIssue = profileLoading || profileError ? null : profileTargetIssue(profile);
  const missingFields = profileLoading || profileError ? [] : missingProfileFields(profile);

  // Cùng khóa với thẻ NutritionTargetCard nên chỉ gọi API một lần.
  const autoTarget = useNutritionTarget(watched.goalType, !missingHealthRecord && !profileIssue);
  const autoTargetBlocked =
    !customTarget && (Boolean(profileIssue) || AUTO_TARGET_BLOCKING_CODES.has(autoTarget.error?.code));

  // Điền mục tiêu BE tính được vào các ô "tự đặt riêng" (mở sẵn phần đó) để người dùng chỉnh tiếp.
  const fillCustomTarget = (target) => {
    for (const field of TARGET_FIELDS) {
      setValue(field, target?.[field] == null ? "" : String(target[field]), { shouldDirty: true, shouldValidate: true });
    }
    setTargetOpen(true);
  };

  // Xóa mọi ô để quay lại mục tiêu BE tự tính.
  const clearCustomTarget = () => {
    for (const field of TARGET_FIELDS) setValue(field, "", { shouldDirty: true, shouldValidate: true });
  };

  const togglePreference = (id) => {
    setActivePrefs((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const addIngredient = (ingredient) => {
    setIngredients((prev) =>
      prev.length >= MEAL_PLAN_LIMITS.ingredients || prev.some((item) => item.id === ingredient.id)
        ? prev
        : [...prev, { id: ingredient.id, name: ingredient.name }],
    );
  };

  const removeIngredient = (id) => {
    setIngredients((prev) => prev.filter((item) => item.id !== id));
  };

  const onSubmit = async (values) => {
    const { name, goalType, healthNote, ...target } = values;
    const payload = buildGeneratePayload({
      name,
      goalType,
      healthNote,
      preferences: flavorPreferences.filter((pref) => activePrefs.has(pref.id)).map((pref) => pref.label),
      ingredients: ingredients.map((item) => item.name),
      target,
    });

    try {
      const plan = await createPlan.mutateAsync(payload);
      const missedDays = countMissedDays(plan);
      if (missedDays > 0) {
        toast.warning(
          `Thực đơn đã xong, nhưng ${missedDays}/7 ngày chưa đạt mục tiêu dinh dưỡng. Bạn xem chi tiết ở từng ngày nhé.`,
        );
      } else {
        toast.success("Bé Bông Cải đã lên xong thực đơn cho bạn!");
      }
      onCreated?.(plan);
    } catch (error) {
      toast.error(error.message);
    }
  };

  const isCreating = createPlan.isPending;

  return (
    <section id="ai-suggestion" className="relative scroll-mt-28 rounded-[28px] bg-card p-6 shadow-lg sm:p-8">
      <form onSubmit={handleSubmit(onSubmit)} noValidate>
        <div className="relative flex flex-col items-center text-center">
          <span className="inline-flex items-center gap-1.5 rounded-full bg-brand-soft px-3 py-1 text-base font-semibold text-brand">
            <Sparkles className="h-3.5 w-3.5" />
            AI Gợi Ý Thực Đơn
          </span>
          <h2 className="mt-3 text-xl font-bold text-ink sm:text-2xl">
            Hôm nay tủ lạnh nhà bạn có nguyên liệu tươi nào?
          </h2>
          <p className="mt-2 max-w-xl text-sm text-subtle">
            Bé Bông Cải sẽ kết hợp các loại rau củ sẵn có để thiết kế thực đơn thuần thực vật chuẩn cân bằng vi
            chất.
          </p>
        </div>

        <div className="relative mt-7 flex flex-col items-center gap-6 lg:flex-row lg:items-center">
          <div className="relative shrink-0">
            <img
              src={iconChatbot}
              alt="Bé Bông Cải gợi ý thực đơn"
              className="mt-2 h-72 w-auto select-none sm:h-72"
              draggable={false}
            />
          </div>

          <div className="flex min-h-[300px] w-full flex-1 flex-col justify-center gap-2 rounded-2xl bg-surface p-6 sm:p-8">
            <div className="flex items-center justify-between">
              <h3 className="text-base font-semibold text-ink">Nguyên liệu có sẵn trong bếp:</h3>
              <button
                type="button"
                onClick={() => setPickerOpen((open) => !open)}
                aria-expanded={pickerOpen}
                className="flex items-center gap-1 text-xs font-semibold text-brand hover:underline"
              >
                {pickerOpen ? <X className="h-3.5 w-3.5" /> : <Plus className="h-3.5 w-3.5" />}
                {pickerOpen ? "Đóng" : "Thêm món mới"}
              </button>
            </div>

            <div className="mt-1 flex flex-wrap gap-2">
              {ingredients.map((item) => (
                <span
                  key={item.id}
                  className="flex items-center gap-2 rounded-full bg-card px-3 py-1.5 text-xs font-medium text-ink shadow-sm"
                >
                  <span className="grid size-5 shrink-0 place-items-center rounded-full bg-brand-soft text-brand">
                    <Leaf className="size-3" />
                  </span>
                  {item.name}
                  <button
                    type="button"
                    onClick={() => removeIngredient(item.id)}
                    aria-label={`Bỏ ${item.name}`}
                    className="grid size-4 shrink-0 place-items-center rounded-full text-subtle transition hover:bg-surface hover:text-ink"
                  >
                    <X className="h-3 w-3" />
                  </button>
                </span>
              ))}
              {ingredients.length === 0 && (
                <span className="text-xs text-subtle">
                  Chưa chọn nguyên liệu nào. Chọn để Bé Bông Cải ưu tiên các món dùng chúng, bỏ trống nếu bạn không cần.
                </span>
              )}
            </div>
            {ingredients.length > 0 && (
              <p className="text-xs text-subtle">
                Món dùng nhiều nguyên liệu này sẽ được ưu tiên, các món khác vẫn có thể xuất hiện trong thực đơn.
              </p>
            )}

            {pickerOpen && (
              // Enter trong ô tìm nguyên liệu không được gửi cả form (sẽ kích hoạt tạo thực đơn ngoài ý muốn).
              <div
                className="mt-1"
                onKeyDown={(event) => {
                  if (event.key === "Enter") event.preventDefault();
                }}
              >
                <IngredientPicker selectedIds={ingredients.map((item) => item.id)} onPick={addIngredient} />
              </div>
            )}

            <h3 className="mt-3 text-base font-semibold text-ink">Gợi ý món & khẩu vị mong muốn:</h3>
            {/* Một hàng duy nhất: chip gọn lại để vừa khung, màn hẹp hơn thì kéo ngang thay vì xuống dòng. */}
            <div className="mt-1 flex flex-nowrap gap-1.5 overflow-x-auto p-0.5 pb-1.5">
              {flavorPreferences.map((pref) => {
                const active = activePrefs.has(pref.id);
                return (
                  <button
                    key={pref.id}
                    type="button"
                    onClick={() => togglePreference(pref.id)}
                    aria-pressed={active}
                    className={cn(
                      "flex shrink-0 items-center gap-1.5 whitespace-nowrap rounded-full px-2.5 py-1.5 text-xs font-medium transition",
                      active ? "bg-brand text-brand-foreground" : "bg-card text-ink ring-1 ring-border hover:bg-surface",
                    )}
                  >
                    <span
                      className={cn(
                        "grid size-4 shrink-0 place-items-center rounded-full text-[10px] leading-none",
                        active && "bg-white/20",
                      )}
                    >
                      <pref.icon className="size-2.5" />
                    </span>
                    {pref.label}
                  </button>
                );
              })}
            </div>

            <div className="mt-4">
              <span id={`${idPrefix}-goal-type`} className={labelClass}>
                Mục tiêu của thực đơn
              </span>
              <Controller
                name="goalType"
                control={control}
                render={({ field }) => (
                  <div
                    role="radiogroup"
                    aria-labelledby={`${idPrefix}-goal-type`}
                    aria-invalid={Boolean(errors.goalType)}
                    className="grid grid-cols-1 gap-2 sm:grid-cols-3"
                  >
                    {GOAL_OPTIONS.map((option) => {
                      const Icon = GOAL_ICONS[option.value];
                      const active = field.value === option.value;
                      return (
                        <button
                          key={option.value}
                          type="button"
                          role="radio"
                          aria-checked={active}
                          onClick={() => field.onChange(option.value)}
                          onBlur={field.onBlur}
                          className={cn(
                            "flex items-center gap-3 rounded-2xl px-3.5 py-3 text-left transition",
                            active
                              ? "bg-brand text-brand-foreground shadow-sm"
                              : "bg-card text-ink ring-1 ring-border hover:bg-surface",
                            errors.goalType && !active && "ring-destructive/50",
                          )}
                        >
                          <Icon className="size-5 shrink-0" />
                          <span className="flex min-w-0 flex-col">
                            <span className="text-sm font-semibold">{option.label}</span>
                            <span className={cn("text-xs", active ? "text-brand-foreground/80" : "text-subtle")}>
                              {option.hint}
                            </span>
                          </span>
                        </button>
                      );
                    })}
                  </div>
                )}
              />
              {errors.goalType && <p className={errorClass}>{errors.goalType.message}</p>}
            </div>

            <div className="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-2">
              <div>
                <label htmlFor={`${idPrefix}-name`} className={labelClass}>
                  Tên thực đơn
                </label>
                <input
                  id={`${idPrefix}-name`}
                  type="text"
                  maxLength={MEAL_PLAN_LIMITS.name}
                  aria-invalid={Boolean(errors.name)}
                  className={cn(fieldClass, "h-11")}
                  {...register("name")}
                />
                {errors.name && <p className={errorClass}>{errors.name.message}</p>}
              </div>

              <div>
                <label htmlFor={`${idPrefix}-note`} className={labelClass}>
                  Mô tả thêm <span className="text-xs font-normal text-subtle">(không bắt buộc)</span>
                </label>
                <Controller
                  name="healthNote"
                  control={control}
                  render={({ field }) => (
                    <GoalCombobox
                      id={`${idPrefix}-note`}
                      value={field.value}
                      onChange={field.onChange}
                      onBlur={field.onBlur}
                      inputRef={field.ref}
                      options={healthGoalSuggestions}
                      maxLength={MEAL_PLAN_LIMITS.healthNote}
                      placeholder="Ví dụ: tăng cơ, ăn thanh đạm..."
                      aria-invalid={Boolean(errors.healthNote)}
                      className={cn(fieldClass, "h-11")}
                    />
                  )}
                />
                {errors.healthNote && <p className={errorClass}>{errors.healthNote.message}</p>}
              </div>
            </div>

            <div className="mt-2">
              <NutritionTargetCard
                goalType={watched.goalType}
                enabled={!missingHealthRecord}
                profileIssue={profileIssue}
                missingFields={missingFields}
                overridden={Boolean(customTarget)}
                onUseTarget={fillCustomTarget}
                onClearTarget={clearCustomTarget}
              />
            </div>

            <div className="mt-2">
              <NutritionTargetFields
                register={register}
                errors={errors}
                replacesAuto
                open={targetOpen}
                onOpenChange={setTargetOpen}
              />
            </div>
          </div>
        </div>

        {missingHealthRecord && (
          <div
            role="alert"
            className="relative mt-7 flex flex-col items-start gap-3 rounded-2xl bg-warning/10 p-4 text-sm text-ink sm:flex-row sm:items-center sm:justify-between"
          >
            <p className="flex items-start gap-2">
              <HeartPulse className="mt-0.5 size-4 shrink-0 text-warning" />
              <span>
                Bạn chưa có chỉ số sức khỏe. Hãy cập nhật chiều cao và cân nặng để Bé Bông Cải lên thực đơn phù hợp với bạn.
              </span>
            </p>
            <Link
              to="/profile/edit"
              state={profileFixState(missingFields)}
              className="shrink-0 rounded-full bg-brand px-4 py-2 text-xs font-semibold text-brand-foreground transition hover:bg-brand/90"
            >
              Cập nhật hồ sơ
            </Link>
          </div>
        )}

        {noQuota && (
          <div
            role="alert"
            className="relative mt-7 flex flex-col items-start gap-3 rounded-2xl bg-warning/10 p-4 text-sm text-ink sm:flex-row sm:items-center sm:justify-between"
          >
            <p>Gói hiện tại của bạn chưa có lượt tạo thực đơn. Nâng cấp lên gói PLUS hoặc PRO để dùng tính năng này.</p>
            <Link
              to="/pricing"
              className="shrink-0 rounded-full bg-brand px-4 py-2 text-xs font-semibold text-brand-foreground transition hover:bg-brand/90"
            >
              Xem các gói thành viên
            </Link>
          </div>
        )}

        <div className={cn("relative flex flex-col items-center gap-4 rounded-2xl bg-surface p-4 sm:flex-row sm:items-center sm:justify-between sm:gap-6", missingHealthRecord || noQuota ? "mt-3" : "mt-7")}>
          <p className="flex items-center gap-2 text-center text-xs text-subtle sm:text-left">
            <Wand2 className="h-4 w-4 shrink-0 text-brand" />
            {isCreating
              ? "Bé Bông Cải đang cân đối 7 ngày × 3 bữa cho bạn, việc này có thể mất khoảng một phút."
              : "Thuật toán AI tự động tối ưu hoá tỷ lệ Axit Amin hoàn chỉnh từ thực vật"}
          </p>
          <Button
            type="submit"
            size="lg"
            disabled={isCreating || missingHealthRecord || noQuota || autoTargetBlocked}
            className="h-auto min-h-11 w-full whitespace-normal px-6 py-2.5 shadow-sm sm:w-auto"
          >
            {isCreating ? <Loader2 className="size-4 animate-spin" /> : <Sparkles className="size-4" />}
            {isCreating ? "Đang lên thực đơn..." : "Nhờ Bé Bông Cải Lên Thực Đơn Mới"}
            {!isCreating && <ArrowRight className="size-4" />}
          </Button>
        </div>

        {subscription && !noQuota && (
          <p className="relative mt-3 text-center text-xs text-subtle">
            {PLAN_DETAILS[subscription.planCode]?.name ?? subscription.planCode}: tối đa {subscription.mealPlansPerMonth}{" "}
            thực đơn mỗi tháng.
            {subscription.planCode !== "PRO" && (
              <>
                {" "}
                <Link to="/pricing" className="font-semibold text-brand underline underline-offset-2">
                  Nâng cấp để tạo nhiều hơn
                </Link>
              </>
            )}
          </p>
        )}
      </form>
    </section>
  );
}
