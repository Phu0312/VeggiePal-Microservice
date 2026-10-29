package com.veggiepal.nutrition.service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.veggiepal.nutrition.dto.request.AddWaterRequest;
import com.veggiepal.nutrition.dto.request.DailyActivityRequest;
import com.veggiepal.nutrition.dto.request.FoodLogRequest;
import com.veggiepal.nutrition.dto.response.DailyActivityResponse;
import com.veggiepal.nutrition.dto.response.DailyNutritionSummaryResponse;
import com.veggiepal.nutrition.dto.response.FoodLogResponse;
import com.veggiepal.nutrition.entity.DailyWellnessLog;
import com.veggiepal.nutrition.entity.FoodLog;
import com.veggiepal.nutrition.enums.MealType;
import com.veggiepal.nutrition.exception.AppException;
import com.veggiepal.nutrition.exception.ErrorCode;
import com.veggiepal.nutrition.repository.DailyWellnessLogRepository;
import com.veggiepal.nutrition.repository.FoodLogRepository;
import com.veggiepal.nutrition.repository.HealthRecordRepository;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class DailyTrackingService {

    static final int DEFAULT_TARGET_CALORIES = 2000;
    static final int GLASS_ML = 300;

    FoodLogRepository foodLogRepository;
    DailyWellnessLogRepository dailyWellnessLogRepository;
    HealthRecordRepository healthRecordRepository;

    @Transactional
    public FoodLogResponse addFoodLog(Long userId, FoodLogRequest request) {
        FoodLog log = FoodLog.builder()
                .userId(userId)
                .logDate(resolveDate(request.getLogDate()))
                .mealType(request.getMealType() != null ? request.getMealType() : MealType.SNACK)
                .foodName(request.getFoodName().trim())
                .recipeId(request.getRecipeId())
                .calories(request.getCalories() != null ? request.getCalories() : 0)
                .proteinG(orZero(request.getProteinG()))
                .carbsG(orZero(request.getCarbsG()))
                .fatG(orZero(request.getFatG()))
                .fiberG(orZero(request.getFiberG()))
                .build();

        return toFoodLogResponse(foodLogRepository.save(log));
    }

    @Transactional(readOnly = true)
    public List<FoodLogResponse> getFoodLogs(Long userId, LocalDate date) {
        return foodLogRepository
                .findByUserIdAndLogDateOrderByCreatedAtAsc(userId, resolveDate(date))
                .stream()
                .map(this::toFoodLogResponse)
                .toList();
    }

    @Transactional
    public void deleteFoodLog(Long userId, Long id) {
        FoodLog log = foodLogRepository
                .findByIdAndUserId(id, userId)
                .orElseThrow(() -> new AppException(ErrorCode.FOOD_LOG_NOT_EXISTED));
        foodLogRepository.delete(log);
    }

    @Transactional(readOnly = true)
    public DailyActivityResponse getDailyActivity(Long userId, LocalDate date) {
        LocalDate targetDate = resolveDate(date);
        return dailyWellnessLogRepository
                .findByUserIdAndLogDate(userId, targetDate)
                .map(this::toActivityResponse)
                .orElseGet(() -> emptyActivity(targetDate));
    }

    @Transactional
    public DailyActivityResponse updateDailyActivity(Long userId, DailyActivityRequest request) {
        LocalDate targetDate = resolveDate(request.getDate());
        DailyWellnessLog log = dailyWellnessLogRepository
                .findByUserIdAndLogDate(userId, targetDate)
                .orElseGet(() -> DailyWellnessLog.builder()
                        .userId(userId)
                        .logDate(targetDate)
                        .waterMl(0)
                        .waterTargetMl(DailyWellnessLog.DEFAULT_WATER_TARGET_ML)
                        .exerciseMinutes(0)
                        .steps(0)
                        .caloriesBurned(0)
                        .build());

        if (request.getWaterMl() != null) {
            log.setWaterMl(request.getWaterMl());
        }
        if (request.getWaterTargetMl() != null) {
            log.setWaterTargetMl(request.getWaterTargetMl());
        }
        if (request.getExerciseMinutes() != null) {
            log.setExerciseMinutes(request.getExerciseMinutes());
        }
        if (request.getSteps() != null) {
            log.setSteps(request.getSteps());
        }
        if (request.getCaloriesBurned() != null) {
            log.setCaloriesBurned(request.getCaloriesBurned());
        }
        if (request.getActivityNote() != null) {
            String trimmed = request.getActivityNote().trim();
            log.setActivityNote(trimmed.isEmpty() ? null : trimmed);
        }

        return toActivityResponse(dailyWellnessLogRepository.save(log));
    }

    @Transactional
    public DailyActivityResponse addWater(Long userId, AddWaterRequest request) {
        LocalDate targetDate = resolveDate(request.getDate());
        DailyWellnessLog log = dailyWellnessLogRepository
                .findByUserIdAndLogDate(userId, targetDate)
                .orElseGet(() -> DailyWellnessLog.builder()
                        .userId(userId)
                        .logDate(targetDate)
                        .waterMl(0)
                        .waterTargetMl(DailyWellnessLog.DEFAULT_WATER_TARGET_ML)
                        .exerciseMinutes(0)
                        .steps(0)
                        .caloriesBurned(0)
                        .build());

        log.setWaterMl((log.getWaterMl() != null ? log.getWaterMl() : 0) + request.getAmountMl());
        return toActivityResponse(dailyWellnessLogRepository.save(log));
    }

    @Transactional(readOnly = true)
    public DailyNutritionSummaryResponse getDailySummary(Long userId, LocalDate date) {
        LocalDate targetDate = resolveDate(date);
        List<FoodLogResponse> entries = getFoodLogs(userId, targetDate);
        DailyActivityResponse activity = getDailyActivity(userId, targetDate);

        int consumedCalories = entries.stream()
                .mapToInt(e -> e.getCalories() != null ? e.getCalories() : 0)
                .sum();
        BigDecimal proteinG = sum(entries, FoodLogResponse::getProteinG);
        BigDecimal carbsG = sum(entries, FoodLogResponse::getCarbsG);
        BigDecimal fatG = sum(entries, FoodLogResponse::getFatG);
        BigDecimal fiberG = sum(entries, FoodLogResponse::getFiberG);

        int targetCalories = resolveTargetCalories(userId);
        // Standard balanced plant-based macro split: 50% carbs (4 kcal/g), 20% protein (4 kcal/g), 30% fat (9 kcal/g)
        BigDecimal targetCarbsG = BigDecimal.valueOf(targetCalories * 0.50 / 4.0).setScale(1, RoundingMode.HALF_UP);
        BigDecimal targetProteinG = BigDecimal.valueOf(targetCalories * 0.20 / 4.0).setScale(1, RoundingMode.HALF_UP);
        BigDecimal targetFatG = BigDecimal.valueOf(targetCalories * 0.30 / 9.0).setScale(1, RoundingMode.HALF_UP);

        return DailyNutritionSummaryResponse.builder()
                .date(targetDate)
                .consumedCalories(consumedCalories)
                .targetCalories(targetCalories)
                .remainingCalories(Math.max(0, targetCalories - consumedCalories))
                .caloriesBurned(activity.getCaloriesBurned())
                .proteinG(proteinG)
                .targetProteinG(targetProteinG)
                .carbsG(carbsG)
                .targetCarbsG(targetCarbsG)
                .fatG(fatG)
                .targetFatG(targetFatG)
                .fiberG(fiberG)
                .waterMl(activity.getWaterMl())
                .waterTargetMl(activity.getWaterTargetMl())
                .waterGlasses(activity.getWaterGlasses())
                .exerciseMinutes(activity.getExerciseMinutes())
                .steps(activity.getSteps())
                .activityNote(activity.getActivityNote())
                .entries(entries)
                .build();
    }

    private int resolveTargetCalories(Long userId) {
        return healthRecordRepository
                .findFirstByUserIdOrderByRecordedAtDescIdDesc(userId)
                .map(record -> {
                    int estimated = record.getWeightKg()
                            .multiply(BigDecimal.valueOf(30))
                            .setScale(0, RoundingMode.HALF_UP)
                            .intValue();
                    return Math.max(1400, Math.min(3500, estimated));
                })
                .orElse(DEFAULT_TARGET_CALORIES);
    }

    private FoodLogResponse toFoodLogResponse(FoodLog log) {
        return FoodLogResponse.builder()
                .id(log.getId())
                .logDate(log.getLogDate())
                .mealType(log.getMealType())
                .foodName(log.getFoodName())
                .recipeId(log.getRecipeId())
                .calories(log.getCalories())
                .proteinG(log.getProteinG())
                .carbsG(log.getCarbsG())
                .fatG(log.getFatG())
                .fiberG(log.getFiberG())
                .createdAt(log.getCreatedAt())
                .build();
    }

    private DailyActivityResponse toActivityResponse(DailyWellnessLog log) {
        int waterMl = log.getWaterMl() != null ? log.getWaterMl() : 0;
        int targetMl = log.getWaterTargetMl() != null ? log.getWaterTargetMl() : DailyWellnessLog.DEFAULT_WATER_TARGET_ML;
        return DailyActivityResponse.builder()
                .date(log.getLogDate())
                .waterMl(waterMl)
                .waterTargetMl(targetMl)
                .waterGlasses(waterMl / GLASS_ML)
                .exerciseMinutes(log.getExerciseMinutes() != null ? log.getExerciseMinutes() : 0)
                .steps(log.getSteps() != null ? log.getSteps() : 0)
                .caloriesBurned(log.getCaloriesBurned() != null ? log.getCaloriesBurned() : 0)
                .activityNote(log.getActivityNote())
                .build();
    }

    private static DailyActivityResponse emptyActivity(LocalDate date) {
        return DailyActivityResponse.builder()
                .date(date)
                .waterMl(0)
                .waterTargetMl(DailyWellnessLog.DEFAULT_WATER_TARGET_ML)
                .waterGlasses(0)
                .exerciseMinutes(0)
                .steps(0)
                .caloriesBurned(0)
                .activityNote(null)
                .build();
    }

    private static LocalDate resolveDate(LocalDate date) {
        return date != null ? date : LocalDate.now();
    }

    private static BigDecimal orZero(BigDecimal value) {
        return value != null ? value.setScale(2, RoundingMode.HALF_UP) : BigDecimal.ZERO.setScale(2);
    }

    private static BigDecimal sum(
            List<FoodLogResponse> entries,
            java.util.function.Function<FoodLogResponse, BigDecimal> getter
    ) {
        return entries.stream()
                .map(getter)
                .filter(v -> v != null)
                .reduce(BigDecimal.ZERO, BigDecimal::add)
                .setScale(2, RoundingMode.HALF_UP);
    }
}

