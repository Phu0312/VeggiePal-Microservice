import { useMemo, useState } from "react";
import { useForm, useWatch } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Loader2, Plus, TriangleAlert } from "lucide-react";
import { createPortal } from "react-dom";
import { Link } from "react-router-dom";

import { Button } from "@/components/ui/button";
import { healthRecordSchema, updateProfileSchema } from "@/lib/schema";
import CalorieProfileFields from "@/features/profile/components/CalorieProfileFields";
import { useCreateHealthRecord } from "@/features/profile/hooks/useHealthRecords";
import { useProfile, useUpdateProfile } from "@/features/profile/hooks/useProfile";
import {
  errorBoxClass,
  healthInputClass,
  errorTextClass,
  successBoxClass,
} from "@/features/profile/utils/editProfileConstants";

const labelClass = "block text-xs font-semibold text-body mb-1";

// Mọi ô của form (chiều cao, cân nặng, ngày sinh, giới tính, mức vận động) cùng cao h-10 cho đồng nhất; ô chọn dùng
// variant "compact" của SelectField có cùng chiều cao.
const fieldInputClass = `${healthInputClass} h-10`;

// Nút "Ghi nhận" có thể đặt ở nơi khác trong thẻ (xem `submitSlot`) nên liên kết với form bằng id thay vì lồng bên trong.
const FORM_ID = "health-record-form";

// Form dùng tên `birthDate` (như form thông tin cá nhân), API dùng `dateOfBirth`.
const healthFormSchema = healthRecordSchema.extend({
  birthDate: updateProfileSchema.shape.dateOfBirth,
  gender: updateProfileSchema.shape.gender,
  activityLevel: updateProfileSchema.shape.activityLevel,
});

/**
 * Form ghi nhận chiều cao / cân nặng mới (POST /nutrition/me/health-records), kèm ngày sinh, giới tính và mức vận động.
 * Ba trường sau không thuộc bản ghi sức khỏe: BE đọc chúng từ hồ sơ (PATCH /users/me) để tính nhu cầu calo, nên
 * form lưu chúng vào hồ sơ khi người dùng đổi, cùng nguồn với thẻ "Thông tin cá nhân".
 * - Chỉ đổi ngày sinh / giới tính / mức vận động mà chiều cao, cân nặng giữ nguyên thì chỉ cập nhật hồ sơ, không tạo
 *   thêm bản ghi trùng trong lịch sử. Không đổi gì cả thì vẫn ghi nhận một bản ghi mới như trước.
 * - highlightFields: trường hồ sơ BE báo thiếu (xem profileFixState); returnTo / returnLabel: nơi người dùng đến từ
 *   đó, hiện liên kết quay lại sau khi lưu xong.
 * - submitSlot: phần tử DOM (ở đầu thẻ) để đặt nút "Ghi nhận"; nút vẫn thuộc form này (gắn bằng thuộc tính `form`)
 *   nên trạng thái "Đang ghi…" vẫn đúng. Không truyền thì nút nằm ngay cuối form.
 */
