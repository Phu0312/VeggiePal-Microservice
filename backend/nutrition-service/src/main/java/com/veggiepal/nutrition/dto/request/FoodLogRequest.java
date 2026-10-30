package com.veggiepal.nutrition.dto.request;

import java.math.BigDecimal;
import java.time.LocalDate;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

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
public class FoodLogRequest {

    LocalDate logDate;

    MealType mealType;

    @NotBlank(message = "FOOD_NAME_REQUIRED")
    @Size(max = 200, message = "INVALID_REQUEST")
    String foodName;

    Long recipeId;

    @Min(value = 0, message = "INVALID_NUTRITION_VALUE")
    Integer calories;

    @DecimalMin(value = "0.0", message = "INVALID_NUTRITION_VALUE")
    BigDecimal proteinG;

    @DecimalMin(value = "0.0", message = "INVALID_NUTRITION_VALUE")
    BigDecimal carbsG;

    @DecimalMin(value = "0.0", message = "INVALID_NUTRITION_VALUE")
    BigDecimal fatG;

    @DecimalMin(value = "0.0", message = "INVALID_NUTRITION_VALUE")
    BigDecimal fiberG;
}

