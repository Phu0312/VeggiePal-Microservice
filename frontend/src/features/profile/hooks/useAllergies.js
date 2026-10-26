import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import {
  getAllergens,
  getMyAllergies,
  replaceMyAllergies,
} from "@/features/profile/api/profileApi";
import { profileKeys } from "@/features/profile/queryKeys";

/** Danh mục dị ứng (GET /nutrition/allergens) — ít thay đổi nên cache 10 phút. */
export function useAllergens() {
  return useQuery({
    queryKey: profileKeys.allergens,
    queryFn: getAllergens,
    staleTime: 10 * 60 * 1000,
  });
}

/** Dị ứng đang chọn của user (GET /nutrition/me/allergies). */
export function useMyAllergies() {
  return useQuery({
    queryKey: profileKeys.myAllergies,
    queryFn: getMyAllergies,
  });
}

/** Lưu danh sách dị ứng (PUT /nutrition/me/allergies), cập nhật cache bằng kết quả trả về. */
export function useReplaceMyAllergies() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: replaceMyAllergies,
    onSuccess: (result) => {
      queryClient.setQueryData(profileKeys.myAllergies, result);
    },
  });
}
