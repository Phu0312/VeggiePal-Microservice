package com.veggiepal.nutrition.service;

import java.math.BigDecimal;
import java.util.*;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.veggiepal.nutrition.entity.*;
import com.veggiepal.nutrition.exception.AppException;
import com.veggiepal.nutrition.exception.ErrorCode;
import com.veggiepal.nutrition.repository.*;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Slf4j
public class MealPlanService {

    private static final String[] MEAL_TYPES = {"BREAKFAST", "LUNCH", "DINNER"};
    private static final int PLAN_DAYS = 7;

    RecipeRepository recipeRepository;
    MealPlanRepository mealPlanRepository;
    HealthRecordRepository healthRecordRepository;
    UserAllergyRepository userAllergyRepository;
    UserIngredientRepository userIngredientRepository;
    AiOperationLogService aiOperationLogService;
    ObjectMapper objectMapper;

    public Map<String, Object> generateMealPlan(Long userId, String goal, List<String> availableIngredients) {

        long startTime = System.currentTimeMillis();

        try {
            // 1. Get latest health record
            HealthRecord healthRecord = healthRecordRepository
                    .findFirstByUserIdOrderByRecordedAtDescIdDesc(userId)
                    .orElse(null);

            BigDecimal bmi = healthRecord != null ? healthRecord.getBmi() : null;

            // 2. Get user allergies
            List<UserAllergy> allergies = userAllergyRepository.findByUserId(userId);
            Set<String> allergenCodes = allergies.stream()
                    .map(a -> a.getAllergen().getCode())
                    .collect(Collectors.toSet());

            // 3. Get available recipes (vegan only)
            List<Recipe> allRecipes = recipeRepository.findByVeganTrue();

            // 4. Filter out recipes containing allergens
            List<Recipe> safeRecipes = allRecipes.stream()
                    .filter(recipe -> {
                        if (recipe.getAllergenCodes() == null || recipe.getAllergenCodes().isBlank()) return true;
                        String[] recipeCodes = recipe.getAllergenCodes().split(",");
                        return Arrays.stream(recipeCodes).map(String::trim).noneMatch(allergenCodes::contains);
                    })
                    .collect(Collectors.toList());

            if (safeRecipes.size() < 3) {
                throw new AppException(ErrorCode.INSUFFICIENT_RECIPES);
            }

            // 5. Categorize by meal type
            Map<String, List<Recipe>> byMealType = new HashMap<>();
            byMealType.put("BREAKFAST", new ArrayList<>());
            byMealType.put("LUNCH", new ArrayList<>());
            byMealType.put("DINNER", new ArrayList<>());

            for (Recipe recipe : safeRecipes) {
                String type = recipe.getMealType().toUpperCase();
                if (byMealType.containsKey(type)) {
                    byMealType.get(type).add(recipe);
                } else {
                    // Multi-purpose recipes go into all categories
                    byMealType.values().forEach(list -> list.add(recipe));
                }
            }

            // Ensure each type has recipes, fill from all if empty
            for (String type : MEAL_TYPES) {
                if (byMealType.get(type).isEmpty()) {
                    byMealType.get(type).addAll(safeRecipes);
                }
            }

            // 6. Prioritize recipes that use available ingredients
            Set<String> ingredientNames = new HashSet<>();
            if (availableIngredients != null) {
                availableIngredients.stream().map(String::toLowerCase).forEach(ingredientNames::add);
            }
            // Also add user's saved ingredients
            userIngredientRepository.findByUserId(userId).stream()
                    .map(i -> i.getName().toLowerCase())
                    .forEach(ingredientNames::add);

            // 7. Adjust calories based on goal
            double calorieMultiplier = switch (goal != null ? goal.toUpperCase() : "MAINTENANCE") {
                case "WEIGHT_LOSS" -> 0.85;
                case "MUSCLE_GAIN" -> 1.15;
                default -> 1.0;
            };

            // 8. Generate 7-day plan
            List<Map<String, Object>> days = new ArrayList<>();
            Random random = new Random(userId); // deterministic per user

            for (int day = 1; day <= PLAN_DAYS; day++) {
                Map<String, Object> dayPlan = new LinkedHashMap<>();
                dayPlan.put("day", day);

                List<Map<String, Object>> meals = new ArrayList<>();
                BigDecimal dailyCalories = BigDecimal.ZERO;

                for (String mealType : MEAL_TYPES) {
                    List<Recipe> candidates = byMealType.get(mealType);

                    // Score by ingredient match
                    Recipe chosen = candidates.stream()
                            .sorted(Comparator.comparingInt((Recipe r) -> scoreIngredientMatch(r, ingredientNames)).reversed()
                                    .thenComparingInt(r -> random.nextInt()))
                            .findFirst()
                            .orElse(candidates.get(random.nextInt(candidates.size())));

                    Map<String, Object> meal = new LinkedHashMap<>();
                    meal.put("mealType", mealType);
                    meal.put("recipeId", chosen.getId());
                    meal.put("recipeName", chosen.getName());
                    meal.put("ingredients", chosen.getIngredients());

                    BigDecimal calories = chosen.getCalories() != null
                            ? chosen.getCalories().multiply(BigDecimal.valueOf(calorieMultiplier))
                            : BigDecimal.ZERO;
                    meal.put("calories", calories.setScale(0, java.math.RoundingMode.HALF_UP));
                    meal.put("protein", chosen.getProtein());
                    meal.put("carbs", chosen.getCarbs());
                    meal.put("fat", chosen.getFat());

                    meals.add(meal);
                    dailyCalories = dailyCalories.add(calories);

                    // Rotate to avoid same recipe every day
                    Collections.rotate(candidates, 1);
                }

                dayPlan.put("meals", meals);
                dayPlan.put("totalCalories", dailyCalories.setScale(0, java.math.RoundingMode.HALF_UP));
                days.add(dayPlan);
            }

            Map<String, Object> result = new LinkedHashMap<>();
            result.put("goal", goal);
            result.put("bmi", bmi);
            result.put("allergenExclusions", allergenCodes);
            result.put("days", days);

            long duration = System.currentTimeMillis() - startTime;
            aiOperationLogService.logOperation("MEAL_PLAN", "LOCAL_DEMO", "SUCCESS", duration, null);

            return result;
        } catch (AppException e) {
            long duration = System.currentTimeMillis() - startTime;
            aiOperationLogService.logOperation("MEAL_PLAN", "LOCAL_DEMO", "FAILURE", duration, e.getMessage());
            throw e;
        }
    }

