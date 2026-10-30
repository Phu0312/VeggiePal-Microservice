package com.veggiepal.recipe.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;

import java.math.BigDecimal;
import java.util.List;

import org.junit.jupiter.api.Test;

import com.veggiepal.recipe.dto.response.NutritionPerServingResponse;
import com.veggiepal.recipe.dto.response.RecipeIngredientResponse;

class RecipeNutritionCalculatorTest {

    @Test
    void calculatesPerServingNutritionAcrossGramsLiquidsSpoonsAndPieces() {
        // 2 servings:
        // - 1 PIECE dau hu (150g): 76 kcal/100g -> 114 kcal, 12.15g P, 2.85g C, 7.20g F, 0.45g fiber
        // - 1 TBSP dau an (13.8g): 884 kcal/100g -> 121.992 kcal, 0g P, 0g C, 13.80g F, 0g fiber
        // - 20 ML nuoc tuong (23g): 53 kcal/100g -> 12.19 kcal, 1.84g P, 1.15g C, 0g F, 0g fiber
        // Total = 248.182 kcal -> per serving (2): 124 kcal (124.1), 7.0g P, 2.0g C, 10.5g F, 0.2g fiber
        List<RecipeIngredientResponse> ingredients = List.of(
                RecipeIngredientResponse.builder()
                        .ingredientId(1L)
                        .ingredientName("Đậu hũ")
                        .normalizedName("dau hu")
                        .quantity(BigDecimal.ONE)
                        .unit("PIECE")
                        .caloriesPer100g(new BigDecimal("76"))
                        .proteinPer100g(new BigDecimal("8.1"))
                        .carbsPer100g(new BigDecimal("1.9"))
                        .fatPer100g(new BigDecimal("4.8"))
                        .fiberPer100g(new BigDecimal("0.3"))
                        .build(),
                RecipeIngredientResponse.builder()
                        .ingredientId(2L)
                        .ingredientName("Dầu ăn")
                        .normalizedName("dau an")
                        .quantity(BigDecimal.ONE)
                        .unit("TBSP")
                        .caloriesPer100g(new BigDecimal("884"))
                        .proteinPer100g(BigDecimal.ZERO)
                        .carbsPer100g(BigDecimal.ZERO)
                        .fatPer100g(new BigDecimal("100"))
                        .fiberPer100g(BigDecimal.ZERO)
                        .build(),
                RecipeIngredientResponse.builder()
                        .ingredientId(3L)
                        .ingredientName("Nước tương")
                        .normalizedName("nuoc tuong")
                        .quantity(new BigDecimal("20"))
                        .unit("ML")
                        .caloriesPer100g(new BigDecimal("53"))
                        .proteinPer100g(new BigDecimal("8.0"))
                        .carbsPer100g(new BigDecimal("5.0"))
                        .fatPer100g(BigDecimal.ZERO)
                        .build()
        );

        NutritionPerServingResponse result = RecipeNutritionCalculator.calculatePerServing(2, ingredients);

        assertNotNull(result);
        assertEquals(124, result.getKcal());
        assertEquals(new BigDecimal("124.1"), result.getCalories());
        assertEquals(new BigDecimal("7.0"), result.getProtein());
        assertEquals(new BigDecimal("2.0"), result.getCarbs());
        assertEquals(new BigDecimal("10.5"), result.getFat());
        assertEquals(new BigDecimal("0.2"), result.getFiber());
        assertEquals(new BigDecimal("150.00"), ingredients.get(0).getGramsEquivalent());
        assertEquals(new BigDecimal("13.80"), ingredients.get(1).getGramsEquivalent());
        assertEquals(new BigDecimal("23.00"), ingredients.get(2).getGramsEquivalent());
    }

    @Test
    void returnsNullWhenPieceWeightIsUnconvertibleToAvoidPartialMisleadingTotal() {
        List<RecipeIngredientResponse> ingredients = List.of(
                RecipeIngredientResponse.builder()
                        .ingredientId(1L)
                        .ingredientName("Gạo lứt")
                        .normalizedName("gao lut")
                        .quantity(BigDecimal.ONE)
                        .unit("PIECE")
                        .caloriesPer100g(new BigDecimal("370"))
                        .proteinPer100g(new BigDecimal("7.9"))
                        .carbsPer100g(new BigDecimal("77.2"))
                        .fatPer100g(new BigDecimal("2.9"))
                        .build()
        );

        assertNull(RecipeNutritionCalculator.calculatePerServing(1, ingredients));
    }
}

