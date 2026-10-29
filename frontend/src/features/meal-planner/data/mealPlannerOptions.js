// Lựa chọn tĩnh của form tạo thực đơn và nhãn macro. Đây là cấu hình giao diện, không phải dữ liệu từ BE.

import { Flame, Pencil, Soup, Sparkles } from "lucide-react";

// Khẩu vị gợi ý gửi cho AI qua `preferences`. `label` là chuỗi gửi đi nên viết rõ nghĩa.
export const flavorPreferences = [
  { id: "light", label: "Thanh đạm vị ngọt nhẹ", icon: Sparkles },
  { id: "sea", label: "Đậm đà Đông Nam Á", icon: Pencil },
  { id: "low-oil", label: "Ít dầu mỡ & chiên xào", icon: Flame },
  { id: "no-sugar", label: "Không đường tinh luyện", icon: Sparkles },
  { id: "soup", label: "Chuộng món súp ấm nóng", icon: Soup },
];

export const macroLabels = {
  carb: "Tinh bột chậm",
  protein: "Đạm thực vật",
  fat: "Chất béo tốt",
};
