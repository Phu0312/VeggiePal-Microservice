import { useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Check, Clock, Loader2, Pencil, X } from "lucide-react";

import { Button } from "@/components/ui/button";
import { useUpdateHealthRecord } from "@/features/profile/hooks/useHealthRecords";
import {
  errorBoxClass,
  errorTextClass,
  healthInputClass,
} from "@/features/profile/utils/editProfileConstants";
import { formatDt } from "@/features/profile/utils/editProfileHelpers";
import { healthRecordSchema } from "@/lib/schema";

/** Form sửa tại chỗ một dòng lịch sử. Chỉ đổi chiều cao / cân nặng; thời điểm ghi nhận do BE giữ nguyên. */
function HealthRecordRowEditor({ record, onDone }) {
  const update = useUpdateHealthRecord();
  const {
    register,
    handleSubmit,
    setError,
    formState: { errors, isSubmitting },
  } = useForm({
    resolver: zodResolver(healthRecordSchema),
    defaultValues: { heightCm: record.heightCm ?? "", weightKg: record.weightKg ?? "" },
  });

  const onSubmit = async (values) => {
    try {
      await update.mutateAsync({ id: record.id, heightCm: values.heightCm, weightKg: values.weightKg });
      onDone();
    } catch (err) {
      setError("root", { message: err.message || "Cập nhật chỉ số thất bại" });
    }
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="flex w-full flex-wrap items-start gap-2.5">
      <div className="min-w-[110px] flex-1">
        <label htmlFor={`history-height-${record.id}`} className="mb-1 block text-[11px] font-semibold text-body">
          Chiều cao (cm)
        </label>
        <input
          id={`history-height-${record.id}`}
          type="number"
          step="0.1"
          aria-invalid={Boolean(errors.heightCm)}
          className={healthInputClass}
          {...register("heightCm")}
        />
        {errors.heightCm && <span className={errorTextClass}>{errors.heightCm.message}</span>}
      </div>
      <div className="min-w-[110px] flex-1">
        <label htmlFor={`history-weight-${record.id}`} className="mb-1 block text-[11px] font-semibold text-body">
          Cân nặng (kg)
        </label>
        <input
          id={`history-weight-${record.id}`}
          type="number"
          step="0.1"
          aria-invalid={Boolean(errors.weightKg)}
          className={healthInputClass}
          {...register("weightKg")}
        />
        {errors.weightKg && <span className={errorTextClass}>{errors.weightKg.message}</span>}
      </div>
      <div className="mt-5 flex gap-1.5">
        <Button type="submit" size="sm" disabled={isSubmitting} className="gap-1 rounded-xl">
          {isSubmitting ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : <Check className="h-3.5 w-3.5" />}
          Lưu
        </Button>
        <Button type="button" size="sm" variant="outline" disabled={isSubmitting} onClick={onDone} className="gap-1 rounded-xl">
          <X className="h-3.5 w-3.5" />
          Hủy
        </Button>
      </div>
      {errors.root && <p className={`basis-full ${errorBoxClass}`}>{errors.root.message}</p>}
    </form>
  );
}

/** Lịch sử ghi nhận gần đây; chỉ báo "chưa có bản ghi" khi danh sách rỗng. Mỗi dòng có nút "Sửa". */
export default function EditHealthHistory({ history }) {
  const [editingId, setEditingId] = useState(null);

  return (
    <div className="text-[11px] text-subtle pt-2 border-t border-border">
      <div className="flex items-center gap-1.5">
        <Clock className="h-3.5 w-3.5" />
        <span>
          {history.length === 0 ? "Lịch sử gần đây: Chưa có bản ghi nào." : "Lịch sử gần đây:"}
        </span>
      </div>
      {history.length > 0 && (
        <ul className="mt-2 divide-y divide-border overflow-hidden rounded-2xl border border-border">
          {history.map((r) => (
            <li
              key={r.id}
              className="flex flex-wrap items-center justify-between gap-2 bg-surface/50 px-3.5 py-2.5 text-xs"
            >
              {editingId === r.id ? (
                <HealthRecordRowEditor record={r} onDone={() => setEditingId(null)} />
              ) : (
                <>
                  <span className="text-subtle">{formatDt(r.recordedAt)}</span>
                  <span className="font-medium text-ink">
                    {r.heightCm} cm · {r.weightKg} kg · BMI{" "}
                    {r.bmi != null ? Number(r.bmi).toFixed(1) : "—"}
                  </span>
                  <Button
                    type="button"
                    size="sm"
                    variant="outline"
                    aria-label={`Sửa bản ghi ${formatDt(r.recordedAt)}`}
                    onClick={() => setEditingId(r.id)}
                    className="h-7 gap-1 rounded-xl px-2.5 text-[11px]"
                  >
                    <Pencil className="h-3 w-3" />
                    Sửa
                  </Button>
                </>
              )}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
