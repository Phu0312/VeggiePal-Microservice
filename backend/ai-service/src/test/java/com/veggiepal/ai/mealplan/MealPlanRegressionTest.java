package com.veggiepal.ai.mealplan;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import java.io.InputStream;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class MealPlanRegressionTest {
    private final ObjectMapper mapper = new ObjectMapper();
    private MealPlanValidator validator;
    private JsonNode seedRecipes;

    @BeforeEach
    void setUp() throws Exception {
        validator = new MealPlanValidator(mapper);
        try (InputStream in = getClass().getResourceAsStream("/mealplan/recipes-seed.json")) {
            assertNotNull(in, "recipes-seed.json must be present");
            seedRecipes = mapper.readTree(in);
        }
    }

    @Test
    void runtimeConfigurationMatchesExpectedDefaults() {
        // Regression: Default serving scale must be [0.75, 1.50], not silently increased to 2.00
        assertEquals(0.75, MealPlanValidator.DEFAULT_MIN_PORTION_SCALE, 0.001);
        assertEquals(1.50, MealPlanValidator.DEFAULT_MAX_PORTION_SCALE, 0.001);
        assertEquals(0.75, validator.minPortionScale(), 0.001);
        assertEquals(1.50, validator.maxPortionScale(), 0.001);
    }

    @Test
    void promptSizeIsReducedToFitWithin2048ContextWindow() throws Exception {
        // Regression: 115 recipes previously generated ~10,329 tokens which was rejected by llama.cpp.
        // Pre-filtering + compact representation must keep prompt well below (2048 - 850) = 1198 tokens.
        MealPlanDtos.GenerateRequest request;
        try (InputStream in = getClass().getResourceAsStream("/mealplan/live-meal-plan-request.json")) {
            request = mapper.readValue(in, MealPlanDtos.GenerateRequest.class);
        }
        ArrayNode candidates = validator.safeCandidates(seedRecipes, mapper.createArrayNode(), request.availableIngredients());
        assertEquals(115, candidates.size());

        ArrayNode promptCandidates = validator.selectPromptCandidates(candidates, request.dailyNutritionTarget());
        assertTrue(promptCandidates.size() <= 20, "Prompt candidates must be bounded, was " + promptCandidates.size());

        ArrayNode promptRecipes = validator.compactPromptCandidates(promptCandidates);
        String recipesJson = mapper.writeValueAsString(promptRecipes);

        String prompt = """
                Tạo thực đơn chay đúng 7 ngày từ danh sách recipe thật. Không tự tạo recipe hoặc ID.
                Mỗi ngày phải có duy nhất BREAKFAST, LUNCH và DINNER. Ưu tiên sở thích và mục tiêu được cung cấp.
                Trả duy nhất JSON {"days":[{"day":"MONDAY","meals":[{"mealType":"BREAKFAST","recipeId":1,"note":"..."}]}]}.
                Mỗi note viết bằng tiếng Việt, một câu ngắn.
                Mục tiêu: %s; sở thích: %s; nguyên liệu sẵn có: %s; sức khỏe: %s; dị ứng đã lọc: %s;
                mục tiêu dinh dưỡng/ngày: %s; recipes an toàn: %s
                """.formatted(request.healthGoal(), request.preferences(), request.availableIngredients(), "{}",
                "[]", request.dailyNutritionTarget(), recipesJson)
                + validator.mealBudgetHint(request.dailyNutritionTarget());

        int utf8Bytes = prompt.getBytes(StandardCharsets.UTF_8).length;
        // Vietnamese + JSON average ~2.5 - 3.5 bytes per Qwen token. 3500 bytes corresponds to ~1000-1100 tokens.
        assertTrue(utf8Bytes < 4000, "Prompt UTF-8 bytes must be < 4000 to safely fit context window, was: " + utf8Bytes);
        assertTrue(prompt.length() < 3000, "Prompt char length must be < 3000, was: " + prompt.length());
    }

    @Test
    void replaceMealPromptIsCompactAndBounded() {
        ArrayNode candidates = validator.safeCandidates(seedRecipes, mapper.createArrayNode(), List.of());
        BigDecimal budget = new BigDecimal("650.00");
        ArrayNode replaceCandidates = validator.selectReplacePromptCandidates(candidates, budget, 104L, 15);
        assertTrue(replaceCandidates.size() <= 15);
        ArrayNode compact = validator.compactPromptCandidates(replaceCandidates);
        assertTrue(compact.size() <= 15);
        for (JsonNode node : compact) {
            assertTrue(node.hasNonNull("id"));
            assertTrue(node.hasNonNull("title"));
            assertTrue(node.hasNonNull("kcal"));
            assertFalse(node.has("ingredients"), "Compact representation omits verbose ingredient lists");
        }
    }

    @Test
    void infeasibleMacroTargetPreservesCalorieTargetMetAndReportsProteinDeviation() {
        // Target requesting 90g protein with 1500-1700 kcal is mathematically infeasible on 115-seed with 1.50x
        MealPlanDtos.NutritionTarget infeasibleTarget = new MealPlanDtos.NutritionTarget(
                new BigDecimal("1500"), new BigDecimal("1700"),
                new BigDecimal("90"), new BigDecimal("130"),
                new BigDecimal("150"), new BigDecimal("210"),
                new BigDecimal("40"), new BigDecimal("60"));
        ObjectNode plan = mapper.createObjectNode();
        validator.validateAndEnrich(plan, seedRecipes, mapper.createArrayNode(), infeasibleTarget, true);

        for (JsonNode day : plan.path("days")) {
            assertTrue(day.path("targetMet").asBoolean(false), "Calorie target must still be met: " + day);
            assertFalse(day.path("allTargetsMet").asBoolean(true), "Infeasible protein target must flag allTargetsMet=false: " + day);
            assertTrue(day.path("targetDeviations").has("protein"), "Deviations must include protein: " + day);
            JsonNode proteinDev = day.path("targetDeviations").path("protein");
            assertEquals(new BigDecimal("90"), proteinDev.path("min").decimalValue());
            // Achieved protein is near-optimal (close to mathematical max 84.8g)
            assertTrue(proteinDev.path("actual").decimalValue().compareTo(new BigDecimal("75.0")) >= 0);
        }
    }

    @Test
    void feasibleMacroTargetMeetsAllTargets() {
        MealPlanDtos.NutritionTarget feasibleTarget = new MealPlanDtos.NutritionTarget(
                new BigDecimal("1500"), new BigDecimal("1700"),
                new BigDecimal("50"), new BigDecimal("85"),
                new BigDecimal("150"), new BigDecimal("210"),
                new BigDecimal("35"), new BigDecimal("60"));
        ObjectNode plan = mapper.createObjectNode();
        validator.validateAndEnrich(plan, seedRecipes, mapper.createArrayNode(), feasibleTarget, true);

        for (JsonNode day : plan.path("days")) {
            assertTrue(day.path("targetMet").asBoolean(false), day.toString());
            assertTrue(day.path("allTargetsMet").asBoolean(false), day.toString());
            assertFalse(day.has("targetDeviations"), "No deviations when all targets met");
        }
    }

    @Test
    void weeklyOptimizationProvidesRecipeDiversityWithoutRepeatingSameThreeRecipes() throws Exception {
        MealPlanDtos.GenerateRequest request;
        try (InputStream in = getClass().getResourceAsStream("/mealplan/live-meal-plan-request.json")) {
            request = mapper.readValue(in, MealPlanDtos.GenerateRequest.class);
        }
        ArrayNode candidates = validator.safeCandidates(seedRecipes, mapper.createArrayNode(), request.availableIngredients());
        ObjectNode plan = mapper.createObjectNode();
        validator.validateAndEnrich(plan, candidates, mapper.createArrayNode(), request.dailyNutritionTarget(), true);

        Set<String> dayCombinations = new HashSet<>();
        Set<Long> weeklyRecipeIds = new HashSet<>();
        for (JsonNode day : plan.path("days")) {
            Set<Long> dayIds = new HashSet<>();
            for (JsonNode meal : day.path("meals")) {
                dayIds.add(meal.path("recipeId").asLong());
                weeklyRecipeIds.add(meal.path("recipeId").asLong());
            }
            assertEquals(3, dayIds.size(), "Each day must have 3 distinct recipes: " + day);
            dayCombinations.add(dayIds.stream().sorted().toList().toString());
        }
        // Regression: Previous fallback repeated the exact same 3 recipes across all 7 days (1 combination, 3 recipes)
        assertTrue(dayCombinations.size() >= 5, "Expected >= 5 distinct daily combinations, got: " + dayCombinations.size());
        assertTrue(weeklyRecipeIds.size() >= 8, "Expected >= 8 distinct weekly recipes, got: " + weeklyRecipeIds.size());
    }
}

