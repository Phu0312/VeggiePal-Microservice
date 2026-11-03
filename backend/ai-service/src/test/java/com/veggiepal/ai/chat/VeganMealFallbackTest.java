package com.veggiepal.ai.chat;

import static org.junit.jupiter.api.Assertions.*;

import java.util.List;
import java.util.Set;
import org.junit.jupiter.api.Test;

class VeganMealFallbackTest {

    @Test
    void defaultComposeReturnsCuratedMeals() {
        String menu = VeganMealFallback.compose(3);
        assertNotNull(menu);
        assertTrue(menu.contains("Bữa 1:"));
        assertTrue(menu.contains("Bữa 2:"));
        assertTrue(menu.contains("Bữa 3:"));
        assertTrue(menu.contains("Nguyên liệu:"));
        assertTrue(menu.contains("Lưu ý"));
    }

    @Test
    void composeWithSoyAllergyReturnsZeroSoyIngredients() {
        DietaryRestrictions soyRestricted = new DietaryRestrictions(
                Set.of("SOY"),
                Set.of("dau nanh", "dau hu", "dau phu", "tau hu", "tempeh", "sua dau nanh", "tau hu ky", "chao", "miso", "nuoc tuong"),
                List.of("đậu nành")
        );

        String menu = VeganMealFallback.compose(3, soyRestricted);
        assertNotNull(menu);
        String lower = menu.toLowerCase();

        assertFalse(lower.contains("đậu hũ"), "Must not contain đậu hũ");
        assertFalse(lower.contains("đậu phụ"), "Must not contain đậu phụ");
        assertFalse(lower.contains("sữa đậu nành"), "Must not contain sữa đậu nành");
        assertFalse(lower.contains("tempeh"), "Must not contain tempeh");
        assertFalse(lower.contains("tàu hũ ky"), "Must not contain tàu hũ ky");
        assertFalse(lower.contains("chao"), "Must not contain chao");

        assertTrue(menu.contains("Bữa 1:"));
        assertTrue(menu.contains("Bữa 2:"));
        assertTrue(menu.contains("Bữa 3:"));
        // Safe soy-free alternatives must be present
        assertTrue(lower.contains("đậu lăng") || lower.contains("đậu gà") || lower.contains("đậu xanh") || lower.contains("đậu đen"));
    }

    @Test
    void composeWithSoyAndPeanutAndSesameAllergiesReturnsSafeMeals() {
        DietaryRestrictions multiRestricted = new DietaryRestrictions(
                Set.of("SOY", "PEANUT", "SESAME"),
                Set.of("dau nanh", "dau hu", "dau phu", "tau hu", "tempeh", "sua dau nanh", "tau hu ky",
                        "dau phong", "lac", "bo dau phong", "bo lac", "me", "vung", "dau me"),
                List.of("đậu nành", "đậu phộng", "mè")
        );

        String menu = VeganMealFallback.compose(3, multiRestricted);
        String lower = menu.toLowerCase();
        String body = lower.substring(lower.indexOf("bữa 1:"));

        assertFalse(body.contains("đậu hũ"));
        assertFalse(body.contains("tempeh"));
        assertFalse(body.contains("đậu phộng"));
        assertFalse(body.contains("lạc"));
        assertFalse(body.contains("mè"));
        assertFalse(body.contains("vừng"));

        assertTrue(menu.contains("Bữa 1:"));
        assertTrue(menu.contains("Bữa 2:"));
        assertTrue(menu.contains("Bữa 3:"));
    }

    @Test
    void composeWhenNoMealsSatisfyExtremeAllergiesReturnsControlledSafeRefusal() {
        // Exclude almost everything
        DietaryRestrictions impossible = new DietaryRestrictions(
                Set.of("SOY", "PEANUT", "SESAME", "GLUTEN", "TREE_NUT", "CASHEW", "MUSHROOM", "CORN", "TOMATO", "CHILI", "MUNG_BEAN"),
                Set.of("dau nanh", "dau hu", "dau ga", "dau lang", "dau den", "dau do", "dau xanh", "gao lut", "yen mach"),
                List.of("tất cả các loại đậu và ngũ cốc")
        );

        String menu = VeganMealFallback.compose(3, impossible);
        assertTrue(menu.contains("Rất tiếc") || menu.contains("không tìm thấy món"));
        assertTrue(menu.contains("bác sĩ") || menu.contains("chuyên gia dinh dưỡng"));
        assertFalse(menu.contains("Bữa 1:"), "Should not invent fake recipes when safety cannot be guaranteed");
    }

    @Test
    void generalAdviceRespectsAllergyRestrictions() {
        DietaryRestrictions soyRestricted = new DietaryRestrictions(
                Set.of("SOY"),
                Set.of("dau nanh", "dau hu", "dau phu", "tau hu", "tempeh", "sua dau nanh", "tau hu ky"),
                List.of("đậu nành")
        );

        String advice = VeganMealFallback.generalAdvice("Bổ sung sắt và canxi cho người ăn chay", soyRestricted);
        String lower = advice.toLowerCase();

        assertFalse(lower.contains("đậu hũ"), "Advice should not recommend đậu hũ when soy allergic");
        assertFalse(lower.contains("sữa đậu nành"), "Advice should not recommend sữa đậu nành when soy allergic");
        assertTrue(lower.contains("đậu lăng") || lower.contains("đậu gà"));
        assertTrue(lower.contains("sữa yến mạch") || lower.contains("canxi"));
    }
}
