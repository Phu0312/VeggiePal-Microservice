import apiClient from "@/shared/api/apiClient";
import { chunk, joinIds, normalizeIds } from "@/shared/utils/ids";

// BE giới hạn 50 id mỗi lần gọi, vượt quá sẽ trả lỗi INVALID_REQUEST.
const MAX_IDS_PER_REQUEST = 50;

/**
 * GET /users/batch?ids=1,2,3 (identity-service, công khai)
 * Đổi id tác giả thành tên + avatar để hiện cạnh blog / comment / công thức,
 * vì các service khác chỉ lưu author id.
 * Trả về: [{ id, fullName, avatarUrl }] — user bị khóa/chưa kích hoạt sẽ không có trong kết quả.
 */
export async function getPublicUsers(ids) {
  const uniqueIds = normalizeIds(ids);
  if (uniqueIds.length === 0) return [];

  const responses = await Promise.all(
    chunk(uniqueIds, MAX_IDS_PER_REQUEST).map((part) =>
      apiClient.get("/users/batch", { params: { ids: joinIds(part) } })
    )
  );

  return responses.flatMap((res) => {
    if (res.status >= 400) {
      throw new Error(res.data?.message || "Không lấy được thông tin tác giả");
    }
    return res.data?.result ?? [];
  });
}
