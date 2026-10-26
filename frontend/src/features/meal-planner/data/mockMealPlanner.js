// Dữ liệu mẫu còn lại của trang Thực đơn — chỉ cho những khối mà BE CHƯA có API:
// thẻ Nước & Khoáng và thẻ Vận Động.
// Thực đơn, dinh dưỡng, BMI và biểu đồ macro đã lấy từ BE; khi BE bổ sung phần còn lại thì thay các hằng số này.

import { Flame, Pencil, Soup, Sparkles } from "lucide-react";

export const mockStats = [
  {
    id: "water",
    icon: "water",
    label: "Nước & Khoáng",
    value: "1.8",
    unit: "/ 2.4 L",
    caption: "Đã uống 6/8 ly nước mát",
  },
  {
    id: "activity",
    icon: "run",
    label: "Vận Động",
    value: "7,850",
    badge: "78% mục tiêu",
    caption: "Đã đạt 25 phút Yoga sáng",
  },
];

// Khẩu vị gợi ý gửi cho AI qua `preferences`. `label` là chuỗi gửi đi nên viết rõ nghĩa.
export const flavorPreferences = [
  { id: "light", label: "Thanh đạm vị ngọt nhẹ", icon: Sparkles },
  { id: "sea", label: "Đậm đà Đông Nam Á", icon: Pencil },
  { id: "low-oil", label: "Ít dầu mỡ & chiên xào", icon: Flame },
  { id: "no-sugar", label: "Không đường tinh luyện", icon: Sparkles },
  { id: "soup", label: "Chuộng món súp ấm nóng", icon: Soup },
];

// Mô tả thêm gợi ý nhanh, bấm để điền vào ô "Mô tả thêm" (mục tiêu giảm / duy trì / tăng cân chọn riêng bằng nút).
export const healthGoalSuggestions = [
  "Ăn thanh đạm, dễ tiêu hoá",
  "Tăng cơ, nhiều đạm thực vật",
  "Ít dầu mỡ, hạn chế đồ chiên xào",
  "Ăn đủ chất, nhiều rau xanh",
];

export const macroLabels = {
  carb: "Tinh bột chậm",
  protein: "Đạm thực vật",
  fat: "Chất béo tốt",
};

export const dailyAdviceStats = [
  { id: "veggie", label: "Ăn đủ rau xanh", value: "~500g/ngày" },
  { id: "water", label: "Uống đủ nước", value: "2 - 2.5L/ngày" },
  { id: "sleep", label: "Ngủ đủ giấc", value: "7 - 8 giờ/đêm" },
];
