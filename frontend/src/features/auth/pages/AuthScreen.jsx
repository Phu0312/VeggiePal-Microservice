import { useLocation, useNavigate } from "react-router-dom";

import AuthLayout from "@/features/auth/components/AuthLayout";
import AuthShowcase from "@/features/auth/components/AuthShowcase";
import LoginForm from "@/features/auth/components/LoginForm";
import RegisterForm from "@/features/auth/components/RegisterForm";
import Logo from "@/shared/components/Logo";

const MODE_BY_PATH = {
  "/register": "register",
};

// 2 mode (login/register) dùng chung 1 khung ảnh+card,
// URL quyết định mode nào hiển thị — không còn tách thành page riêng nữa.
export default function AuthScreen() {
  const location = useLocation();
  const navigate = useNavigate();
  const mode = MODE_BY_PATH[location.pathname] ?? "login";

  const toRegister = () => navigate("/register", { replace: true, state: location.state });
  const toLogin = () => navigate("/login", { replace: true, state: location.state });

  return (
    <AuthLayout className="px-6 py-10">
      <div className="relative flex w-full max-w-[1040px] flex-col overflow-hidden rounded-[32px] border border-white/30 bg-gradient-to-br from-[#1b5e20] via-[#2e7d32] to-[#689f38] shadow-2xl lg:h-[min(680px,85vh)] lg:flex-row">
        <div aria-hidden className="pointer-events-none absolute -left-16 -top-16 size-72 rounded-full bg-brand-2/40 blur-3xl" />
        <div aria-hidden className="pointer-events-none absolute -bottom-20 left-1/3 size-72 rounded-full bg-white/10 blur-3xl" />
        <Logo light className="absolute left-5 top-5 z-20 lg:hidden" markClassName="size-9" />

        <AuthShowcase />

        <div className="relative z-10 flex min-h-0 w-full flex-1 items-center justify-center overflow-y-auto bg-black/15 px-5 pb-10 pt-20 backdrop-blur-xl no-scrollbar sm:px-6 lg:px-10 lg:py-10">
          <div key={mode} className="auth-form-enter w-full flex justify-center">
            {mode === "register" && <RegisterForm onSwitchMode={toLogin} />}
            {mode === "login" && <LoginForm onSwitchMode={toRegister} />}
          </div>
        </div>
      </div>
    </AuthLayout>
  );
}