export default function EditHealthForm({
  latest,
  highlightFields = [],
  returnTo = null,
  returnLabel = "Quay lại",
  submitSlot = null,
}) {
  const create = useCreateHealthRecord();
  const updateProfile = useUpdateProfile();
  const { profile, loading: profileLoading } = useProfile();
  const [done, setDone] = useState("");

  const savedBirthDate = profile?.dateOfBirth ? String(profile.dateOfBirth).slice(0, 10) : "";
  const savedGender = profile?.gender || "";
  const savedActivityLevel = profile?.activityLevel || "";

  // Điền sẵn từ bản ghi mới nhất và hồ sơ; tự cập nhật sau khi ghi nhận xong và refetch.
  const values = useMemo(
    () => ({
      heightCm: latest?.heightCm ?? "",
      weightKg: latest?.weightKg ?? "",
      birthDate: savedBirthDate,
      gender: savedGender,
      activityLevel: savedActivityLevel,
    }),
    [latest, savedBirthDate, savedGender, savedActivityLevel],
  );

  const form = useForm({
    resolver: zodResolver(healthFormSchema),
    defaultValues: { heightCm: "", weightKg: "", birthDate: "", gender: "", activityLevel: "" },
    values,
  });
  const {
    register,
    handleSubmit,
    setError,
    formState: { errors, isSubmitting },
  } = form;

  // Chưa tải xong hồ sơ thì ô nào cũng đang trống: chưa làm nổi để khỏi nhấp nháy sai. Ô nào điền xong thì hết nổi.
  const activeHighlight = profileLoading ? [] : highlightFields;
  const [birthDate, gender, activityLevel] = useWatch({
    control: form.control,
    name: ["birthDate", "gender", "activityLevel"],
  });
  const stillMissing = activeHighlight.filter((field) => !{ dateOfBirth: birthDate, gender, activityLevel }[field]);

  const submitButton = (
    <Button
      type="submit"
      form={FORM_ID}
      variant="default"
      size="sm"
      disabled={isSubmitting}
      className="rounded-full gap-1.5 px-4 font-semibold shadow-xs cursor-pointer"
    >
      {isSubmitting ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : <Plus className="h-3.5 w-3.5" />}
      {isSubmitting ? "Đang ghi…" : "Ghi nhận"}
    </Button>
  );

  const onSubmit = async (formValues) => {
    setDone("");

    // Chỉ gửi trường đã chọn và khác hồ sơ: BE không nhận giá trị rỗng và không có cách xóa về trống.
    const profileChanges = {};
    if (formValues.birthDate && formValues.birthDate !== savedBirthDate) profileChanges.dateOfBirth = formValues.birthDate;
    if (formValues.gender && formValues.gender !== savedGender) profileChanges.gender = formValues.gender;
    if (formValues.activityLevel && formValues.activityLevel !== savedActivityLevel) {
      profileChanges.activityLevel = formValues.activityLevel;
    }
    const profileChanged = Object.keys(profileChanges).length > 0;
    const measurementsChanged =
      !latest ||
      Number(latest.heightCm) !== Number(formValues.heightCm) ||
      Number(latest.weightKg) !== Number(formValues.weightKg);
    const shouldRecord = measurementsChanged || !profileChanged;

    try {
      // Hồ sơ trước: lỗi ngày sinh / giá trị lạ được báo trước khi tạo bản ghi.
      if (profileChanged) await updateProfile.mutateAsync(profileChanges);
      if (shouldRecord) {
        await create.mutateAsync({ heightCm: formValues.heightCm, weightKg: formValues.weightKg });
      }
      if (shouldRecord && profileChanged) setDone("Đã ghi nhận chỉ số mới và cập nhật hồ sơ.");
      else if (shouldRecord) setDone("Đã ghi nhận chỉ số mới.");
      else setDone("Đã cập nhật thông tin hồ sơ.");
    } catch (err) {
      setError("root", { message: err.message || "Ghi nhận chỉ số thất bại" });
    }
  };

  return (
    <form id={FORM_ID} onSubmit={handleSubmit(onSubmit)} className="flex flex-wrap items-start gap-3.5 mb-4">
      {stillMissing.length > 0 && (
        <p
          role="status"
          className="basis-full flex items-start gap-2 rounded-xl bg-warning/10 px-3 py-2 text-xs text-warning"
        >
          <TriangleAlert className="mt-0.5 size-3.5 shrink-0" />
          Bổ sung các mục được đánh dấu bên dưới để Bé Bông Cải tính được nhu cầu calo cho thực đơn của bạn.
        </p>
      )}

      <div className="flex-1 min-w-[130px]">
        <label htmlFor="edit-heightCm" className={labelClass}>
          Chiều cao (cm)
        </label>
        <input
          id="edit-heightCm"
          type="number"
          step="0.1"
          placeholder="170"
          aria-invalid={Boolean(errors.heightCm)}
          className={fieldInputClass}
          {...register("heightCm")}
        />
        {errors.heightCm && <span className={errorTextClass}>{errors.heightCm.message}</span>}
      </div>

      <div className="flex-1 min-w-[130px]">
        <label htmlFor="edit-weightKg" className={labelClass}>
          Cân nặng (kg)
        </label>
        <input
          id="edit-weightKg"
          type="number"
          step="0.1"
          placeholder="60"
          aria-invalid={Boolean(errors.weightKg)}
          className={fieldInputClass}
          {...register("weightKg")}
        />
        {errors.weightKg && <span className={errorTextClass}>{errors.weightKg.message}</span>}
      </div>

      {/* Ngày sinh hẹp vừa đủ, giới tính hẹp hơn, mức vận động rộng nhất để hiện đủ nhãn dài; cả ba cùng cao h-10. */}
      <CalorieProfileFields
        form={form}
        idPrefix="health"
        highlightFields={activeHighlight}
        inputClass={fieldInputClass}
        labelClass={labelClass}
        className="basis-full grid grid-cols-1 gap-3.5 sm:grid-cols-[1fr_0.75fr_1.4fr]"
      />

      {/* Nút nằm ở đầu thẻ (cạnh nhãn "Cá nhân hóa") nếu thẻ có chỗ chứa, không thì ngay cuối form. */}
      {submitSlot ? createPortal(submitButton, submitSlot) : submitButton}

      {errors.root && <p className={`basis-full ${errorBoxClass}`}>{errors.root.message}</p>}
      {done && !errors.root && (
        <p className={`basis-full ${successBoxClass}`}>
          {done}
          {returnTo && (
            <>
              {" "}
              <Link to={returnTo} className="font-semibold underline underline-offset-2">
                {returnLabel}
              </Link>
            </>
          )}
        </p>
      )}
    </form>
  );
}
