// Khóa cache của trang Cộng đồng. Bảng vàng và kênh video có cờ `following` theo người xem nên
// cùng tiền tố `authors` để theo dõi / bỏ theo dõi xong làm mới một lần.
export const communityKeys = {
  stats: ["community", "stats"],
  topics: (limit) => ["community", "topics", limit],
  authors: ["community", "authors"],
  leaderboard: (limit) => ["community", "authors", "leaderboard", limit],
  channels: (limit) => ["community", "authors", "channels", limit],
  following: ["community", "authors", "following"],
  challenge: ["community", "challenge"],
};
