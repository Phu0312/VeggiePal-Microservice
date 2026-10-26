// Khóa cache React Query của feature restaurant-map.
// Tọa độ làm tròn 4 chữ số thập phân (~11 m) để GPS nhích nhẹ không gọi lại API.
const round = (n) => Math.round(n * 1e4) / 1e4;

export const restaurantKeys = {
  all: ["restaurants"],
  nearby: ({ lat, lng, radiusKm, veganOnly }) => [
    "restaurants",
    "nearby",
    { lat: round(lat), lng: round(lng), radiusKm, veganOnly },
  ],
};
