import { keepPreviousData, useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { getAdminUsers, updateUserRole, updateUserStatus } from "@/features/admin/users/api/adminUserApi";
import { adminUserKeys } from "@/features/admin/users/queryKeys";

/** Danh sách người dùng có lọc + phân trang; giữ trang cũ trong lúc tải trang mới. */
export function useAdminUsers(params) {
  return useQuery({
    queryKey: adminUserKeys.list(params),
    queryFn: () => getAdminUsers(params),
    placeholderData: keepPreviousData,
  });
}

/**
 * Đổi trạng thái hoặc vai trò. mutate({ id, field: "status" | "role", value }).
 * Thành công hoặc lỗi 1020 / 1023 (đã ở giá trị đó, tức danh sách đang cũ) đều tải lại danh sách.
 */
export function useUpdateAdminUser() {
  const queryClient = useQueryClient();
  const reload = () => queryClient.invalidateQueries({ queryKey: adminUserKeys.all });
  return useMutation({
    mutationFn: ({ id, field, value }) => (field === "status" ? updateUserStatus(id, value) : updateUserRole(id, value)),
    onSuccess: reload,
    onError: (error) => {
      if (error.code === 1020 || error.code === 1023) reload();
    },
  });
}
