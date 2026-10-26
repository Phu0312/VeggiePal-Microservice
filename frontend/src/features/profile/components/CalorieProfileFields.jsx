import { Controller, useWatch } from "react-hook-form";

import {
  ACTIVITY_LEVEL_OPTIONS,
  errorTextClass,
  GENDER_OPTIONS,
} from "@/features/profile/utils/editProfileConstants";
import SelectField from "@/shared/components/SelectField";

const needClass = "mt-1 block text-[11px] text-warning";

/**
 * Ba trường hồ sơ BE dùng để tính nhu cầu calo của thực đơn: ngày sinh, giới tính, mức độ vận động.
 * Nằm trong form chỉ số sức khỏe (EditHealthForm) cùng chiều cao, cân nặng vì BE dùng chung cả năm giá trị để tính
 * nhu cầu calo; form cần có field `birthDate` / `gender` / `activityLevel`.
 * - form: đối tượng của useForm (register, control, formState.errors).
 * - idPrefix: tiền tố id của các ô (id = `${idPrefix}-birthDate`...).
 * - highlightFields: trường (tên field của GET /users/me: "dateOfBirth" | "gender" | "activityLevel") cần làm nổi vì
 *   BE báo thiếu; mỗi trường chỉ nổi khi còn trống và hết nổi ngay khi người dùng điền.
 * - inputClass / labelClass / className: giữ kiểu của form chứa nó.
 */
export default function CalorieProfileFields({
  form,
  idPrefix,
  highlightFields = [],
  inputClass,
  labelClass,
  className,
}) {
  const {
    control,
    register,
    formState: { errors },
  } = form;
  const [birthDate, gender, activityLevel] = useWatch({ control, name: ["birthDate", "gender", "activityLevel"] });

  const needs = {
    birthDate: highlightFields.includes("dateOfBirth") && !birthDate,
    gender: highlightFields.includes("gender") && !gender,
    activityLevel: highlightFields.includes("activityLevel") && !activityLevel,
  };

  return (
    <div className={className}>
      <div>
        <label htmlFor={`${idPrefix}-birthDate`} className={labelClass}>
          Ngày sinh
        </label>
        <input
          id={`${idPrefix}-birthDate`}
          type="date"
          autoComplete="bday"
          aria-invalid={Boolean(errors.birthDate) || needs.birthDate}
          className={inputClass}
          {...register("birthDate")}
        />
        {errors.birthDate && <span className={errorTextClass}>{errors.birthDate.message}</span>}
        {!errors.birthDate && needs.birthDate && <span className={needClass}>Cần bổ sung để tính nhu cầu calo</span>}
      </div>

      <div>
        <label htmlFor={`${idPrefix}-gender`} className={labelClass}>
          Giới tính
        </label>
        <Controller
          name="gender"
          control={control}
          render={({ field }) => (
            <SelectField
              id={`${idPrefix}-gender`}
              variant="compact"
              options={GENDER_OPTIONS}
              value={field.value}
              onValueChange={field.onChange}
              onBlur={field.onBlur}
              placeholder="Chọn giới tính"
              aria-invalid={Boolean(errors.gender) || needs.gender}
            />
          )}
        />
        {errors.gender && <span className={errorTextClass}>{errors.gender.message}</span>}
        {!errors.gender && needs.gender && <span className={needClass}>Cần bổ sung để tính nhu cầu calo</span>}
      </div>

      <div>
        <label htmlFor={`${idPrefix}-activityLevel`} className={labelClass}>
          Mức độ vận động
        </label>
        <Controller
          name="activityLevel"
          control={control}
          render={({ field }) => (
            <SelectField
              id={`${idPrefix}-activityLevel`}
              variant="compact"
              options={ACTIVITY_LEVEL_OPTIONS}
              value={field.value}
              onValueChange={field.onChange}
              onBlur={field.onBlur}
              placeholder="Chọn mức độ vận động"
              aria-invalid={Boolean(errors.activityLevel) || needs.activityLevel}
            />
          )}
        />
        {errors.activityLevel && <span className={errorTextClass}>{errors.activityLevel.message}</span>}
        {!errors.activityLevel && needs.activityLevel && (
          <span className={needClass}>Cần bổ sung để tính nhu cầu calo</span>
        )}
      </div>

      <span className="block text-[10px] text-subtle sm:col-span-3">
        Ngày sinh, giới tính và mức vận động dùng để tính nhu cầu calo khi lên thực đơn.
      </span>
    </div>
  );
}
