// Dữ liệu demo cho các khối phụ của trang Cộng đồng (/blog) mà BE chưa có API:
// số liệu cộng đồng, lời nhắn Bé Bông Cải, bảng vàng, chủ đề hot, thử thách.
// Bài viết đã lấy từ API thật (useBlogFeed), không còn nằm ở đây.

export const communityStats = [
  { id: "recipes", icon: "book", value: "12.4k", label: "Công thức chia sẻ" },
  { id: "experts", icon: "check", value: "3.8k", label: "Bếp trưởng & Chuyên gia" },
  { id: "safe", icon: "shield", value: "98.6%", label: "Duyệt AI an toàn Macro" },
];

export const broccoliQuote = {
  label: "Bé Bông Cải nhắn nhủ",
  quote: "“Ăn trọn vị, sống trọn an lành!”",
  hint: "Sẵn sàng phân tích dinh dưỡng cùng bạn",
};

export const leaderboard = [
  { id: 1, name: "Bếp Chay Yên Vui", recipes: 38, likes: "4.8k", following: false },
  { id: 2, name: "Minh Thuận", recipes: 29, likes: "3.2k", following: true },
  { id: 3, name: "BS. Diệu Hiếu", articles: 14, likes: "2.9k", following: false },
];

export const trendingTopics = [
  { id: "mealprep", tag: "MealPrepChay", count: "1.2k" },
  { id: "diet", tag: "DiamCanLanhManh", count: "890" },
  { id: "broccoli", tag: "BongCaiCare", count: "640" },
  { id: "wfpb", tag: "WFPB_Vietnam", count: "2.4k" },
  { id: "hat", tag: "SuaHatTuNhien", count: "520" },
];
