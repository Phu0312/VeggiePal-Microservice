import { useMemo, useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";

import { updateProfileSchema } from "@/lib/schema";
import { useProfile, useUpdateProfile } from "@/features/profile/hooks/useProfile";

// Thẻ này chỉ sửa họ tên và số điện thoại. Ngày sinh, giới tính, mức vận động nằm ở form chỉ số sức khỏe
// (EditHealthForm) cùng chỗ với chiều cao, cân nặng vì BE dùng chúng chung để tính nhu cầu calo.
const personalSchema = updateProfileSchema.pick({ fullName: true, phone: true });

/**
 * Form thông tin cá nhân. Tách thành hook vì cả card lẫn nút "Lưu thông tin"
 * cuối trang đều cần dùng chung form + hàm lưu.
 */
export function usePersonalInfoForm() {
  const { profile, loading, error } = useProfile();
  const updateProfile = useUpdateProfile();
  const [open, setOpen] = useState(false);

  // `values` giúp form tự đồng bộ lại mỗi khi hồ sơ trên server đổi (tải lần đầu / sau khi lưu).
  const serverValues = useMemo(
    () =>
      profile
        ? {
            fullName: profile.fullName || "",
            phone: profile.phone || "",
          }
        : undefined,
    [profile]
  );

  const form = useForm({
    resolver: zodResolver(personalSchema),
    defaultValues: { fullName: "", phone: "" },
    values: serverValues,
  });

  // Gửi lên API: phone "" nghĩa là xóa số điện thoại. Không gửi các trường khác nên BE giữ nguyên ngày sinh,
  // giới tính, mức vận động.
  const save = async (values) => {
    await updateProfile.mutateAsync({
      fullName: values.fullName.trim(),
      phone: values.phone?.trim() ?? "",
    });
  };

  const onSubmit = async (values) => {
    try {
      await save(values);
    } catch (err) {
      form.setError("root", { message: err.message || "Cập nhật hồ sơ thất bại" });
    }
  };

  return {
    profile,
    profileLoading: loading,
    profileError: error,
    form,
    updateProfile,
    save,
    onSubmit,
    saving: form.formState.isSubmitting || updateProfile.isPending,
    dirty: form.formState.isDirty,
    open,
    toggleOpen: () => setOpen((v) => !v),
    openSection: () => setOpen(true),
    resetToServer: () => form.reset(serverValues),
  };
}
