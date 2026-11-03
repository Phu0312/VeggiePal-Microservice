package com.veggiepal.ai.chat;

import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.Test;

class ChatOutputGuardTest {
    @Test
    void exactSwaggerFailureLoopIsDetected() {
        String loop = "Bữa 1: 100g đậu xanh, 100g đậu đen, 100g đậu gà, 100g đậu lăng, 100g đậu đỏ, "
                .repeat(10);
        var issues = ChatOutputGuard.assess(loop, "length");
        assertTrue(issues.contains(ChatOutputGuard.Issue.REPETITION_LOOP));
        assertTrue(issues.contains(ChatOutputGuard.Issue.TRUNCATED));
    }

    @Test
    void legitimateRepeatedTermsAreNotFlagged() {
        String text = """
                - Đậu hũ giàu đạm, đậu nành giàu đạm, tempeh giàu đạm và đậu lăng giàu đạm.
                - Kết hợp đậu với gạo lứt, đậu với yến mạch và đậu với rau xanh.
                - Nguyên liệu: đậu hũ; nguyên liệu: tempeh; nguyên liệu: nấm.
                - Tránh thịt, cá và trứng; thay thế bằng đậu hũ.""";
        assertTrue(ChatOutputGuard.assess(text, "stop").isEmpty());
    }

    @Test
    void educationalNegatedAnimalMentionAndChickpeaAreNotAnimalIngredients() {
        assertFalse(ChatOutputGuard.containsAffirmativeAnimalIngredient(
                "Người ăn thuần chay tránh thịt, cá, trứng và dùng đậu gà, mỡ máu thấp nhờ chất xơ, tốt cho cá nhân."));
        assertFalse(ChatOutputGuard.containsAffirmativeAnimalIngredient("Dùng tôm chay và nước mắm chay từ nấm."));
        assertTrue(ChatOutputGuard.containsAffirmativeAnimalIngredient("Nguyên liệu: 100g tôm, 500g thịt gà"));
    }

    @Test
    void identicalMealsAreDuplicatesButDistinctMealsAreNot() {
        String dup = """
                Bữa 1:
                - Nguyên liệu: 200g đậu hũ, 100g gạo lứt, 100g đậu lăng, 100g nấm
                Bữa 2:
                - Nguyên liệu: 200g đậu hũ, 100g gạo lứt, 100g đậu lăng, 100g nấm""";
        assertTrue(ChatOutputGuard.hasDuplicateMeals(dup));
        String distinct = """
                Bữa 1: Cơm đậu hũ
                - Nguyên liệu: 150g đậu hũ, 80g gạo lứt, 2 quả cà chua
                Bữa 2: Yến mạch sữa đậu nành
                - Nguyên liệu: 50g yến mạch, 250ml sữa đậu nành, 20g hạt bí""";
        assertFalse(ChatOutputGuard.hasDuplicateMeals(distinct));
    }

    @Test
    void excessiveIngredientListsAndForeignScriptAreFlagged() {
        StringBuilder sb = new StringBuilder("Bữa 1:\n");
        for (int i = 0; i < 12; i++) {
            sb.append("- ").append(100 + i).append("g nguyên liệu số ").append(i).append('\n');
        }
        assertTrue(ChatOutputGuard.hasExcessiveList(sb.toString()));
        assertTrue(ChatOutputGuard.assess("Bữa晚餐: đậu hũ", "stop").contains(ChatOutputGuard.Issue.FOREIGN_SCRIPT));
    }

    @Test
    void trimRepetitionKeepsFirstOccurrencesOnly() {
        String trimmed = ChatOutputGuard.trimRepetition(
                "- Ưu tiên đậu hũ, tempeh, đậu nành\n- Kiểm soát lượng đường trong máu\n- Kiểm soát lượng đường trong máu\n"
                        + "- Kiểm soát lượng đường trong máu", false);
        assertEquals(1, trimmed.split("Kiểm soát").length - 1);
    }

    @Test
    void mealRequestDetectionAndCount() {
        assertTrue(ChatOutputGuard.isMealSuggestionRequest("Gợi ý 3 bữa ăn thuần chay giúp tăng cơ"));
        assertTrue(ChatOutputGuard.isMealSuggestionRequest("Goi y 3 bua an thuan chay"));
        assertFalse(ChatOutputGuard.isMealSuggestionRequest("Bổ sung sắt cho người ăn chay?"));
        assertEquals(3, ChatOutputGuard.requestedMealCount("Gợi ý 3 bữa ăn"));
        assertEquals(2, ChatOutputGuard.requestedMealCount("cho tôi 2 món chay"));
        assertEquals(3, ChatOutputGuard.requestedMealCount("gợi ý bữa ăn"));
    }