    public MealPlan saveMealPlan(Long userId, String goal, Map<String, Object> planData) {

        try {
            String json = objectMapper.writeValueAsString(planData);

            MealPlan mealPlan = MealPlan.builder()
                    .userId(userId)
                    .goal(goal)
                    .planData(json)
                    .build();

            return mealPlanRepository.save(mealPlan);
        } catch (JsonProcessingException e) {
            throw new AppException(ErrorCode.UNCATEGORIZED_EXCEPTION);
        }
    }

    public List<MealPlan> getUserMealPlans(Long userId) {
        return mealPlanRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }

    public Map<String, Object> getMealPlanDetail(Long userId, Long planId) {

        MealPlan mealPlan = mealPlanRepository.findByIdAndUserId(planId, userId)
                .orElseThrow(() -> new AppException(ErrorCode.MEAL_PLAN_NOT_FOUND));

        try {
            @SuppressWarnings("unchecked")
            Map<String, Object> data = objectMapper.readValue(mealPlan.getPlanData(), Map.class);
            data.put("id", mealPlan.getId());
            data.put("createdAt", mealPlan.getCreatedAt());
            return data;
        } catch (JsonProcessingException e) {
            throw new AppException(ErrorCode.UNCATEGORIZED_EXCEPTION);
        }
    }

    public Map<String, Object> replaceMeal(Long userId, Long planId, int day, String mealType) {

        MealPlan mealPlan = mealPlanRepository.findByIdAndUserId(planId, userId)
                .orElseThrow(() -> new AppException(ErrorCode.MEAL_PLAN_NOT_FOUND));

        try {
            @SuppressWarnings("unchecked")
            Map<String, Object> data = objectMapper.readValue(mealPlan.getPlanData(), Map.class);

            // Get user allergies
            List<UserAllergy> allergies = userAllergyRepository.findByUserId(userId);
            Set<String> allergenCodes = allergies.stream()
                    .map(a -> a.getAllergen().getCode())
                    .collect(Collectors.toSet());

            // Find safe recipes
            List<Recipe> safeRecipes = recipeRepository.findByVeganTrue().stream()
                    .filter(recipe -> {
                        if (recipe.getAllergenCodes() == null || recipe.getAllergenCodes().isBlank()) return true;
                        String[] recipeCodes = recipe.getAllergenCodes().split(",");
                        return Arrays.stream(recipeCodes).map(String::trim).noneMatch(allergenCodes::contains);
                    })
                    .filter(r -> r.getMealType().equalsIgnoreCase(mealType) || r.getMealType().equalsIgnoreCase("ANY"))
                    .collect(Collectors.toList());

            if (safeRecipes.isEmpty()) {
                safeRecipes = recipeRepository.findByVeganTrue();
            }

            // Pick a random replacement
            Recipe replacement = safeRecipes.get(new Random().nextInt(safeRecipes.size()));

            // Update the plan data
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> days = (List<Map<String, Object>>) data.get("days");
            for (Map<String, Object> dayPlan : days) {
                if (((Number) dayPlan.get("day")).intValue() == day) {
                    @SuppressWarnings("unchecked")
                    List<Map<String, Object>> meals = (List<Map<String, Object>>) dayPlan.get("meals");
                    for (Map<String, Object> meal : meals) {
                        if (mealType.equalsIgnoreCase((String) meal.get("mealType"))) {
                            meal.put("recipeId", replacement.getId());
                            meal.put("recipeName", replacement.getName());
                            meal.put("ingredients", replacement.getIngredients());
                            meal.put("calories", replacement.getCalories());
                            meal.put("protein", replacement.getProtein());
                            meal.put("carbs", replacement.getCarbs());
                            meal.put("fat", replacement.getFat());
                            break;
                        }
                    }
                    break;
                }
            }

            mealPlan.setPlanData(objectMapper.writeValueAsString(data));
            mealPlanRepository.save(mealPlan);

            data.put("id", mealPlan.getId());
            return data;
        } catch (JsonProcessingException e) {
            throw new AppException(ErrorCode.UNCATEGORIZED_EXCEPTION);
        }
    }

    private int scoreIngredientMatch(Recipe recipe, Set<String> ingredientNames) {

        if (ingredientNames.isEmpty() || recipe.getIngredients() == null) return 0;

        String ingredients = recipe.getIngredients().toLowerCase();
        int score = 0;
        for (String name : ingredientNames) {
            if (ingredients.contains(name)) score++;
        }
        return score;
    }
}
