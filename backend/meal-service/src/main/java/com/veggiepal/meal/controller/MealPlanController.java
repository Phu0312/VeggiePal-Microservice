package com.veggiepal.meal.controller;

import java.util.List;
import java.util.Map;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import com.veggiepal.meal.configuration.CurrentUser;
import com.veggiepal.meal.dto.response.ApiResponse;
import com.veggiepal.meal.entity.MealPlan;
import com.veggiepal.meal.service.MealPlanService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@RestController
@RequestMapping({"/nutrition/meal-plans", "/meal/meal-plans"})
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Tag(name = "Meal Planner", description = "Personalized 7-day vegan meal planning and replacement")
public class MealPlanController {

    MealPlanService mealPlanService;

    @Operation(summary = "Generate a personalized 7-day meal plan")
    @PostMapping("/generate")
    public ApiResponse<Map<String, Object>> generateMealPlan(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @RequestBody Map<String, Object> body
    ) {
        String goal = (String) body.get("goal");
        @SuppressWarnings("unchecked")
        List<String> ingredients = (List<String>) body.get("availableIngredients");

        return ApiResponse.<Map<String, Object>>builder()
                .result(mealPlanService.generateMealPlan(CurrentUser.id(jwt), goal, ingredients))
                .build();
    }

    @Operation(summary = "Save a generated meal plan")
    @PostMapping
    public ApiResponse<MealPlan> saveMealPlan(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @RequestBody Map<String, Object> body
    ) {
        String goal = (String) body.get("goal");
        @SuppressWarnings("unchecked")
        Map<String, Object> planData = (Map<String, Object>) body.get("planData");

        return ApiResponse.<MealPlan>builder()
                .result(mealPlanService.saveMealPlan(CurrentUser.id(jwt), goal, planData))
                .build();
    }

    @Operation(summary = "Get user's saved meal plans")
    @GetMapping
    public ApiResponse<List<MealPlan>> getUserMealPlans(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt
    ) {
        return ApiResponse.<List<MealPlan>>builder()
                .result(mealPlanService.getUserMealPlans(CurrentUser.id(jwt)))
                .build();
    }

    @Operation(summary = "Get meal plan detail by ID")
    @GetMapping("/{id}")
    public ApiResponse<Map<String, Object>> getMealPlanDetail(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @PathVariable Long id
    ) {
        return ApiResponse.<Map<String, Object>>builder()
                .result(mealPlanService.getMealPlanDetail(CurrentUser.id(jwt), id))
                .build();
    }

    @Operation(summary = "Replace a meal on a specific day in the plan")
    @PostMapping("/{id}/replace-meal")
    public ApiResponse<Map<String, Object>> replaceMeal(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @PathVariable Long id,
            @RequestBody Map<String, Object> body
    ) {
        int day = ((Number) body.get("day")).intValue();
        String mealType = (String) body.get("mealType");

        return ApiResponse.<Map<String, Object>>builder()
                .result(mealPlanService.replaceMeal(CurrentUser.id(jwt), id, day, mealType))
                .build();
    }
}
