import { useEffect, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import { ArrowLeft, ArrowRight, Clock } from "lucide-react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import iconOtp from "@/assets/img/icon_otp.png";
import phoneIcon from "@/assets/svg/phone.svg";

const OTP_LENGTH = 6;
const RESEND_SECONDS = 105; // 01:45

export default function VerifyOtpForm({ phone = "0912 *** 678" }) {
  const navigate = useNavigate();
  const [digits, setDigits] = useState(Array(OTP_LENGTH).fill(""));
  const [secondsLeft, setSecondsLeft] = useState(RESEND_SECONDS);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const inputRefs = useRef([]);

  useEffect(() => {
    if (secondsLeft <= 0) return;
    const timer = setInterval(() => {
      setSecondsLeft((s) => Math.max(0, s - 1));
    }, 1000);
    return () => clearInterval(timer);
  }, [secondsLeft]);

  const minutes = String(Math.floor(secondsLeft / 60)).padStart(2, "0");
  const seconds = String(secondsLeft % 60).padStart(2, "0");
  const code = digits.join("");
  const isComplete = code.length === OTP_LENGTH;

  const handleChange = (index, value) => {
    const digit = value.replace(/\D/g, "").slice(-1);
    setDigits((prev) => {
      const next = [...prev];
      next[index] = digit;
      return next;
    });
    if (digit && index < OTP_LENGTH - 1) {
      inputRefs.current[index + 1]?.focus();
    }
  };

  const handleKeyDown = (index, e) => {
    if (e.key === "Backspace" && !digits[index] && index > 0) {
      inputRefs.current[index - 1]?.focus();
    }
  };

  const handlePaste = (e) => {
    const pasted = e.clipboardData.getData("text").replace(/\D/g, "");
    if (!pasted) return;
    e.preventDefault();
    setDigits((prev) => {
      const next = [...prev];
      for (let i = 0; i < OTP_LENGTH; i++) {
        next[i] = pasted[i] || next[i];
      }
      return next;
    });
    const focusIndex = Math.min(pasted.length, OTP_LENGTH) - 1;
    inputRefs.current[focusIndex]?.focus();
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!isComplete) return;
    setIsSubmitting(true);
    // Chưa gắn backend, chỉ mô phỏng UI.
    toast.info("Tính năng này sẽ sẵn sàng khi tích hợp backend.");
    setIsSubmitting(false);
  };

  const handleResend = () => {
    if (secondsLeft > 0) return;
    setSecondsLeft(RESEND_SECONDS);
    setDigits(Array(OTP_LENGTH).fill(""));
    inputRefs.current[0]?.focus();
  };

  return (
    <div className="w-full max-w-[380px] px-2 py-4">
      <div className="flex flex-col items-center gap-2">
        <img src={iconOtp} alt="" className="h-50 w-auto object-contain" />
        <h2 className="text-center text-[26px] font-extrabold tracking-tight text-white font-heading">
          Xác thực mã OTP
        </h2>
      </div>

      <div className="mt-6 flex items-center justify-between gap-3 rounded-xl border border-white/20 bg-white/10 px-4 py-2.5">
        <div className="flex items-center gap-2.5">
          <img src={phoneIcon} alt="" className="w-[15px] brightness-0 invert opacity-80" />
          <div className="flex flex-col">
            <span className="text-[12px] text-white/70">Số điện thoại</span>
            <span className="text-[14px] font-semibold text-white">{phone}</span>
          </div>
        </div>
        <button
          type="button"
          onClick={() => navigate(-1)}
          className="text-[14px] font-semibold text-white/90 transition hover:text-white hover:underline"
        >
          Thay đổi
        </button>
      </div>

      <form onSubmit={handleSubmit} noValidate className="mt-4 flex flex-col gap-3">
        <div className="flex justify-between gap-2" onPaste={handlePaste}>
          {digits.map((digit, index) => (
            <input
              key={index}
              ref={(el) => (inputRefs.current[index] = el)}
              type="text"
              inputMode="numeric"
              maxLength={1}
              value={digit}
              onChange={(e) => handleChange(index, e.target.value)}
              onKeyDown={(e) => handleKeyDown(index, e)}
              className="h-12 w-full max-w-12 rounded-xl border border-white/30 bg-white/10 text-center text-[20px] font-bold text-white outline-none transition focus-visible:border-white focus-visible:bg-white/20"
            />
          ))}
        </div>

        <div className="flex items-center gap-1.5 text-[13px] text-white/70">
          <Clock className="size-3.5" />
          {secondsLeft > 0 ? (
            <span>
              Mã sẽ hết hiệu lực sau:{" "}
              <span className="font-semibold text-white">
                {minutes}:{seconds}
              </span>
            </span>
          ) : (
            <button
              type="button"
              onClick={handleResend}
              className="font-semibold text-white transition hover:underline"
            >
              Gửi lại mã xác thực
            </button>
          )}
        </div>

        <Button
          type="submit"
          variant="gradient"
          size="xl"
          disabled={!isComplete || isSubmitting}
          className="mt-1 w-full"
        >
          {isSubmitting ? "Đang xác nhận..." : "Xác nhận & Tiếp tục"}
          <ArrowRight className="size-4" />
        </Button>
      </form>

      <button
        type="button"
        onClick={() => navigate(-1)}
        className="mx-auto mt-5 flex items-center gap-1.5 text-[14px] font-semibold text-white/90 transition hover:text-white hover:underline"
      >
        <ArrowLeft className="size-4" />
        Quay lại trang trước
      </button>
    </div>
  );
}