    @Test
    void inventedNutritionFiguresAreFlaggedOnlyForMealRequests() {
        String text = "Bữa 1: Cơm đậu hũ\n- Nguyên liệu: 150g đậu hũ, 80g gạo lứt\n- Dinh dưỡng: 386kcal, 47g protein";
        assertTrue(ChatOutputGuard.assess(text, "stop", true).contains(ChatOutputGuard.Issue.INVENTED_NUTRITION));
        assertFalse(ChatOutputGuard.assess(text, "stop", false).contains(ChatOutputGuard.Issue.INVENTED_NUTRITION));
    }

    @Test
    void overlongBulletAnswerIsOnlyASoftIssue() {
        StringBuilder sb = new StringBuilder();
        for (int i = 1; i <= 10; i++) {
            sb.append(i).append(". ").append(new String[] {"Ăn đậu hũ", "Uống sữa đậu nành", "Thêm rau cải", "Dùng nấm hương", "Chọn gạo lứt", "Ăn hạt điều", "Nấu canh bí", "Hấp khoai lang", "Trộn salad cà chua", "Nướng tempeh"}[i - 1]).append(" mỗi ngày\n");
        }
        var issues = ChatOutputGuard.assess(sb.toString(), "stop", false);
        assertEquals(java.util.Set.of(ChatOutputGuard.Issue.TOO_MANY_ITEMS), issues);
        assertTrue(issues.stream().allMatch(ChatOutputGuard.Issue::isSoft));
    }

    @Test
    void allergenViolationDetectedWhenExcludedAllergenIsAffirmativelyRecommended() {
        DietaryRestrictions soyRestricted = new DietaryRestrictions(
                java.util.Set.of("SOY"),
                java.util.Set.of("dau nanh", "dau hu", "dau phu", "tau hu", "tempeh", "sua dau nanh", "tau hu ky"),
                java.util.List.of("đậu nành")
        );

        String violatingMeal = """
                Bữa 1: Cơm gạo lứt với đậu hũ sốt cà chua
                - Nguyên liệu: 150g đậu hũ, 80g gạo lứt
                - Vì sao phù hợp: Đậu hũ giàu đạm.""";
        var issues = ChatOutputGuard.assess(violatingMeal, "stop", true, soyRestricted);
        assertTrue(issues.contains(ChatOutputGuard.Issue.ALLERGEN_VIOLATION),
                "Meal with đậu hũ must trigger ALLERGEN_VIOLATION when soy is restricted");
    }

    @Test
    void educationalOrWarningMentionOfAllergenDoesNotTriggerAllergenViolation() {
        DietaryRestrictions soyRestricted = new DietaryRestrictions(
                java.util.Set.of("SOY"),
                java.util.Set.of("dau nanh", "dau hu", "dau phu", "tau hu", "tempeh", "sua dau nanh", "tau hu ky"),
                java.util.List.of("đậu nành")
        );

        String educationalAdvice = "Bạn bị dị ứng đậu nành nên cần tránh đậu hũ, tempeh và sữa đậu nành; thay thế bằng đậu gà và đậu lăng.";
        var issues = ChatOutputGuard.assess(educationalAdvice, "stop", false, soyRestricted);
        assertFalse(issues.contains(ChatOutputGuard.Issue.ALLERGEN_VIOLATION),
                "Educational warnings explicitly advising to avoid the allergen must NOT be flagged as violations");
    }

    @Test
    void duplicateMealWithRepeatedTitleOrSimilarDishIsDetected() {
        String repeatedTitle = """
                Bữa 1: Cà ri đậu lăng đỏ với cơm gạo lứt
                - Nguyên liệu: 100g đậu lăng đỏ, 80g gạo lứt, cà chua
                Bữa 2: Cà ri đậu lăng đỏ với cơm gạo lứt
                - Nguyên liệu: 100g đậu lăng đỏ, 80g gạo lứt, dưa leo""";
        assertTrue(ChatOutputGuard.hasDuplicateMeals(repeatedTitle), "Identical title must be detected as duplicate");

        String similarDish = """
                Bữa 1: Cà ri đậu lăng đỏ thơm ngon
                - Nguyên liệu: 100g đậu lăng đỏ, 80g gạo lứt, nước cốt dừa, bột cà ri
                Bữa 2: Cà ri đậu lăng đỏ bí đỏ
                - Nguyên liệu: 100g đậu lăng đỏ, 80g gạo lứt, bí đỏ, bột cà ri""";
        assertTrue(ChatOutputGuard.hasDuplicateMeals(similarDish), "Near-identical title/composition must be detected as duplicate");
    }
}
