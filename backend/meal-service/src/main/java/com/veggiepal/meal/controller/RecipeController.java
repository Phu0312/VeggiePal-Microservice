package com.veggiepal.meal.controller;

import java.util.List;

import org.springframework.web.bind.annotation.*;

import com.veggiepal.meal.dto.response.ApiResponse;
import com.veggiepal.meal.entity.Recipe;
import com.veggiepal.meal.service.RecipeService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@RestController
@RequestMapping({"/nutrition/recipes", "/meal/recipes"})
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Tag(name = "Recipe", description = "Vegan recipes catalog and search")
public class RecipeController {

    RecipeService recipeService;

    @Operation(summary = "Get all recipes, with optional search and allergen exclusion")
    @GetMapping
    public ApiResponse<List<Recipe>> getAllRecipes(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String excludeAllergen
    ) {
        List<Recipe> recipes = recipeService.searchRecipes(keyword, excludeAllergen);

        return ApiResponse.<List<Recipe>>builder()
                .result(recipes)
                .build();
    }

    @Operation(summary = "Get recipe detail by ID")
    @GetMapping("/{id}")
    public ApiResponse<Recipe> getRecipeById(@PathVariable Long id) {
        return ApiResponse.<Recipe>builder()
                .result(recipeService.getRecipeById(id))
                .build();
    }
}
