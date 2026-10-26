import { useLocation, useNavigate } from "react-router-dom";

import AuthLayout from "@/features/auth/components/AuthLayout";
import AuthShowcase from "@/features/auth/components/AuthShowcase";
import LoginForm from "@/features/auth/components/LoginForm";
import RegisterForm from "@/features/auth/components/RegisterForm";
import ForgotPasswordForm from "@/features/auth/components/ForgotPasswordForm";
import VerifyOtpForm from "@/features/auth/components/VerifyOtpForm";
import bg from "@/assets/img/bg.png";

const MODE_BY_PATH = {
  "/register": "register",
  "/forgot-password": "forgot",
  "/verify-otp": "otp",
};

// 4 mode (login/register/quên mật khẩu/otp) dùng chung 1 khung ảnh+card,
// URL quyết định mode nào hiển thị — không còn tách thành page riêng nữa.
export default function AuthScreen() {
  const location = useLocation();
  const navigate = useNavigate();
  const mode = MODE_BY_PATH[location.pathname] ?? "login";

  const toRegister = () => navigate("/register", { replace: true, state: location.state });
  const toLogin = () => navigate("/login", { replace: true, state: location.state });

  return (
    <AuthLayout className="px-6 py-10">
      <div className="relative flex w-full max-w-[1040px] flex-col overflow-hidden shadow-2xl lg:h-[min(680px,85vh)] lg:flex-row">
        <img src={bg} alt="" className="absolute inset-0 h-full w-full object-cover" />

        <AuthShowcase />

        <div className="relative z-10 flex min-h-0 w-full flex-1 items-center justify-center overflow-y-auto bg-black/15 px-6 py-10 backdrop-blur-xl no-scrollbar lg:px-10">
          <div key={mode} className="auth-form-enter w-full flex justify-center">
            {mode === "register" && <RegisterForm onSwitchMode={toLogin} />}
            {mode === "forgot" && <ForgotPasswordForm />}
            {mode === "otp" && <VerifyOtpForm />}
            {mode === "login" && <LoginForm onSwitchMode={toRegister} />}
          </div>
        </div>
      </div>
    </AuthLayout>
  );
}
