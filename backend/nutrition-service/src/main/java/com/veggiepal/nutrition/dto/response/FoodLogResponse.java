package com.veggiepal.nutrition.dto.response;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

import com.veggiepal.nutrition.enums.MealType;

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
public class FoodLogResponse {

    Long id;
    LocalDate logDate;
    MealType mealType;
    String foodName;
    Long recipeId;
    Integer calories;
    BigDecimal proteinG;
    BigDecimal carbsG;
    BigDecimal fatG;
    BigDecimal fiberG;
    LocalDateTime createdAt;
}

