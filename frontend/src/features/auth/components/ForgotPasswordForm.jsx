import { useId, useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { ArrowLeft, Eye, EyeOff, KeyRound, Mail } from "lucide-react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { requestPasswordReset, resetPassword, verifyPasswordResetOtp } from "@/features/auth/api/authApi";
import { useResendCountdown } from "@/features/auth/hooks/useResendCountdown";
import { forgotEmailSchema, otpSchema, resetPasswordSchema } from "@/features/auth/schema";
import { otpSentNotice } from "@/features/auth/utils/otpText";

const labelClass = "text-[20px] font-semibold tracking-tight text-white font-heading";
const errorClass = "rounded-lg bg-destructive/15 px-3 py-2 text-sm text-destructive";

/**
 * Quên mật khẩu, 3 bước: email -> mã OTP 6 số -> mật khẩu mới.
 * BE luôn trả 200 ở bước gửi mã (kể cả email chưa đăng ký / vượt giới hạn) nên không khẳng định "đã gửi".
 */
export default function ForgotPasswordForm({ onBackToLogin }) {
  const [step, setStep] = useState("email");
  const [email, setEmail] = useState("");
  const [resetToken, setResetToken] = useState("");
  const [notice, setNotice] = useState("");
  const [restartError, setRestartError] = useState("");
  const countdown = useResendCountdown();

  const sendCode = async (targetEmail) => {
    const result = await requestPasswordReset(targetEmail);
    setEmail(targetEmail);
    setNotice(otpSentNotice(result?.expiresInSeconds, "Nếu email này đã đăng ký"));
    countdown.start();
  };

  // 1027: phiên đặt lại hết hạn -> quay về bước 1.
  const restart = (message) => {
    setResetToken("");
    setRestartError(message);
    setStep("email");
  };

  return (
    <div className="w-full max-w-[380px] px-2 py-4">
      <h2 className="mb-2 text-center text-[30px] font-extrabold tracking-tight text-white font-heading">
        Quên mật khẩu
      </h2>
      <p className="mb-7 text-center text-[14px] text-white/75">
        {step === "email" && "Nhập email đã đăng ký để nhận mã đặt lại mật khẩu."}
        {step === "otp" && "Nhập mã gồm 6 chữ số trong email."}
        {step === "password" && "Đặt mật khẩu mới cho tài khoản của bạn."}
      </p>

      {step === "email" && (
        <EmailStep
          defaultEmail={email}
          initialError={restartError}
          onSubmit={async (value) => {
            await sendCode(value);
            setRestartError("");
            setStep("otp");
          }}
        />
      )}
      {step === "otp" && (
        <OtpStep
          email={email}
          notice={notice}
          countdown={countdown}
          onResend={() => sendCode(email)}
          onChangeEmail={() => setStep("email")}
          onVerified={(token) => {
            setResetToken(token);
            setStep("password");
          }}
        />
      )}
      {step === "password" && (
        <PasswordStep
          resetToken={resetToken}
          onExpired={restart}
          onDone={() => {
            toast.success("Đã đặt lại mật khẩu, vui lòng đăng nhập bằng mật khẩu mới");
            onBackToLogin();
          }}
        />
      )}

      <p className="mt-6 text-center text-[14px] text-white/75">
        <button
          type="button"
          onClick={onBackToLogin}
          className="inline-flex items-center gap-1.5 font-bold text-white hover:underline"
        >
          <ArrowLeft className="size-4" />
          Quay lại đăng nhập
        </button>
      </p>
    </div>
  );
}

function EmailStep({ defaultEmail, initialError, onSubmit }) {
  const emailId = useId();
  const {
    register,
    handleSubmit,
    setError,
    formState: { errors, isSubmitting },
  } = useForm({
    resolver: zodResolver(forgotEmailSchema),
    defaultValues: { email: defaultEmail },
  });

  const submit = async ({ email }) => {
    try {
      await onSubmit(email);
    } catch (err) {
      setError("root", { message: err.message });
    }
  };

  const rootError = errors.root?.message || initialError;

  return (
    <form onSubmit={handleSubmit(submit)} noValidate className="flex flex-col gap-4">
      {rootError && (
        <p role="alert" className={errorClass}>
          {rootError}
        </p>
      )}
      <div className="flex flex-col gap-1">
        <label htmlFor={emailId} className={labelClass}>
          Email
        </label>
        <div className="relative">
          <Input
            variant="auth"
            id={emailId}
            type="email"
            autoComplete="email"
            placeholder="Nhập email của bạn..."
            aria-invalid={Boolean(errors.email)}
            {...register("email")}
          />
          <Mail className="pointer-events-none absolute right-0 top-1/2 size-[17px] -translate-y-1/2 text-white/80" />
        </div>
        {errors.email && <span className="text-xs text-destructive">{errors.email.message}</span>}
      </div>
      <Button type="submit" variant="gradient" size="xl" disabled={isSubmitting} className="mt-1 w-full">
        {isSubmitting ? "Đang gửi..." : "Gửi mã"}
      </Button>
    </form>
  );
}

function OtpStep({ email, notice, countdown, onResend, onChangeEmail, onVerified }) {
  const otpId = useId();
  const [resending, setResending] = useState(false);
  const {
    register,
    handleSubmit,
    setError,
    resetField,
    formState: { errors, isSubmitting },
  } = useForm({ resolver: zodResolver(otpSchema), defaultValues: { otp: "" } });

  const submit = async ({ otp }) => {
    try {
      const result = await verifyPasswordResetOtp({ email, otp });
      onVerified(result?.resetToken ?? "");
    } catch (err) {
      // 1026: sai quá nhiều lần thì mã cũ bỏ đi, phải xin mã mới.
      if (err.code === 1026) resetField("otp");
      setError("root", { message: err.message });
    }
  };

  const resend = async () => {
    setResending(true);
    try {
      await onResend();
      resetField("otp");
    } catch (err) {
      setError("root", { message: err.message });
    } finally {
      setResending(false);
    }
  };

  return (
    <form onSubmit={handleSubmit(submit)} noValidate className="flex flex-col gap-4">
      {notice && <p className="rounded-lg bg-white/10 px-3 py-2 text-sm text-white/85">{notice}</p>}
      {errors.root && (
        <p role="alert" className={errorClass}>
          {errors.root.message}
        </p>
      )}
      <div className="flex flex-col gap-1">
        <label htmlFor={otpId} className={labelClass}>
          Mã OTP
        </label>
        <div className="relative">
          <Input
            variant="auth"
            id={otpId}
            inputMode="numeric"
            autoComplete="one-time-code"
            maxLength={6}
            placeholder="6 chữ số"
            aria-invalid={Boolean(errors.otp)}
            className="tracking-[0.4em]"
            {...register("otp")}
          />
          <KeyRound className="pointer-events-none absolute right-0 top-1/2 size-[17px] -translate-y-1/2 text-white/80" />
        </div>
        {errors.otp && <span className="text-xs text-destructive">{errors.otp.message}</span>}
      </div>
      <div className="flex items-center justify-between text-[13px] text-white/75">
        <button type="button" onClick={onChangeEmail} className="hover:text-white hover:underline">
          Đổi email
        </button>
        <button
          type="button"
          onClick={resend}
          disabled={countdown.remaining > 0 || resending}
          className="font-semibold text-white hover:underline disabled:cursor-not-allowed disabled:font-normal disabled:text-white/50 disabled:no-underline"
        >
          {countdown.remaining > 0 ? `Gửi lại sau ${countdown.remaining}s` : resending ? "Đang gửi..." : "Gửi lại mã"}
        </button>
      </div>
      <Button type="submit" variant="gradient" size="xl" disabled={isSubmitting} className="mt-1 w-full">
        {isSubmitting ? "Đang kiểm tra..." : "Xác nhận mã"}
      </Button>
    </form>
  );
}

function PasswordStep({ resetToken, onExpired, onDone }) {
  const passwordId = useId();
  const confirmId = useId();
  const [showPassword, setShowPassword] = useState(false);
  const {
    register,
    handleSubmit,
    setError,
    formState: { errors, isSubmitting },
  } = useForm({
    resolver: zodResolver(resetPasswordSchema),
    defaultValues: { newPassword: "", confirmPassword: "" },
  });

  const submit = async ({ newPassword }) => {
    try {
      await resetPassword({ resetToken, newPassword });
      onDone();
    } catch (err) {
      if (err.code === 1027) {
        onExpired(err.message);
        return;
      }
      setError("root", { message: err.message });
    }
  };

  const fields = [
    { id: passwordId, name: "newPassword", label: "Mật khẩu mới", autoComplete: "new-password" },
    { id: confirmId, name: "confirmPassword", label: "Nhập lại mật khẩu", autoComplete: "new-password" },
  ];

  return (
    <form onSubmit={handleSubmit(submit)} noValidate className="flex flex-col gap-4">
      {errors.root && (
        <p role="alert" className={errorClass}>
          {errors.root.message}
        </p>
      )}
      {fields.map((field) => (
        <div key={field.name} className="flex flex-col gap-1">
          <label htmlFor={field.id} className={labelClass}>
            {field.label}
          </label>
          <div className="relative">
            <Input
              variant="auth"
              id={field.id}
              type={showPassword ? "text" : "password"}
              autoComplete={field.autoComplete}
              placeholder="Tối thiểu 6 ký tự..."
              aria-invalid={Boolean(errors[field.name])}
              {...register(field.name)}
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
          {errors[field.name] && <span className="text-xs text-destructive">{errors[field.name].message}</span>}
        </div>
      ))}
      <Button type="submit" variant="gradient" size="xl" disabled={isSubmitting} className="mt-1 w-full">
        {isSubmitting ? "Đang lưu..." : "Đặt lại mật khẩu"}
      </Button>
    </form>
  );
}
