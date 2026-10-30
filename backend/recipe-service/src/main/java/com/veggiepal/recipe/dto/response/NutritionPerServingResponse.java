package com.veggiepal.recipe.dto.response;

import java.math.BigDecimal;

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
public class NutritionPerServingResponse {

    Integer kcal;

    BigDecimal calories;

    BigDecimal protein;

    BigDecimal carbs;

    BigDecimal fat;

    BigDecimal fiber;
}

