import { useLayoutEffect, useRef, useState } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { GoogleLogin, GoogleOAuthProvider, useGoogleOAuth } from "@react-oauth/google";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { loginWithGoogle } from "@/features/auth/api/authApi";
import { useAuthStore } from "@/features/auth/store/authStore";
import { resolvePostLoginPath } from "@/features/auth/utils/roleRedirect";

// Logo Google (lucide không có icon thương hiệu) vẽ bằng SVG inline.
function GoogleMark({ className }) {
  return (
    <svg viewBox="0 0 24 24" aria-hidden className={className}>
      <path fill="#4285F4" d="M23.5 12.27c0-.85-.08-1.67-.22-2.45H12v4.64h6.46a5.52 5.52 0 0 1-2.4 3.62v3h3.88c2.27-2.09 3.56-5.17 3.56-8.81Z" />
      <path fill="#34A853" d="M12 24c3.24 0 5.96-1.07 7.94-2.91l-3.88-3c-1.07.72-2.45 1.15-4.06 1.15-3.12 0-5.77-2.11-6.71-4.95H1.28v3.1A12 12 0 0 0 12 24Z" />
      <path fill="#FBBC05" d="M5.29 14.29a7.2 7.2 0 0 1 0-4.58v-3.1H1.28a12 12 0 0 0 0 10.78l4.01-3.1Z" />
      <path fill="#EA4335" d="M12 4.76c1.76 0 3.34.61 4.58 1.8l3.44-3.44C17.95 1.19 15.23 0 12 0A12 12 0 0 0 1.28 6.61l4.01 3.1C6.23 6.87 8.88 4.76 12 4.76Z" />
    </svg>
  );
}

const GOOGLE_CLIENT_ID = import.meta.env.VITE_GOOGLE_CLIENT_ID;

// Google chỉ cho nút rộng 200-400px.
const MIN_WIDTH = 200;
const MAX_WIDTH = 400;

/**
 * Nút "Tiếp tục với Google" dùng chung cho màn đăng nhập và đăng ký (BE gộp hai luồng:
 * chưa có tài khoản thì tạo mới). Giữ nguyên nút kính mờ của app; nút thật của Google
 * (cần để lấy ID token) được phủ lên trên, trong suốt, nên bấm vào đâu cũng đúng nút Google.
 * `onError(message)`: để form cha hiện lỗi trong khung lỗi của nó.
 */
export default function GoogleSignInButton({ onError }) {
  if (!GOOGLE_CLIENT_ID) {
    return <GoogleButtonBody status="missing" />;
  }

  return (
    <GoogleOAuthProvider clientId={GOOGLE_CLIENT_ID} locale="vi">
      <GoogleButtonWithOverlay onError={onError} />
    </GoogleOAuthProvider>
  );
}

function GoogleButtonWithOverlay({ onError }) {
  const navigate = useNavigate();
  const location = useLocation();
  const setAuth = useAuthStore((s) => s.setAuth);
  const { scriptLoadedSuccessfully } = useGoogleOAuth();

  const wrapperRef = useRef(null);
  const [width, setWidth] = useState(0);
  const [busy, setBusy] = useState(false);

  // trang người dùng muốn vào trước khi bị đá về /login (nếu có)
  const from = location.state?.from?.pathname;

  useLayoutEffect(() => {
    const measured = Math.round(wrapperRef.current?.offsetWidth ?? 0);
    setWidth(Math.min(MAX_WIDTH, Math.max(MIN_WIDTH, measured)));
  }, []);

  const handleSuccess = async ({ credential }) => {
    if (!credential) {
      onError("Không nhận được thông tin từ Google. Vui lòng thử lại.");
      return;
    }
    setBusy(true);
    try {
      const session = await loginWithGoogle(credential);
      // Không có ô "Ghi nhớ đăng nhập" ở luồng Google nên giữ phiên lâu dài (localStorage).
      setAuth({ ...session, remember: true });
      navigate(resolvePostLoginPath(session.user, from), { replace: true });
    } catch (err) {
      onError(err.message || "Đăng nhập bằng Google thất bại");
      setBusy(false);
    }
  };

  return (
    <div ref={wrapperRef} className="group/google relative mt-3 w-full">
      <GoogleButtonBody status={busy ? "busy" : scriptLoadedSuccessfully ? "ready" : "loading"} />
      {!busy && scriptLoadedSuccessfully && width > 0 && (
        <div className="absolute inset-0 flex h-10 items-center justify-center overflow-hidden rounded-full opacity-0">
          <GoogleLogin
            onSuccess={handleSuccess}
            onError={() => onError("Đăng nhập bằng Google thất bại. Vui lòng thử lại.")}
            width={width}
            size="large"
            text="continue_with"
            shape="pill"
            locale="vi"
          />
        </div>
      )}
    </div>
  );
}

// Phần nhìn thấy được. Khi chưa phủ được nút Google lên trên (thiếu cấu hình / chưa tải xong script)
// thì bấm vào sẽ báo lý do thay vì im lặng.
function GoogleButtonBody({ status }) {
  const onClick = () => {
    if (status === "missing") {
      toast.error("Đăng nhập Google chưa được cấu hình (thiếu VITE_GOOGLE_CLIENT_ID).");
    } else if (status === "loading") {
      toast.info("Đang tải Google, nếu mãi không được hãy kiểm tra kết nối mạng rồi thử lại.");
    }
  };

  return (
    <Button
      type="button"
      variant="glass"
      size="md"
      disabled={status === "busy"}
      onClick={onClick}
      className={
        status === "missing"
          ? "mt-3 w-full text-[13px]"
          : "w-full text-[13px] group-hover/google:bg-white/20"
      }
    >
      <GoogleMark className="size-4" />
      {status === "busy" ? "Đang đăng nhập..." : "Tiếp tục với Google"}
    </Button>
  );
}
