// Khóa cache React Query của feature profile + nutrition (dữ liệu của user hiện tại).
// Khóa dạng mảng phân cấp: invalidateQueries({ queryKey: profileKeys.healthRecords })
// sẽ làm mới cả "latest" lẫn "history" vì cùng tiền tố.
export const profileKeys = {
  me: ["profile", "me"],
  allergens: ["nutrition", "allergens"],
  myAllergies: ["nutrition", "my-allergies"],
  healthRecords: ["nutrition", "health-records"],
  latestHealthRecord: ["nutrition", "health-records", "latest"],
  healthHistory: (size) => ["nutrition", "health-records", "history", { size }],
  // Yêu thích và huy hiệu (identity-service /users/me/favorites, /users/me/badges).
  favoritesRoot: ["profile", "favorites"],
  favorites: (type) => ["profile", "favorites", type],
  badges: ["profile", "badges"],
};
