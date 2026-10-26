import { useId, useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { useNavigate, useLocation } from "react-router-dom";
import { Eye, EyeOff } from "lucide-react";

import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import GoogleSignInButton from "@/features/auth/components/GoogleSignInButton";
import { loginSchema } from "@/features/auth/schema";
import { login } from "@/features/auth/api/authApi";
import { useAuthStore } from "@/features/auth/store/authStore";
import { resolvePostLoginPath } from "@/features/auth/utils/roleRedirect";

import mailIcon from "@/assets/svg/mail.svg";

export default function LoginForm({ onSwitchMode }) {
  const navigate = useNavigate();
  const location = useLocation();
  const setAuth = useAuthStore((s) => s.setAuth);
  const [showPassword, setShowPassword] = useState(false);

  const emailId = useId();
  const passwordId = useId();

  // trang người dùng muốn vào trước khi bị đá về /login (nếu có)
  const from = location.state?.from?.pathname;

  const {
    register,
    handleSubmit,
    setError,
    formState: { errors, isSubmitting },
  } = useForm({
    resolver: zodResolver(loginSchema),
    defaultValues: { email: "", password: "", remember: false },
  });

  const onSubmit = async (values) => {
    try {
      const { token, user } = await login(values);
      setAuth({ token, user, remember: Boolean(values.remember) });
      // ADMIN vào thẳng trang quản trị; người dùng thường quay lại trang trước đó (hoặc "/").
      navigate(resolvePostLoginPath(user, from), { replace: true });
    } catch (err) {
      setError("root", { message: err.message || "Đăng nhập thất bại" });
    }
  };

  return (
    <div className="w-full max-w-[380px] px-2 py-4">
      <h2 className="mb-7 text-center text-[30px] font-extrabold tracking-tight text-white font-heading">
        Đăng nhập VeggiePal
      </h2>

      <form onSubmit={handleSubmit(onSubmit)} noValidate className="flex flex-col gap-4">
        {errors.root && (
          <p role="alert" className="rounded-lg bg-destructive/15 px-3 py-2 text-sm text-destructive">
            {errors.root.message}
          </p>
        )}

        <div className="flex flex-col gap-1">
          <label htmlFor={emailId} className="text-[20px] font-semibold tracking-tight text-white font-heading">
            Email
          </label>
          <div className="relative">
            <Input
              variant="auth"
              id={emailId}
              type="text"
              autoComplete="email"
              placeholder="Nhập email hoặc số điện thoại..."
              aria-invalid={Boolean(errors.email)}
              {...register("email")}
            />
            <img
              src={mailIcon}
              alt=""
              className="pointer-events-none absolute right-0 top-1/2 w-[17px] -translate-y-1/2 brightness-0 invert opacity-80"
            />
          </div>
          {errors.email && <span className="text-xs text-destructive">{errors.email.message}</span>}
        </div>

        <div className="flex flex-col gap-1">
          <label htmlFor={passwordId} className="text-[20px] font-semibold tracking-tight text-white font-heading">
            Mật khẩu
          </label>
          <div className="relative">
            <Input
              variant="auth"
              id={passwordId}
              type={showPassword ? "text" : "password"}
              autoComplete="current-password"
              placeholder="Nhập mật khẩu của bạn..."
              aria-invalid={Boolean(errors.password)}
              {...register("password")}
            />
            <button
              type="button"
              onClick={() => setShowPassword((v) => !v)}
              aria-label={showPassword ? "Ẩn mật khẩu" : "Hiện mật khẩu"}
              className="absolute right-0 top-1/2 flex size-6 -translate-y-1/2 items-center justify-center text-white/80 transition hover:text-white"
            >
              {showPassword ? <EyeOff className="size-[18px]" /> : <Eye className="size-[18px]" />}
            </button>
          </div>
          {errors.password && (
            <span className="text-xs text-destructive">{errors.password.message}</span>
          )}
        </div>

        <div className="flex items-center justify-between text-[13px]">
          <label className="flex items-center gap-2 font-medium text-white/75">
            <input
              type="checkbox"
              className="size-4 rounded border-white/40 accent-brand"
              {...register("remember")}
            />
            Ghi nhớ đăng nhập
          </label>
          <button
            type="button"
            onClick={() => navigate("/forgot-password")}
            className="font-semibold text-white/90 transition hover:text-white hover:underline"
          >
            Quên mật khẩu?
          </button>
        </div>

        <Button
          type="submit"
          variant="gradient"
          size="xl"
          disabled={isSubmitting}
          className="mt-1 w-full"
        >
          {isSubmitting ? "Đang đăng nhập..." : "Đăng nhập"}
        </Button>
      </form>

      <p className="mt-5 text-center text-[14px] text-white/75">
        Chưa có tài khoản?{" "}
        <button type="button" onClick={onSwitchMode} className="font-bold text-white hover:underline">
          Đăng ký ngay
        </button>
      </p>

      <div className="mt-5 flex items-center gap-3">
        <span className="h-px flex-1 bg-white/15" />
        <span className="text-[11px] font-medium uppercase tracking-wide text-white/50">Hoặc</span>
        <span className="h-px flex-1 bg-white/15" />
      </div>

      <GoogleSignInButton onError={(message) => setError("root", { message })} />
    </div>
  );
}
