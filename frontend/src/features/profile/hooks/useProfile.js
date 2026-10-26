import { useMemo } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { useAuthStore } from "@/features/auth/store/authStore";
import {
  changePassword,
  getProfile,
  updateProfile as updateProfileApi,
  uploadAvatar,
} from "@/features/profile/api/profileApi";
import { profileKeys } from "@/features/profile/queryKeys";

// Giữ token, cập nhật user trong store (fullName / avatar hiển thị ở header).
// Đọc store trực tiếp qua getState() nên không phụ thuộc closure/hook.
function syncAuthUser(p) {
  const { token, setAuth } = useAuthStore.getState();
  if (!p || !token) return;
  setAuth({
    token,
    user: {
      id: p.id,
      email: p.email,
      fullName: p.fullName,
      role: p.role,
      avatarUrl: p.avatarUrl,
    },
  });
}

/**
 * Hồ sơ hiện tại (GET /users/me), đồng bộ user vào authStore.
 * Fallback nhẹ từ authStore nếu API lỗi.
 */
export function useProfile({ enabled = true, staleTime } = {}) {
  const authUser = useAuthStore((s) => s.user);

  const query = useQuery({
    queryKey: profileKeys.me,
    queryFn: async () => {
      const data = await getProfile();
      syncAuthUser(data);
      return data;
    },
    enabled,
    staleTime,
  });

  // API lỗi mà vẫn còn user trong authStore -> dựng hồ sơ tối thiểu từ đó.
  const fallbackProfile = useMemo(
    () =>
      authUser
        ? {
            id: authUser.id,
            email: authUser.email,
            fullName: authUser.fullName,
            role: authUser.role,
            phone: null,
            avatarUrl: authUser.avatarUrl || null,
            dateOfBirth: null,
            gender: null,
            activityLevel: null,
            emailVerified: false,
          }
        : null,
    [authUser]
  );

  return {
    profile: query.data ?? (query.isError ? fallbackProfile : null),
    loading: query.isPending,
    error: query.error ? query.error.message || "Không tải được hồ sơ" : "",
  };
}

// Hồ sơ mới từ server -> ghi vào cache (mọi nơi đang đọc useProfile tự cập nhật)
// và đồng bộ tên/avatar vào authStore để header đổi theo.
function useApplyProfile() {
  const queryClient = useQueryClient();
  return (updated) => {
    queryClient.setQueryData(profileKeys.me, updated);
    syncAuthUser(updated);
  };
}

/** Sửa fullName / phone / dateOfBirth / gender / activityLevel (PATCH /users/me). */
export function useUpdateProfile() {
  const applyProfile = useApplyProfile();
  return useMutation({
    mutationFn: updateProfileApi,
    onSuccess: applyProfile,
  });
}

/** Đổi avatar (POST /users/me/avatar) — server trả về hồ sơ đã cập nhật. */
export function useUploadAvatar() {
  const applyProfile = useApplyProfile();
  return useMutation({
    mutationFn: uploadAvatar,
    onSuccess: applyProfile,
  });
}

/** Đổi mật khẩu (PUT /users/me/password). */
export function useChangePassword() {
  return useMutation({ mutationFn: changePassword });
}
