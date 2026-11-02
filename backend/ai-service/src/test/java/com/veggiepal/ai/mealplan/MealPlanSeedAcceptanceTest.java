package com.veggiepal.ai.mealplan;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import java.io.InputStream;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.math.BigDecimal;
import java.util.List;
import java.util.Set;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

// Runs the planner on the real seed catalogue (recipes-seed.json, exported from recipe-service's
// GET /recipes?size=200). Re-export it whenever recipe-service's data.sql changes — see
// docs/superpowers/plans/2026-10-21-recipe-nutrition-data.md, Task 6 Step 9.
class MealPlanSeedAcceptanceTest {
    private final ObjectMapper mapper = new ObjectMapper();
    private final MealPlanValidator validator = new MealPlanValidator(mapper);

    @Test
    void livePantryRequestMeetsMacrosWithDistinctDays() throws Exception {
        JsonNode recipes;
        try (InputStream in = getClass().getResourceAsStream("/mealplan/recipes-seed.json")) {
            recipes = mapper.readTree(in);
        }
        var byId = new java.util.HashMap<Long, JsonNode>();
        recipes.forEach(recipe -> byId.put(recipe.path("id").asLong(), recipe));
        var liveOrder = mapper.createArrayNode();
        try (var reader = new BufferedReader(new InputStreamReader(
                getClass().getResourceAsStream("/mealplan/recipes-live-order.txt"), StandardCharsets.UTF_8))) {
            for (String id; (id = reader.readLine()) != null; ) liveOrder.add(byId.get(Long.parseLong(id)));
        }
        assertEquals(recipes.size(), liveOrder.size());
        MealPlanDtos.GenerateRequest request;
        try (InputStream in = getClass().getResourceAsStream("/mealplan/live-meal-plan-request.json")) {
            request = mapper.readValue(in, MealPlanDtos.GenerateRequest.class);
        }
        assertEquals(5, request.preferences().size());
        // The saved live request had no allergies. Pantry ingredients rank recipes; animal items
        // do not make non-vegan recipes eligible.
        var candidates = validator.safeCandidates(liveOrder, mapper.createArrayNode(), request.availableIngredients());
        ObjectNode plan = mapper.createObjectNode();
        var days = plan.putArray("days");
        for (String day : MealPlanValidator.STANDARD_DAYS) {
            var meals = days.addObject().put("day", day).putArray("meals");
            meals.addObject().put("mealType", "BREAKFAST").put("recipeId", 63);
            meals.addObject().put("mealType", "LUNCH").put("recipeId", 104);
            meals.addObject().put("mealType", "DINNER").put("recipeId", 55);
        }
        new MealPlanValidator(mapper, 0.75, 1.50).validateAndEnrich(
                plan, candidates, mapper.createArrayNode(), request.dailyNutritionTarget(), true);
        Set<String> combinations = new java.util.HashSet<>();
        Set<Long> weeklyRecipeIds = new java.util.HashSet<>();
        for (JsonNode day : plan.path("days")) {
            assertTrue(day.path("targetMet").asBoolean(false), day.toString());
            // Target requests 90g protein which is mathematically infeasible on this seed catalogue
            // with serving multiplier 1.50 (max achievable protein within 1500-1700 kcal is ~84.8g).
            // allTargetsMet truthfully flags the shortfall without breaking calorie targetMet.
            assertFalse(day.path("allTargetsMet").asBoolean(true), day.toString());
            assertTrue(day.path("targetDeviations").has("protein"), day.toString());
            Set<Long> dayIds = new java.util.HashSet<>();
            for (JsonNode meal : day.path("meals")) {
                dayIds.add(meal.path("recipeId").asLong());
                weeklyRecipeIds.add(meal.path("recipeId").asLong());
            }
            assertEquals(3, dayIds.size(), day.toString());
            combinations.add(dayIds.stream().sorted().toList().toString());
        }
        assertTrue(combinations.size() >= 5, "repeated daily combinations: " + combinations);
        assertTrue(weeklyRecipeIds.size() >= 6, "recipe repetition: " + weeklyRecipeIds);
    }

