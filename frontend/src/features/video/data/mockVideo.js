// Dữ liệu mẫu tham khảo cho các tính năng chưa có endpoint backend riêng
// (nutrition facts, kênh ẩm thực đề xuất).

export const nutritionFacts = {
  servingLabel: "1 bát tiêu chuẩn",
  kcal: 315,
  protein: "16.5g",
  fiber: "7.8g",
  ingredients: [
    { id: "banh-pho", name: "Bánh phở lứt huyết rồng", amount: "250g" },
    { id: "nam", name: "Nấm hương tươi & Nấm đùi gà", amount: "180g" },
    { id: "thao-moc", name: "Thảo mộc: Hoa hồi, quế, thảo quả", amount: "1 gói nhỏ" },
  ],
};

export const videoChannels = [
  { id: "an", label: "Bếp Chay An Nhiên", initials: "AN", avatarClass: "bg-[#1D6C3D]" },
  { id: "yv", label: "Bếp Nhỏ Yên Vui", initials: "YV", avatarClass: "bg-[#E38B29]" },
  { id: "mc", label: "Mộc Chay Kitchen", initials: "MC", avatarClass: "bg-[#4B5563]" },
  { id: "tm", label: "Chef Tuệ Mẫn", initials: "TM", avatarClass: "bg-[#1D8A6E]" },
  { id: "sv", label: "Bếp Sen Vàng", initials: "SV", avatarClass: "bg-[#2E7D4F]" },
  { id: "sk", label: "Sống Khỏe Cùng Hạt", initials: "SK", avatarClass: "bg-[#E3A72D]" },
  { id: "gl", label: "GreenLife Vietnam", initials: "GL", avatarClass: "bg-[#1D8A6E]" },
];
