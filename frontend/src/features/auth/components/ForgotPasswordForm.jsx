import { useId, useState } from "react";
import { useNavigate } from "react-router-dom";
import { ArrowLeft, ArrowRight } from "lucide-react";

import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import mailIcon from "@/assets/svg/mail.svg";
import iconFgp from "@/assets/img/icon_fgp.png";

export default function ForgotPasswordForm() {
  const navigate = useNavigate();
  const contactId = useId();
  const [contact, setContact] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setIsSubmitting(true);
    // Chưa gắn backend, chỉ mô phỏng UI.
    navigate("/verify-otp");
    setIsSubmitting(false);
  };

  return (
    <div className="w-full max-w-[380px] px-2 py-4">
      <div className="flex flex-col items-center gap-2">
        <img src={iconFgp} alt="" className="h-50 w-auto object-contain" />
        <h2 className="text-center text-[26px] font-extrabold tracking-tight text-white font-heading">
          Bạn quên mật khẩu rồi à?
        </h2>
      </div>

      <form onSubmit={handleSubmit} noValidate className="mt-6 flex flex-col gap-4">
        <div className="flex flex-col gap-1">
          <label htmlFor={contactId} className="text-[20px] font-semibold tracking-tight text-white font-heading">
            Nhập email hoặc số điện thoại đã đăng ký
          </label>
          <div className="relative">
            <Input
              variant="auth"
              id={contactId}
              type="text"
              autoComplete="username"
              value={contact}
              onChange={(e) => setContact(e.target.value)}
            />
            <img
              src={mailIcon}
              alt=""
              className="pointer-events-none absolute right-0 top-1/2 w-[17px] -translate-y-1/2 brightness-0 invert opacity-80"
            />
          </div>
        </div>

        <Button
          type="submit"
          variant="gradient"
          size="xl"
          disabled={isSubmitting}
          className="mt-1 w-full"
        >
          {isSubmitting ? "Đang gửi..." : "Gửi mã xác nhận"}
          <ArrowRight className="size-4" />
        </Button>
      </form>

      <button
        type="button"
        onClick={() => navigate("/login")}
        className="mx-auto mt-5 flex items-center gap-1.5 text-[14px] font-semibold text-white/90 transition hover:text-white hover:underline"
      >
        <ArrowLeft className="size-4" />
        Quay lại đăng nhập
      </button>
    </div>
  );
}
