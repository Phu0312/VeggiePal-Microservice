import { useQuery } from "@tanstack/react-query";

import { getPublicUsers } from "@/shared/api/publicUserApi";
import { normalizeIds } from "@/shared/utils/ids";

const toUserMap = (users) => new Map(users.map((u) => [u.id, u]));

/**
 * Tên + avatar của danh sách tác giả (GET /users/batch).
 * `data` là Map<id, { id, fullName, avatarUrl }> -> dùng `data?.get(authorId)`.
 * Id không có trong Map nghĩa là user không còn hiển thị công khai (nên hiện tên dự phòng).
 */
export function usePublicUsers(ids) {
  const uniqueIds = normalizeIds(ids);
  return useQuery({
    queryKey: ["users", "public", uniqueIds],
    queryFn: () => getPublicUsers(uniqueIds),
    select: toUserMap,
    enabled: uniqueIds.length > 0,
    staleTime: 5 * 60 * 1000,
  });
}
