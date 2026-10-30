import apiClient from "@/shared/api/apiClient";

/**
 * Bộ sưu tập yêu thích và huy hiệu (identity-service qua api-gateway, cần đăng nhập):
 *   GET    /users/me/favorites?type=RECIPE|BLOG|VIDEO
 *   POST   /users/me/favorites { targetType, targetId, title?, imageUrl? }  (thêm, có rồi thì cập nhật)
 *   DELETE /users/me/favorites/:targetType/:targetId
 *   GET    /users/me/badges -> { earnedCount, totalCount, badges: [{ code, title, description, icon, earned, earnedAt }] }
 * POST /users/me/badges/:code chỉ ADMIN gọi được nên FE không dùng: huy hiệu do BE tự cấp
 * (vd VEGGIE_GREEN_HEART khi hoàn thành thử thách 7 ngày).
 */

const VI_MESSAGES = {
  1008: "Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại",
  1018: "Dữ liệu chưa hợp lệ, vui lòng thử lại",
  1031: "Thiếu thông tin nội dung cần lưu",
};

function unwrap(res, fallbackMessage) {
  if (res.status >= 400) {
    throw new Error(VI_MESSAGES[res.data?.code] ?? (res.status === 401 ? VI_MESSAGES[1008] : fallbackMessage));
  }
  return res.data?.result;
}

async function send(request) {
  try {
    return await request();
  } catch (error) {
    throw new Error("Không kết nối được máy chủ, vui lòng thử lại", { cause: error });
  }
}

/** [{ id, targetType, targetId, title, imageUrl, createdAt }] mới lưu trước. `type` bỏ trống = mọi loại. */
export async function getFavorites(type) {
  const res = await send(() => apiClient.get("/users/me/favorites", { params: type ? { type } : {} }));
  return unwrap(res, "Không tải được danh sách yêu thích") ?? [];
}

export async function addFavorite({ targetType, targetId, title, imageUrl }) {
  const res = await send(() =>
    apiClient.post("/users/me/favorites", {
      targetType,
      targetId,
      // BE giới hạn 255 / 512 ký tự; cắt bớt để không bị từ chối vì tiêu đề dài.
      title: title ? title.slice(0, 255) : undefined,
      imageUrl: imageUrl && imageUrl.length <= 512 ? imageUrl : undefined,
    })
  );
  return unwrap(res, "Không lưu được vào yêu thích");
}

export async function removeFavorite({ targetType, targetId }) {
  const res = await send(() => apiClient.delete(`/users/me/favorites/${targetType}/${targetId}`));
  return unwrap(res, "Không bỏ được khỏi yêu thích");
}

export async function getMyBadges() {
  const res = await send(() => apiClient.get("/users/me/badges"));
  return unwrap(res, "Không tải được huy hiệu");
}