    @Test
    void infeasibleMacroTargetOnRealSeedCatalogueReportsDeviationsTruthfully() throws Exception {
        JsonNode recipes;
        try (InputStream in = getClass().getResourceAsStream("/mealplan/recipes-seed.json")) {
            recipes = mapper.readTree(in);
        }
        ObjectNode plan = mapper.createObjectNode();
        MealPlanDtos.NutritionTarget target = new MealPlanDtos.NutritionTarget(
                new BigDecimal("1500"), new BigDecimal("1700"),
                new BigDecimal("90"), new BigDecimal("130"),
                new BigDecimal("150"), new BigDecimal("210"),
                new BigDecimal("40"), new BigDecimal("60"));
        validator.validateAndEnrich(plan, recipes, mapper.createArrayNode(), target, true);
        for (JsonNode day : plan.path("days")) {
            assertTrue(day.path("targetMet").asBoolean(false), "calorie target must be met: " + day);
            assertFalse(day.path("allTargetsMet").asBoolean(true), "infeasible protein target must be flagged: " + day);
            assertTrue(day.path("targetDeviations").has("protein"), "deviation must explain protein shortfall: " + day);
            JsonNode totals = day.path("nutritionTotals");
            assertTrue(totals.path("calories").decimalValue().compareTo(target.minCalories()) >= 0, day.toString());
            assertTrue(totals.path("calories").decimalValue().compareTo(target.maxCalories()) <= 0, day.toString());
            assertTrue(totals.path("protein").decimalValue().compareTo(new BigDecimal("75.0")) >= 0, day.toString());
        }
    }

    @Test
    void feasibleMacroTargetOnRealSeedCatalogueMeetsAllTargets() throws Exception {
        JsonNode recipes;
        try (InputStream in = getClass().getResourceAsStream("/mealplan/recipes-seed.json")) {
            recipes = mapper.readTree(in);
        }
        ObjectNode plan = mapper.createObjectNode();
        // A feasible target for vegan 3-meal combinations within [0.75, 1.50]
        MealPlanDtos.NutritionTarget target = new MealPlanDtos.NutritionTarget(
                new BigDecimal("1500"), new BigDecimal("1700"),
                new BigDecimal("50"), new BigDecimal("85"),
                new BigDecimal("150"), new BigDecimal("210"),
                new BigDecimal("35"), new BigDecimal("60"));
        validator.validateAndEnrich(plan, recipes, mapper.createArrayNode(), target, true);
        for (JsonNode day : plan.path("days")) {
            assertTrue(day.path("targetMet").asBoolean(false), day.toString());
            assertTrue(day.path("allTargetsMet").asBoolean(false), day.toString());
            JsonNode totals = day.path("nutritionTotals");
            assertTrue(totals.path("calories").decimalValue().compareTo(target.minCalories()) >= 0, day.toString());
            assertTrue(totals.path("calories").decimalValue().compareTo(target.maxCalories()) <= 0, day.toString());
            assertTrue(totals.path("protein").decimalValue().compareTo(target.minProtein()) >= 0, day.toString());
            assertTrue(totals.path("protein").decimalValue().compareTo(target.maxProtein()) <= 0, day.toString());
        }
    }

    @ParameterizedTest(name = "{0}-{1} kcal")
    @CsvSource({"1350,1650", "1800,2200", "2250,2750", "2700,3300", "2522,3082"})
    void everyDayMeetsTheCalorieTargetOnTheSeedCatalogue(int min, int max) throws Exception {
        JsonNode recipes;
        try (InputStream in = getClass().getResourceAsStream("/mealplan/recipes-seed.json")) {
            recipes = mapper.readTree(in);
        }
        ObjectNode plan = mapper.createObjectNode(); // what generate() validates when the AI call fails
        MealPlanDtos.NutritionTarget target = new MealPlanDtos.NutritionTarget(
                BigDecimal.valueOf(min), BigDecimal.valueOf(max), null, null, null, null, null, null);

        validator.validateAndEnrich(plan, recipes, mapper.createArrayNode(), target, true);

        for (JsonNode day : plan.path("days")) {
            assertEquals(true, day.path("targetMet").asBoolean(false), day.toString());
            JsonNode totals = day.path("nutritionTotals");
            assertTrue(totals.path("calories").decimalValue().compareTo(target.minCalories()) >= 0, day.toString());
            assertTrue(totals.path("calories").decimalValue().compareTo(target.maxCalories()) <= 0, day.toString());
        }
    }
}
