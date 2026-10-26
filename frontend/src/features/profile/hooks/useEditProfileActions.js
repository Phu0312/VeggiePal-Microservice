import { useState } from "react";
import { useNavigate } from "react-router-dom";

/**
 * Nút "Lưu thông tin" / "Hủy thay đổi" cuối trang.
 * Quyết định: chỉ lưu phần đã thay đổi (thông tin cá nhân + dị ứng). Mật khẩu và chỉ số
 * sức khỏe có nút riêng vì là thao tác tức thời (đổi mật khẩu / ghi nhận bản ghi mới).
 * `returnTo`: nơi quay lại sau khi lưu / hủy (mặc định trang cá nhân); trang thực đơn đặt nó khi chuyển người dùng sang
 * bổ sung hồ sơ để họ làm xong là về thẳng thực đơn.
 */
export function useEditProfileActions({ personal, allergy, returnTo = "/profile" }) {
  const navigate = useNavigate();
  const [status, setStatus] = useState({ type: "", message: "" });
  const [saving, setSaving] = useState(false);

  const saveAll = async () => {
    setStatus({ type: "", message: "" });
    if (!personal.dirty && !allergy.dirty) {
      navigate(returnTo);
      return;
    }

    setSaving(true);
    try {
      if (personal.dirty) {
        const valid = await personal.form.trigger();
        if (!valid) {
          personal.openSection(); // mở sẵn phần có lỗi để user thấy
          setStatus({ type: "error", message: "Vui lòng kiểm tra lại thông tin cá nhân." });
          return;
        }
        await personal.save(personal.form.getValues());
      }
      if (allergy.dirty) await allergy.save();

      setStatus({ type: "success", message: "Đã lưu thông tin thành công." });
      // Chờ một chút để user kịp thấy thông báo trước khi chuyển trang.
      await new Promise((resolve) => setTimeout(resolve, 800));
      navigate(returnTo);
    } catch (err) {
      setStatus({ type: "error", message: err.message || "Lưu thông tin thất bại" });
    } finally {
      setSaving(false);
    }
  };

  // Hủy: trả form + lựa chọn dị ứng về dữ liệu server rồi quay lại trang cá nhân.
  const cancel = () => {
    personal.resetToServer();
    allergy.discard();
    navigate(returnTo);
  };

  return { status, saving, saveAll, cancel };
}
