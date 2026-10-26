import { useId, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Eye, EyeOff } from "lucide-react";
import { toast } from "sonner";

import { useForm, useWatch } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import GoogleSignInButton from "@/features/auth/components/GoogleSignInButton";
import { registerSchema } from "@/features/auth/schema";
import { register as registerUser } from "@/features/auth/api/authApi";

import peopleIcon from "@/assets/svg/people.svg";
import phoneIcon from "@/assets/svg/phone.svg";
import mailIcon from "@/assets/svg/mail.svg";

export default function RegisterForm({ onSwitchMode }) {
  const navigate = useNavigate();

  const fullNameId = useId();
  const emailId = useId();
  const phoneId = useId();
  const passwordId = useId();
  const confirmPasswordId = useId();

  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  const {
    register,
    handleSubmit,
    setError,
    control,
    formState: { errors, isSubmitting },
  } = useForm({
    resolver: zodResolver(registerSchema),
    defaultValues: {
      fullName: "",
      email: "",
      phone: "",
      password: "",
      confirmPassword: "",
      acceptTerms: false,
    },
  });

  const acceptTerms = useWatch({ control, name: "acceptTerms" });

  const onSubmit = async ({ fullName, email, phone, password }) => {
    try {
      await registerUser({ fullName, email, phone, password });
      toast.success("Đăng ký thành công! Hãy đăng nhập để tiếp tục.");
      navigate("/login");
    } catch (err) {
      setError("root", { message: err.message || "Đăng ký thất bại" });
    }
  };

  return (
    <div className="w-full max-w-[420px] px-2 py-4">
      <h2 className="mb-6 text-center text-[30px] font-extrabold tracking-tight text-white font-heading">
        Tạo tài khoản VeggiePal
      </h2>

      <form onSubmit={handleSubmit(onSubmit)} noValidate className="flex flex-col gap-4">
        {errors.root && (
          <p role="alert" className="rounded-lg bg-destructive/15 px-3 py-2 text-sm text-destructive">
            {errors.root.message}
          </p>
        )}

        <div className="relative flex flex-col gap-1">
          <label htmlFor={fullNameId} className="text-[18px] font-semibold tracking-tight text-white font-heading">
            Họ và tên
          </label>
          <div className="relative">
            <Input
              variant="auth"
              id={fullNameId}
              type="text"
              autoComplete="name"
              placeholder="Nhập họ và tên của bạn"
              aria-invalid={Boolean(errors.fullName)}
              className="h-10 border-white/40"
              {...register("fullName")}
            />
            <img
              src={peopleIcon}
              alt=""
              className="pointer-events-none absolute right-0 top-1/2 size-4 -translate-y-1/2 brightness-0 invert opacity-80"
            />
          </div>
          {errors.fullName && (
            <span className="absolute left-0 top-full mt-1 text-xs leading-tight text-destructive">
              {errors.fullName.message}
            </span>
          )}
        </div>

        <div className="relative flex flex-col gap-1">
          <label htmlFor={emailId} className="text-[18px] font-semibold tracking-tight text-white font-heading">
            Email
          </label>
          <div className="relative">
            <Input
              variant="auth"
              id={emailId}
              type="email"
              autoComplete="email"
              placeholder="Nhập email của bạn"
              aria-invalid={Boolean(errors.email)}
              className="h-10 border-white/40"
              {...register("email")}
            />
            <img
              src={mailIcon}
              alt=""
              className="pointer-events-none absolute right-0 top-1/2 w-[17px] -translate-y-1/2 brightness-0 invert opacity-80"
            />
          </div>
          {errors.email && (
            <span className="absolute left-0 top-full mt-1 text-xs leading-tight text-destructive">
              {errors.email.message}
            </span>
          )}
        </div>

        <div className="relative flex flex-col gap-1">
          <label htmlFor={phoneId} className="text-[18px] font-semibold tracking-tight text-white font-heading">
            Số điện thoại (không bắt buộc)
          </label>
          <div className="relative">
            <Input
              variant="auth"
              id={phoneId}
              type="tel"
              autoComplete="tel"
              placeholder="Nhập số điện thoại của bạn"
              aria-invalid={Boolean(errors.phone)}
              className="h-10 border-white/40"
              {...register("phone")}
            />
            <img
              src={phoneIcon}
              alt=""
              className="pointer-events-none absolute right-0 top-1/2 size-4 -translate-y-1/2 brightness-0 invert opacity-80"
            />
          </div>
          {errors.phone && (
            <span className="absolute left-0 top-full mt-1 text-xs leading-tight text-destructive">
              {errors.phone.message}
            </span>
          )}
        </div>

        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <div className="relative flex flex-col gap-1">
            <label htmlFor={passwordId} className="text-[18px] font-semibold tracking-tight text-white font-heading">
              Mật khẩu
            </label>
            <div className="relative">
              <Input
                variant="auth"
                id={passwordId}
                type={showPassword ? "text" : "password"}
                autoComplete="new-password"
                placeholder="Tối thiểu 6 ký tự"
                aria-invalid={Boolean(errors.password)}
                className="h-10 border-white/40"
                {...register("password")}
              />
              <button
                type="button"
                onClick={() => setShowPassword((v) => !v)}
                aria-label={showPassword ? "Ẩn mật khẩu" : "Hiện mật khẩu"}
                className="absolute right-0 top-1/2 flex size-6 -translate-y-1/2 items-center justify-center text-white/80 transition hover:text-white"
              >
                {showPassword ? <EyeOff className="size-4" /> : <Eye className="size-4" />}
              </button>
            </div>
            {errors.password && (
              <span className="absolute left-0 top-full mt-1 text-xs leading-tight text-destructive">
                {errors.password.message}
              </span>
            )}
          </div>

          <div className="relative flex flex-col gap-1">
            <label htmlFor={confirmPasswordId} className="text-[18px] font-semibold tracking-tight text-white font-heading">
              Xác nhận mật khẩu
            </label>
            <div className="relative">
              <Input
                variant="auth"
                id={confirmPasswordId}
                type={showConfirmPassword ? "text" : "password"}
                autoComplete="new-password"
                placeholder="Nhập lại mật khẩu"
                aria-invalid={Boolean(errors.confirmPassword)}
                className="h-10 border-white/40"
                {...register("confirmPassword")}
              />
              <button
                type="button"
                onClick={() => setShowConfirmPassword((v) => !v)}
                aria-label={showConfirmPassword ? "Ẩn mật khẩu" : "Hiện mật khẩu"}
                className="absolute right-0 top-1/2 flex size-6 -translate-y-1/2 items-center justify-center text-white/80 transition hover:text-white"
              >
                {showConfirmPassword ? <EyeOff className="size-4" /> : <Eye className="size-4" />}
              </button>
            </div>
            {errors.confirmPassword && (
              <span className="absolute left-0 top-full mt-1 text-xs leading-tight text-destructive">
                {errors.confirmPassword.message}
              </span>
            )}
          </div>
        </div>

        <label className="flex items-start gap-2 text-[13px] leading-5 text-white/75">
          <input
            type="checkbox"
            className="mt-0.5 size-4 shrink-0 rounded border-white/40 accent-brand"
            {...register("acceptTerms")}
          />
          <span>
            Tôi đồng ý với <span className="font-semibold text-white">Điều khoản sử dụng</span> và{" "}
            <span className="font-semibold text-white">Chính sách bảo mật</span>
          </span>
        </label>

        <Button
          type="submit"
          variant="gradient"
          size="xl"
          disabled={isSubmitting || !acceptTerms}
          className="w-full disabled:cursor-not-allowed disabled:opacity-40"
        >
          {isSubmitting ? "Đang tạo tài khoản..." : "Tạo tài khoản"}
        </Button>
      </form>

      <p className="mt-4 text-center text-[14px] text-white/75">
        Đã có tài khoản?{" "}
        <button type="button" onClick={onSwitchMode} className="font-bold text-white hover:underline">
          Đăng nhập ngay
        </button>
      </p>

      <div className="mt-4 flex items-center gap-3">
        <span className="h-px flex-1 bg-white/15" />
        <span className="text-[11px] font-medium uppercase tracking-wide text-white/50">Hoặc</span>
        <span className="h-px flex-1 bg-white/15" />
      </div>

      <GoogleSignInButton onError={(message) => setError("root", { message })} />
    </div>
  );
}
