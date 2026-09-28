package com.veggiepal.nutrition.controller;

import java.util.List;
import java.util.Map;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import com.veggiepal.nutrition.dto.response.ApiResponse;
import com.veggiepal.nutrition.entity.MealPlan;
import com.veggiepal.nutrition.service.MealPlanService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@RestController
@RequestMapping("/nutrition/meal-plans")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Tag(name = "Meal Planner", description = "AI-powered personalized 7-day vegan meal planning")
public class MealPlanController {

    MealPlanService mealPlanService;

    @Operation(summary = "Generate a personalized 7-day meal plan")
    @PostMapping("/generate")
    ApiResponse<Map<String, Object>> generateMealPlan(
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
    ApiResponse<MealPlan> saveMealPlan(
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

    @Operation(summary = "List user's saved meal plans")
    @GetMapping
    ApiResponse<List<MealPlan>> getMealPlans(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt
    ) {
        return ApiResponse.<List<MealPlan>>builder()
                .result(mealPlanService.getUserMealPlans(CurrentUser.id(jwt)))
                .build();
    }

    @Operation(summary = "Get meal plan detail")
    @GetMapping("/{id}")
    ApiResponse<Map<String, Object>> getMealPlan(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @PathVariable("id") Long id
    ) {
        return ApiResponse.<Map<String, Object>>builder()
                .result(mealPlanService.getMealPlanDetail(CurrentUser.id(jwt), id))
                .build();
    }

    @Operation(summary = "Replace a meal in a saved plan with another valid recipe")
    @PostMapping("/{id}/replace-meal")
    ApiResponse<Map<String, Object>> replaceMeal(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @PathVariable("id") Long id,
            @RequestBody Map<String, Object> body
    ) {
        int day = ((Number) body.get("day")).intValue();
        String mealType = (String) body.get("mealType");

        return ApiResponse.<Map<String, Object>>builder()
                .result(mealPlanService.replaceMeal(CurrentUser.id(jwt), id, day, mealType))
                .build();
    }
}
