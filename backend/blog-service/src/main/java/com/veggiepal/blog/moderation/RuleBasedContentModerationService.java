package com.veggiepal.blog.moderation;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Service;

import lombok.extern.slf4j.Slf4j;

/**
 * BR-02 & BR-06: Rule-based moderation engine for university lecturer demo.
 * Flags toxic/offensive words for immediate rejection, and non-vegan/meat
 * ingredients for pending admin review, ensuring VeggiePal's 100% vegan standard.
 */
@Service
@Primary
@Slf4j
public class RuleBasedContentModerationService implements ContentModerationService {

    private static final List<String> TOXIC_KEYWORDS = List.of(
            "đm", "đkm", "vcl", "chó chết", "lừa đảo", "khốn nạn", "địt", "đụ", "fuck", "bitch", "scam"
    );

    private static final List<String> NON_VEGAN_KEYWORDS = List.of(
            "thịt bò", "thịt heo", "thịt lợn", "thịt gà", "thịt chó", "thịt mèo",
            "tiết canh", "hải sản", "cá hồi", "tôm hùm", "mực tươi", "sườn heo",
            "nước mắm", "mắm tôm", "mỡ heo", "beef", "pork", "chicken", "seafood"
    );

    @Override
    public ModerationResult moderate(String text) {
        if (text == null || text.isBlank()) {
            return ModerationResult.approved();
        }

        String lowerText = text.toLowerCase(Locale.ROOT);

        // 1. Check for toxic / offensive content -> Immediate REJECT
        List<String> matchedToxic = new ArrayList<>();
        for (String word : TOXIC_KEYWORDS) {
            if (containsWord(lowerText, word)) {
                matchedToxic.add(word);
            }
        }
        if (!matchedToxic.isEmpty()) {
            String keywords = String.join(", ", matchedToxic);
            log.info("Content rejected due to toxic keywords: {}", keywords);
            return new ModerationResult(
                    ModerationDecision.REJECTED,
                    "Nội dung vi phạm tiêu chuẩn cộng đồng do chứa từ ngữ thô tục/xúc phạm (" + keywords + ")",
                    keywords
            );
        }

        // 2. Check for non-vegan ingredients -> PENDING admin review (BR-06)
        List<String> matchedNonVegan = new ArrayList<>();
        for (String word : NON_VEGAN_KEYWORDS) {
            if (containsWord(lowerText, word)) {
                matchedNonVegan.add(word);
            }
        }
        if (!matchedNonVegan.isEmpty()) {
            String keywords = String.join(", ", matchedNonVegan);
            log.info("Content flagged for admin review due to non-vegan keywords: {}", keywords);
            return new ModerationResult(
                    ModerationDecision.PENDING,
                    "Phát hiện nguyên liệu không thuần chay (" + keywords + "). Cần quản trị viên kiểm duyệt trước khi công khai.",
                    keywords
            );
        }

        return ModerationResult.approved();
    }

    private boolean containsWord(String text, String word) {
        return text.contains(word);
    }
}
