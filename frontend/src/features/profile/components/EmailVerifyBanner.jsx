import { useId, useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Loader2, MailCheck, MailWarning } from "lucide-react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { sendEmailVerification, verifyEmail } from "@/features/auth/api/authApi";
import { useResendCountdown } from "@/features/auth/hooks/useResendCountdown";
import { otpSchema } from "@/features/auth/schema";
import { otpSentNotice } from "@/features/auth/utils/otpText";
import { useApplyProfile } from "@/features/profile/hooks/useProfile";

/**
 * Nhắc xác minh email ở trang Hồ sơ khi `emailVerified` còn false.
 * Gửi mã: POST /auth/send-verification (BE lấy email từ token); xác minh: POST /auth/verify-email.
 */
export default function EmailVerifyBanner({ profile }) {
  const otpId = useId();
  const applyProfile = useApplyProfile();
  const countdown = useResendCountdown();
  const [sending, setSending] = useState(false);
  const [notice, setNotice] = useState("");
  const [codeRequested, setCodeRequested] = useState(false);

  const {
    register,
    handleSubmit,
    setError,
    clearErrors,
    resetField,
    formState: { errors, isSubmitting },
  } = useForm({ resolver: zodResolver(otpSchema), defaultValues: { otp: "" } });

  if (!profile?.email || profile.emailVerified) return null;

  const send = async () => {
    setSending(true);
    clearErrors("root");
    try {
      const result = await sendEmailVerification();
      setNotice(otpSentNotice(result?.expiresInSeconds));
      setCodeRequested(true);
      countdown.start();
    } catch (err) {
      setError("root", { message: err.message });
    } finally {
      setSending(false);
    }
  };

  const submit = async ({ otp }) => {
    try {
      const updated = await verifyEmail({ email: profile.email, otp });
      applyProfile(updated ? { ...profile, ...updated, emailVerified: true } : { ...profile, emailVerified: true });
      toast.success("Đã xác minh email");
    } catch (err) {
      // 1028: thật ra đã xác minh rồi -> cập nhật lại giao diện.
      if (err.code === 1028) {
        applyProfile({ ...profile, emailVerified: true });
        return;
      }
      if (err.code === 1026) resetField("otp");
      setError("root", { message: err.message });
    }
  };

  return (
    <section className="rounded-3xl border border-warning/40 bg-warning/10 p-5 shadow-sm sm:p-6">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
        <div className="flex items-start gap-3">
          <MailWarning className="mt-0.5 size-5 shrink-0 text-warning" />
          <div>
            <h2 className="font-heading text-base font-bold text-ink">Email chưa được xác minh</h2>
            <p className="mt-1 text-sm text-body">
              Xác minh <span className="font-semibold text-ink">{profile.email}</span> để bảo vệ tài khoản và lấy lại
              mật khẩu khi cần.
            </p>
          </div>
        </div>
        <Button
          type="button"
          variant="outline"
          size="sm"
          onClick={send}
          disabled={sending || countdown.remaining > 0}
          className="shrink-0"
        >
          {sending ? <Loader2 className="size-4 animate-spin" /> : <MailCheck className="size-4" />}
          {countdown.remaining > 0
            ? `Gửi lại sau ${countdown.remaining}s`
            : codeRequested
              ? "Gửi lại mã"
              : "Gửi mã xác minh"}
        </Button>
      </div>

      {notice && <p className="mt-4 text-sm text-body">{notice}</p>}
      {errors.root && (
        <p role="alert" className="mt-3 rounded-xl bg-destructive/10 px-3 py-2 text-sm text-destructive">
          {errors.root.message}
        </p>
      )}

      {codeRequested && (
        <form onSubmit={handleSubmit(submit)} noValidate className="mt-4 flex flex-col gap-2 sm:flex-row sm:items-start">
          <div className="flex flex-1 flex-col gap-1">
            <label htmlFor={otpId} className="sr-only">
              Mã OTP
            </label>
            <Input
              id={otpId}
              inputMode="numeric"
              autoComplete="one-time-code"
              maxLength={6}
              placeholder="Nhập mã 6 chữ số"
              aria-invalid={Boolean(errors.otp)}
              className="tracking-[0.3em]"
              {...register("otp")}
            />
            {errors.otp && <span className="text-xs text-destructive">{errors.otp.message}</span>}
          </div>
          <Button type="submit" disabled={isSubmitting} className="h-11">
            {isSubmitting && <Loader2 className="size-4 animate-spin" />}
            Xác minh
          </Button>
        </form>
      )}
    </section>
  );
}
