package com.veggiepal.nutrition.dto.response;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class DailyNutritionSummaryResponse {

    LocalDate date;
    Integer consumedCalories;
    Integer targetCalories;
    Integer remainingCalories;
    Integer caloriesBurned;
    BigDecimal proteinG;
    BigDecimal targetProteinG;
    BigDecimal carbsG;
    BigDecimal targetCarbsG;
    BigDecimal fatG;
    BigDecimal targetFatG;
    BigDecimal fiberG;
    Integer waterMl;
    Integer waterTargetMl;
    Integer waterGlasses;
    Integer exerciseMinutes;
    Integer steps;
    String activityNote;
    List<FoodLogResponse> entries;
}

