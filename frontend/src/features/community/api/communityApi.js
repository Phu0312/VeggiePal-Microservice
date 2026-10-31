import { unwrapBlogResponse } from "@/features/blog/api/blogErrors";
import apiClient from "@/shared/api/apiClient";

/**
 * Cộng đồng (blog-service qua api-gateway). Công khai (khách xem được):
 *   GET /blogs/community/trending-topics  [{ categoryId, name, tag, count }]
 *   GET /blogs/community/leaderboard      [{ authorId, articlesCount, videosCount, postsCount, totalLikes, followersCount, following }]
 *   GET /videos/channels                  [{ authorId, videoCount, totalViews, totalLikes, followersCount, following }]
 * Cần đăng nhập:
 *   POST / DELETE /blogs/authors/:id/follow -> { authorId, following, followersCount } (theo dõi chính mình: 3070)
 *   GET  /blogs/me/following                -> [authorId]
 *   GET  /blogs/challenge/me, POST /blogs/challenge/check-in
 *        -> { days, total, checkedToday, completed, broken, justCompleted, completedAt, checkIns, badgeName }
 *        Đủ 7 ngày BE tự cấp huy hiệu VEGGIE_GREEN_HEART; cấp lỗi thì điểm danh vẫn được lưu nhưng BE trả 503 / 3053.
 * Tên / avatar tác giả lấy riêng qua GET /users/batch (usePublicUsers).
 */

async function send(request) {
  try {
    return await request();
  } catch (error) {
    throw new Error("Không kết nối được máy chủ, vui lòng thử lại", { cause: error });
  }
}

export async function getTrendingTopics(limit = 8) {
  const res = await send(() => apiClient.get("/blogs/community/trending-topics", { params: { limit } }));
  return unwrapBlogResponse(res, "Không tải được chủ đề nổi bật") ?? [];
}

export async function getLeaderboard(limit = 5) {
  const res = await send(() => apiClient.get("/blogs/community/leaderboard", { params: { limit } }));
  return unwrapBlogResponse(res, "Không tải được bảng vàng") ?? [];
}

export async function getVideoChannels(limit = 6) {
  const res = await send(() => apiClient.get("/videos/channels", { params: { limit } }));
  return unwrapBlogResponse(res, "Không tải được kênh video") ?? [];
}

export async function followAuthor(authorId) {
  const res = await send(() => apiClient.post(`/blogs/authors/${authorId}/follow`));
  return unwrapBlogResponse(res, "Không theo dõi được tác giả");
}

export async function unfollowAuthor(authorId) {
  const res = await send(() => apiClient.delete(`/blogs/authors/${authorId}/follow`));
  return unwrapBlogResponse(res, "Không bỏ theo dõi được tác giả");
}

export async function getMyFollowing() {
  const res = await send(() => apiClient.get("/blogs/me/following"));
  return unwrapBlogResponse(res, "Không tải được danh sách đang theo dõi") ?? [];
}

export async function getMyChallenge() {
  const res = await send(() => apiClient.get("/blogs/challenge/me"));
  return unwrapBlogResponse(res, "Không tải được tiến độ thử thách");
}

export async function checkInChallenge() {
  const res = await send(() => apiClient.post("/blogs/challenge/check-in"));
  return unwrapBlogResponse(res, "Không điểm danh được, vui lòng thử lại");
}
