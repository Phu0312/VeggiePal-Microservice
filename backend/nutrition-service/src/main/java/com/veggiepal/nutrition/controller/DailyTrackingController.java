package com.veggiepal.nutrition.controller;

import java.time.LocalDate;
import java.util.List;

import jakarta.validation.Valid;

import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.veggiepal.nutrition.dto.request.AddWaterRequest;
import com.veggiepal.nutrition.dto.request.DailyActivityRequest;
import com.veggiepal.nutrition.dto.request.FoodLogRequest;
import com.veggiepal.nutrition.dto.response.ApiResponse;
import com.veggiepal.nutrition.dto.response.DailyActivityResponse;
import com.veggiepal.nutrition.dto.response.DailyNutritionSummaryResponse;
import com.veggiepal.nutrition.dto.response.FoodLogResponse;
import com.veggiepal.nutrition.service.DailyTrackingService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@RestController
@RequestMapping("/nutrition/me")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Tag(name = "Daily Tracking", description = "Food diary, today's nutrition summary, water & exercise tracking")
public class DailyTrackingController {

    DailyTrackingService dailyTrackingService;

    @Operation(summary = "Log a meal or food item into the daily food diary")
    @PostMapping("/food-logs")
    ApiResponse<FoodLogResponse> addFoodLog(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @RequestBody @Valid FoodLogRequest request
    ) {
        return ApiResponse.<FoodLogResponse>builder()
                .result(dailyTrackingService.addFoodLog(CurrentUser.id(jwt), request))
                .build();
    }

    @Operation(summary = "List food diary entries for a date (defaults to today)")
    @GetMapping("/food-logs")
    ApiResponse<List<FoodLogResponse>> getFoodLogs(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @RequestParam(name = "date", required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date
    ) {
        return ApiResponse.<List<FoodLogResponse>>builder()
                .result(dailyTrackingService.getFoodLogs(CurrentUser.id(jwt), date))
                .build();
    }

    @Operation(summary = "Delete a food diary entry")
    @DeleteMapping("/food-logs/{id}")
    ApiResponse<Void> deleteFoodLog(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @PathVariable("id") Long id
    ) {
        dailyTrackingService.deleteFoodLog(CurrentUser.id(jwt), id);
        return ApiResponse.<Void>builder().build();
    }

    @Operation(summary = "Get daily water intake and physical activity tracking for a date")
    @GetMapping("/daily-activity")
    ApiResponse<DailyActivityResponse> getDailyActivity(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @RequestParam(name = "date", required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date
    ) {
        return ApiResponse.<DailyActivityResponse>builder()
                .result(dailyTrackingService.getDailyActivity(CurrentUser.id(jwt), date))
                .build();
    }

    @Operation(summary = "Upsert daily water intake and exercise tracking")
    @PutMapping("/daily-activity")
    ApiResponse<DailyActivityResponse> updateDailyActivity(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @RequestBody @Valid DailyActivityRequest request
    ) {
        return ApiResponse.<DailyActivityResponse>builder()
                .result(dailyTrackingService.updateDailyActivity(CurrentUser.id(jwt), request))
                .build();
    }

    @Operation(summary = "Quickly add water intake (e.g. +300ml glass)")
    @PostMapping("/water")
    ApiResponse<DailyActivityResponse> addWater(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @RequestBody @Valid AddWaterRequest request
    ) {
        return ApiResponse.<DailyActivityResponse>builder()
                .result(dailyTrackingService.addWater(CurrentUser.id(jwt), request))
                .build();
    }

    @Operation(summary = "Get today's nutrition summary combining food diary totals, macro targets, water and exercise")
    @GetMapping("/daily-summary")
    ApiResponse<DailyNutritionSummaryResponse> getDailySummary(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @RequestParam(name = "date", required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date
    ) {
        return ApiResponse.<DailyNutritionSummaryResponse>builder()
                .result(dailyTrackingService.getDailySummary(CurrentUser.id(jwt), date))
                .build();
    }
}

