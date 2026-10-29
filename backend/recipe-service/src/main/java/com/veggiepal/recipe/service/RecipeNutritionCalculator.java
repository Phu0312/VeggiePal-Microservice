package com.veggiepal.recipe.service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import java.util.Optional;

import com.veggiepal.recipe.dto.response.NutritionPerServingResponse;
import com.veggiepal.recipe.dto.response.RecipeIngredientResponse;

public final class RecipeNutritionCalculator {

    private static final BigDecimal HUNDRED = new BigDecimal("100");

    private RecipeNutritionCalculator() {
    }

    public static NutritionPerServingResponse calculatePerServing(
            Integer servings,
            List<RecipeIngredientResponse> ingredients
    ) {
        if (ingredients == null || ingredients.isEmpty()) {
            return null;
        }

        BigDecimal totalCalories = BigDecimal.ZERO;
        BigDecimal totalProtein = BigDecimal.ZERO;
        BigDecimal totalCarbs = BigDecimal.ZERO;
        BigDecimal totalFat = BigDecimal.ZERO;
        BigDecimal totalFiber = BigDecimal.ZERO;

        for (RecipeIngredientResponse item : ingredients) {
            if (item == null || !hasMacroData(item)) {
                return null;
            }

            BigDecimal grams = item.getGramsEquivalent();
            if (grams == null) {
                Optional<BigDecimal> converted = IngredientUnitConverter.toGrams(
                        item.getQuantity(),
                        item.getUnit(),
                        item.getIngredientName(),
                        item.getNormalizedName()
                );
                if (converted.isEmpty()) {
                    return null;
                }
                grams = converted.get();
                item.setGramsEquivalent(grams);
            }

            BigDecimal factor = grams.divide(HUNDRED, 6, RoundingMode.HALF_UP);
            totalCalories = totalCalories.add(factor.multiply(item.getCaloriesPer100g()));
            totalProtein = totalProtein.add(factor.multiply(item.getProteinPer100g()));
            totalCarbs = totalCarbs.add(factor.multiply(item.getCarbsPer100g()));
            totalFat = totalFat.add(factor.multiply(item.getFatPer100g()));
            if (item.getFiberPer100g() != null) {
                totalFiber = totalFiber.add(factor.multiply(item.getFiberPer100g()));
            }
        }

        BigDecimal divisor = BigDecimal.valueOf(servings != null && servings > 0 ? servings : 1);
        BigDecimal caloriesPerServing = totalCalories.divide(divisor, 1, RoundingMode.HALF_UP);

        return NutritionPerServingResponse.builder()
                .kcal(totalCalories.divide(divisor, 0, RoundingMode.HALF_UP).intValue())
                .calories(caloriesPerServing)
                .protein(totalProtein.divide(divisor, 1, RoundingMode.HALF_UP))
                .carbs(totalCarbs.divide(divisor, 1, RoundingMode.HALF_UP))
                .fat(totalFat.divide(divisor, 1, RoundingMode.HALF_UP))
                .fiber(totalFiber.divide(divisor, 1, RoundingMode.HALF_UP))
                .build();
    }

    private static boolean hasMacroData(RecipeIngredientResponse item) {
        return item.getCaloriesPer100g() != null
                && item.getProteinPer100g() != null
                && item.getCarbsPer100g() != null
                && item.getFatPer100g() != null;
    }
}

