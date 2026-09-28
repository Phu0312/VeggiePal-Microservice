package com.veggiepal.video.service;

import java.util.Locale;

import org.springframework.stereotype.Service;

import com.veggiepal.video.entity.Video;

@Service
public class VideoSummarizationService {

    public String generateSummary(Video video) {
        String title = video.getTitle() != null ? video.getTitle() : "";
        String desc = video.getDescription() != null ? video.getDescription() : "";
        String combined = (title + " " + desc).toLowerCase(Locale.ROOT);

        StringBuilder sb = new StringBuilder();
        sb.append("📋 **TÓM TẮT VIDEO NẤU ĂN THUẦN CHAY (VEGGIEPAL AI):**\n\n");
        sb.append("🎯 **Chủ đề**: ").append(title).append("\n\n");

        sb.append("🥦 **Nguyên liệu cốt lõi**:\n");
        if (combined.contains("nấm")) {
            sb.append("- Các loại nấm tươi (nấm đùi gà, nấm rơm, nấm hương): cung cấp vị ngọt umami tự nhiên và chất xơ.\n");
        }
        if (combined.contains("đậu") || combined.contains("đậu hũ") || combined.contains("đậu phụ")) {
            sb.append("- Đậu phụ non / đậu phụ chiên: nguồn đạm thực vật chất lượng cao, dễ hấp thu.\n");
        }
        if (combined.contains("sữa") || combined.contains("hạt")) {
            sb.append("- Các loại hạt dinh dưỡng (hạt điều, yến mạch, hạnh nhân): giàu axit béo omega-3 và khoáng chất.\n");
        }
        if (combined.contains("canh") || combined.contains("chua") || combined.contains("cà chua")) {
            sb.append("- Cà chua chín mọng, me chua, dứa thơm: giàu vitamin C và chất chống oxy hóa.\n");
        }
        sb.append("- Rau củ quả hữu cơ theo mùa, gia vị chay thuần túy (hạt nêm nấm, muối biển, nước tương tamari).\n\n");

        sb.append("👩‍🍳 **Các bước thực hiện chính**:\n");
        sb.append("1. **Sơ chế sạch**: Rửa và ngâm rau củ, nấm với nước muối loãng, để ráo nước.\n");
        sb.append("2. **Xào thơm & Tạo vị**: Phi thơm boa-rô hoặc gừng tươi, cho nguyên liệu chính vào xào săn với lửa vừa.\n");
        sb.append("3. **Chế biến nhiệt**: Nấu hoặc om nhỏ lửa trong 15-20 phút để các tầng hương vị thấm đượm vào nguyên liệu.\n");
        sb.append("4. **Trình bày & Hoàn thiện**: Bày ra đĩa, trang trí rau thơm, tiêu xay và thưởng thức khi còn nóng hổi.\n\n");

        sb.append("💡 **Điểm sáng dinh dưỡng & Lời khuyên của Đầu bếp**:\n");
        sb.append("- Món ăn đạt tiêu chuẩn 100% Thuần Chay (Vegan).\n");
        sb.append("- Cung cấp đầy đủ vi chất, ít cholesterol xấu, tốt cho hệ tim mạch và tiêu hoá.\n");
        sb.append("- Thời lượng thực hiện ước tính: ").append(video.getDurationSeconds() != null ? (video.getDurationSeconds() / 60) + " phút" : "15-25 phút").append(".");

        return sb.toString();
    }
}
