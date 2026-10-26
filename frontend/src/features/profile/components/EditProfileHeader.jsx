import { ArrowLeft, Circle, Sprout } from "lucide-react";
import { useNavigate } from "react-router-dom";

/** Breadcrumb + badge + tiêu đề của trang chỉnh sửa hồ sơ. */
export default function EditProfileHeader({ profile }) {
  const navigate = useNavigate();

  return (
    <div>
      <div className="flex flex-wrap items-center gap-2 text-xs font-medium text-subtle mb-2">
        <button
          type="button"
          onClick={() => navigate("/profile")}
          className="flex items-center gap-1 text-ink hover:text-brand font-semibold cursor-pointer"
        >
          <ArrowLeft className="h-3.5 w-3.5" />
          Quay lại Trang cá nhân
        </button>
        <span>/</span>
        <span>Cài đặt tài khoản</span>
      </div>

      <div className="flex flex-wrap items-center gap-2 mb-2">
        <span className="inline-flex items-center gap-1 rounded-full bg-brand-soft px-2.5 py-0.5 text-[11px] font-semibold text-brand border border-brand/30">
          <Sprout className="size-3" /> Hồ sơ thành viên xanh
        </span>
        {/* Trạng thái xác thực email lấy từ hồ sơ thật thay cho nhãn "đã xác minh" cố định */}
        <span className="inline-flex items-center gap-1 rounded-full bg-surface px-2.5 py-0.5 text-[11px] font-medium text-body border border-border">
          <Circle className="size-2 fill-current" />
          {profile?.emailVerified ? "Email đã xác thực" : "Email chưa xác thực"}
        </span>
      </div>

      <h1 className="text-2xl sm:text-3xl font-extrabold text-ink tracking-tight font-heading">
        Chỉnh sửa hồ sơ
      </h1>
      <p className="text-xs sm:text-sm text-subtle mt-1">
        Quản lý thông tin hiển thị và quyền riêng tư trên cộng đồng thuần chay VeggiePal
      </p>
    </div>
  );
}
