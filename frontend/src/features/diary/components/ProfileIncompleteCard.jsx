import { Link } from "react-router-dom";
import { UserPen } from "lucide-react";

import { buttonVariants } from "@/components/ui/variants/button-variants";

/**
 * BE chưa tính được mục tiêu calo: hồ sơ thiếu (2013) hoặc dưới 18 tuổi (2014).
 * Người dưới 18 tuổi chỉ được dẫn tới sửa hồ sơ (phòng khi nhập sai ngày sinh).
 */
export default function ProfileIncompleteCard({ message, underage }) {
  return (
    <section className="flex flex-col items-center rounded-3xl border border-border bg-card p-8 text-center shadow-sm">
      <UserPen className="size-10 text-brand" />
      <h2 className="mt-3 font-heading text-lg font-bold text-ink">
        {underage ? "Chưa đủ tuổi để tính mục tiêu" : "Cần bổ sung hồ sơ"}
      </h2>
      <p className="mt-2 max-w-md text-sm text-body">{message}</p>
      {underage && (
        <p className="mt-2 text-xs text-subtle">Nếu bạn đã nhập sai ngày sinh, hãy sửa lại trong hồ sơ.</p>
      )}
      <Link
        to="/profile/edit"
        state={{ returnTo: "/diary", returnLabel: "Quay lại nhật ký" }}
        className={buttonVariants({ size: "md", className: "mt-5" })}
      >
        {underage ? "Sửa hồ sơ" : "Bổ sung hồ sơ"}
      </Link>
    </section>
  );
}
