import { Link } from "react-router-dom";
import { Calculator, Loader2 } from "lucide-react";

import { Button } from "@/components/ui/button";
import { useNutritionTarget } from "@/features/meal-planner/hooks/useMealPlans";
import { goalLabel, profileFixState, targetRangeLines } from "@/features/meal-planner/utils/mealPlan";

const formatNumber = (value) => Number(value).toLocaleString("vi-VN");

// Lỗi do hồ sơ thiếu thông tin: người dùng sửa được ở trang chỉnh sửa hồ sơ.
const PROFILE_FIX_CODES = new Set([6010, 6020]);

// Hồ sơ không đủ điều kiện để BE tự tính (xem profileTargetIssue): báo ngay, khỏi gọi API chờ BE từ chối.
const PROFILE_ISSUE_MESSAGES = {
  incomplete: "Bạn cần cập nhật ngày sinh, giới tính và mức độ vận động trong hồ sơ để tính nhu cầu calo",
  underage: "Mục tiêu calo tự tính hiện chỉ dành cho người từ 18 tuổi trở lên. Bạn có thể tự đặt mục tiêu dinh dưỡng riêng",
};

const fixLinkClass =
  "shrink-0 rounded-full bg-brand px-3.5 py-1.5 text-xs font-semibold text-brand-foreground transition hover:bg-brand/90";

/**
 * Thẻ "Mục tiêu dinh dưỡng gợi ý" theo mục tiêu đã chọn (GET /ai/meal-plans/nutrition-target): nhu cầu cơ bản (BMR),
 * tiêu hao mỗi ngày (TDEE), calo mục tiêu và khoảng đạm / tinh bột / béo. BE tự tính từ chỉ số sức khỏe + ngày sinh,
 * giới tính, mức vận động nên không cần FE tính lại.
 * - `goalType`: mục tiêu đang chọn (rỗng thì thẻ nhắc chọn mục tiêu).
 * - `enabled`: false khi biết chắc chưa có chỉ số sức khỏe (form đã có cảnh báo riêng cho trường hợp đó).
 * - `profileIssue`: "incomplete" | "underage" | null, kết quả của profileTargetIssue; có thì không gọi API.
 * - `missingFields`: trường hồ sơ còn trống (missingProfileFields), gắn vào liên kết "Cập nhật hồ sơ" để trang hồ sơ
 *   làm nổi đúng các ô đó và cho người dùng quay lại thực đơn sau khi lưu.
 * - `overridden`: người dùng đang tự đặt mục tiêu riêng nên thẻ này chỉ để tham khảo.
 * - `onUseTarget(target)`: điền mục tiêu gợi ý vào các ô "tự đặt riêng" để chỉnh tiếp (nút chỉ hiện khi có hàm này).
 * - `onClearTarget()`: xóa mục tiêu riêng để quay lại mục tiêu tự tính (nút chỉ hiện khi đang `overridden`).
 * Form cha cũng gọi `useNutritionTarget` cùng khóa để biết khi nào BE chắc chắn từ chối; React Query dùng chung một
 * lần gọi API cho cả hai nơi.
 */
export default function NutritionTargetCard({
  goalType,
  enabled = true,
  profileIssue = null,
  missingFields = [],
  overridden = false,
  onUseTarget,
  onClearTarget,
}) {
  const { data, isPending, isFetching, error } = useNutritionTarget(goalType, enabled && !profileIssue);
  const lines = targetRangeLines(data?.target);

  return (
    <section className="rounded-2xl bg-card p-4 ring-1 ring-border" aria-live="polite">
      <h4 className="flex items-center gap-2 text-sm font-semibold text-ink">
        <Calculator className="size-4 text-brand" />
        Mục tiêu dinh dưỡng gợi ý cho bạn
        {goalType && <span className="text-xs font-normal text-subtle">({goalLabel(goalType)})</span>}
      </h4>

      {!goalType && (
        <p className="mt-2 text-xs text-subtle">Chọn mục tiêu của thực đơn để xem lượng calo mỗi ngày phù hợp với bạn.</p>
      )}

      {goalType && profileIssue && (
        <div className="mt-2 flex flex-col items-start gap-2 text-xs text-destructive sm:flex-row sm:items-center sm:justify-between">
          <p>{PROFILE_ISSUE_MESSAGES[profileIssue]}</p>
          {profileIssue === "incomplete" && (
            <Link to="/profile/edit" state={profileFixState(missingFields)} className={fixLinkClass}>
              Cập nhật hồ sơ
            </Link>
          )}
        </div>
      )}

      {goalType && !profileIssue && !enabled && (
        <p className="mt-2 text-xs text-subtle">Cập nhật chiều cao và cân nặng trong hồ sơ để xem mục tiêu gợi ý.</p>
      )}

      {goalType && !profileIssue && enabled && isPending && !error && (
        <p className="mt-2 flex items-center gap-2 text-xs text-subtle">
          <Loader2 className="size-3.5 animate-spin" />
          Đang tính mục tiêu của bạn...
        </p>
      )}

      {goalType && !profileIssue && error && (
        <div className="mt-2 flex flex-col items-start gap-2 text-xs text-destructive sm:flex-row sm:items-center sm:justify-between">
          <p>{error.message}</p>
          {PROFILE_FIX_CODES.has(error.code) && (
            <Link to="/profile/edit" state={profileFixState(missingFields)} className={fixLinkClass}>
              Cập nhật hồ sơ
            </Link>
          )}
        </div>
      )}

      {goalType && !profileIssue && data && (
        <div className={isFetching ? "opacity-60 transition" : "transition"}>
          <p className="mt-2 text-xs text-subtle">
            Nhu cầu cơ bản (BMR) {formatNumber(data.bmr)} kcal · Tiêu hao mỗi ngày (TDEE) {formatNumber(data.tdee)} kcal
          </p>
          <p className="mt-1 text-sm font-semibold text-ink">
            Calo mục tiêu: {formatNumber(data.targetCalories)} kcal/ngày
          </p>
          <ul className="mt-1 list-inside list-disc text-xs text-subtle">
            {lines.map((line) => (
              <li key={line.key}>
                {line.label}: {line.range}
              </li>
            ))}
          </ul>
          {!overridden && onUseTarget && (
            <Button type="button" variant="outline" size="sm" className="mt-3" onClick={() => onUseTarget(data.target)}>
              Dùng làm mục tiêu riêng để chỉnh
            </Button>
          )}
        </div>
      )}

      {goalType && overridden && (
        <div className="mt-2 flex flex-col items-start gap-2 rounded-xl bg-warning/10 px-3 py-2 text-xs text-warning sm:flex-row sm:items-center sm:justify-between">
          <p>Bạn đang tự đặt mục tiêu riêng bên dưới nên thực đơn sẽ không dùng mục tiêu gợi ý này.</p>
          {onClearTarget && (
            <Button type="button" variant="outline" size="sm" className="shrink-0" onClick={onClearTarget}>
              Quay lại mục tiêu tự tính
            </Button>
          )}
        </div>
      )}

      <p className="mt-3 text-[11px] leading-relaxed text-subtle">
        Mục tiêu calo chỉ là gợi ý, không thay thế tư vấn của chuyên gia dinh dưỡng.
      </p>
    </section>
  );
}
