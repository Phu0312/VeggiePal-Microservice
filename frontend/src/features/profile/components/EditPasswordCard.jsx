import { useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { ChevronDown, ChevronUp, Eye, EyeOff, Loader2, Lock } from "lucide-react";

import { changePasswordSchema } from "@/lib/schema";
import { useChangePassword } from "@/features/profile/hooks/useProfile";
import { Button } from "@/components/ui/button";
import {
  accordionBodyClass,
  accordionHeaderClass,
  cardClass,
  errorBoxClass,
  errorTextClass,
  iconBoxClass,
  inputClass,
  labelClass,
  successBoxClass,
} from "@/features/profile/utils/editProfileConstants";

/** Accordion "Đổi mật khẩu" — tự quản lý form + mutation. */
export default function EditPasswordCard() {
  const [open, setOpen] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const changePwd = useChangePassword();

  const {
    register,
    handleSubmit,
    reset,
    setError,
    formState: { errors, isSubmitting },
  } = useForm({
    resolver: zodResolver(changePasswordSchema),
    defaultValues: { currentPassword: "", newPassword: "", confirmPassword: "" },
  });

  const onSubmit = async (values) => {
    try {
      await changePwd.mutateAsync({
        currentPassword: values.currentPassword,
        newPassword: values.newPassword,
      });
      reset(); // xóa sạch mật khẩu khỏi form sau khi đổi thành công
    } catch (err) {
      // Lỗi từ server (vd: sai mật khẩu hiện tại) hiện ngay dưới form
      setError("root", { message: err.message || "Đổi mật khẩu thất bại" });
    }
  };

  const type = showPassword ? "text" : "password";

  return (
    <div className={`${cardClass} overflow-hidden transition-all`}>
      <button type="button" onClick={() => setOpen((v) => !v)} className={accordionHeaderClass}>
        <div className="flex items-center gap-3">
          <div className={iconBoxClass}>
            <Lock className="h-4 w-4" />
          </div>
          <h4 className="text-xs sm:text-sm font-bold text-ink">
            Đổi mật khẩu
          </h4>
        </div>
        {open ? (
          <ChevronUp className="h-4 w-4 text-subtle" />
        ) : (
          <ChevronDown className="h-4 w-4 text-subtle" />
        )}
      </button>

      {open && (
        <form onSubmit={handleSubmit(onSubmit)} className={accordionBodyClass}>
          <div>
            <label htmlFor="edit-currentPassword" className={labelClass}>
              Mật khẩu hiện tại
            </label>
            <input
              id="edit-currentPassword"
              type={type}
              autoComplete="current-password"
              placeholder="Nhập mật khẩu hiện tại"
              aria-invalid={Boolean(errors.currentPassword)}
              className={inputClass}
              {...register("currentPassword")}
            />
            {errors.currentPassword && (
              <span className={errorTextClass}>{errors.currentPassword.message}</span>
            )}
          </div>

          <div>
            <label htmlFor="edit-newPassword" className={labelClass}>
              Mật khẩu mới
            </label>
            <div className="relative">
              <input
                id="edit-newPassword"
                type={type}
                autoComplete="new-password"
                placeholder="Nhập mật khẩu mới"
                aria-invalid={Boolean(errors.newPassword)}
                className={`${inputClass} pr-9`}
                {...register("newPassword")}
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                aria-label={showPassword ? "Ẩn mật khẩu" : "Hiện mật khẩu"}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-subtle hover:text-ink cursor-pointer"
              >
                {showPassword ? <EyeOff className="h-3.5 w-3.5" /> : <Eye className="h-3.5 w-3.5" />}
              </button>
            </div>
            {errors.newPassword && (
              <span className={errorTextClass}>{errors.newPassword.message}</span>
            )}
          </div>

          <div>
            <label htmlFor="edit-confirmPassword" className={labelClass}>
              Xác nhận mật khẩu mới
            </label>
            <input
              id="edit-confirmPassword"
              type={type}
              autoComplete="new-password"
              placeholder="Nhập lại mật khẩu mới"
              aria-invalid={Boolean(errors.confirmPassword)}
              className={`${inputClass} pr-9`}
              {...register("confirmPassword")}
            />
            {errors.confirmPassword && (
              <span className={errorTextClass}>{errors.confirmPassword.message}</span>
            )}
          </div>

          {errors.root && <p className={errorBoxClass}>{errors.root.message}</p>}
          {changePwd.isSuccess && !errors.root && (
            <p className={successBoxClass}>Đã đổi mật khẩu thành công.</p>
          )}

          <Button
            type="submit"
            variant="default"
            size="sm"
            disabled={isSubmitting}
            className="rounded-xl gap-1.5 font-semibold cursor-pointer"
          >
            {isSubmitting && <Loader2 className="h-3.5 w-3.5 animate-spin" />}
            {isSubmitting ? "Đang cập nhật…" : "Cập nhật mật khẩu"}
          </Button>
        </form>
      )}
    </div>
  );
}
