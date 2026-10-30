package com.veggiepal.recipe.mapper;

import org.mapstruct.AfterMapping;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingTarget;

import com.veggiepal.recipe.dto.response.RecipeIngredientResponse;
import com.veggiepal.recipe.dto.response.RecipeResponse;
import com.veggiepal.recipe.dto.response.RecipeStepResponse;
import com.veggiepal.recipe.entity.Recipe;
import com.veggiepal.recipe.entity.RecipeIngredient;
import com.veggiepal.recipe.entity.RecipeStep;
import com.veggiepal.recipe.service.IngredientUnitConverter;
import com.veggiepal.recipe.service.RecipeNutritionCalculator;

@Mapper(componentModel = "spring")
public interface RecipeMapper {

    @Mapping(
            target = "ingredients",
            source = "ingredients"
    )
    @Mapping(
            target = "steps",
            source = "steps"
    )
    @Mapping(target = "nutritionPerServing", ignore = true)
    RecipeResponse toRecipeResponse(
            Recipe recipe
    );

    @Mapping(
            target = "ingredientId",
            source = "ingredient.id"
    )
    @Mapping(
            target = "ingredientName",
            source = "ingredient.name"
    )
    @Mapping(target = "normalizedName", source = "ingredient.normalizedName")
    @Mapping(target = "caloriesPer100g", source = "ingredient.caloriesPer100g")
    @Mapping(target = "proteinPer100g", source = "ingredient.proteinPer100g")
    @Mapping(target = "carbsPer100g", source = "ingredient.carbsPer100g")
    @Mapping(target = "fatPer100g", source = "ingredient.fatPer100g")
    @Mapping(target = "fiberPer100g", source = "ingredient.fiberPer100g")
    @Mapping(target = "vegan", source = "ingredient.vegan")
    @Mapping(target = "allergen", source = "ingredient.allergen")
    @Mapping(target = "gramsEquivalent", ignore = true)
    RecipeIngredientResponse
    toRecipeIngredientResponse(
            RecipeIngredient recipeIngredient
    );

    RecipeStepResponse toRecipeStepResponse(
            RecipeStep recipeStep
    );

    @AfterMapping
    default void populateIngredientGrams(
            RecipeIngredient source,
            @MappingTarget RecipeIngredientResponse target
    ) {
        target.setGramsEquivalent(
                IngredientUnitConverter.toGrams(
                        target.getQuantity(),
                        target.getUnit(),
                        target.getIngredientName(),
                        target.getNormalizedName()
                ).orElse(null)
        );
    }

    @AfterMapping
    default void populateDerivedRecipeFields(
            Recipe source,
            @MappingTarget RecipeResponse target
    ) {
        if (target.getLikeCount() == null) {
            target.setLikeCount(0);
        }
        target.setNutritionPerServing(
                RecipeNutritionCalculator.calculatePerServing(
                        target.getServings(),
                        target.getIngredients()
                )
        );
    }
}
