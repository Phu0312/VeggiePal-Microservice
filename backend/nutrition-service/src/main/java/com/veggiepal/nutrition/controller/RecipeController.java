package com.veggiepal.nutrition.controller;

import java.util.List;

import org.springframework.web.bind.annotation.*;

import com.veggiepal.nutrition.dto.response.ApiResponse;
import com.veggiepal.nutrition.entity.Recipe;
import com.veggiepal.nutrition.service.RecipeService;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@RestController
@RequestMapping("/nutrition/recipes")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class RecipeController {

    RecipeService recipeService;

    @GetMapping
    public ApiResponse<List<Recipe>> getAllRecipes(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String excludeAllergen
    ) {
        List<Recipe> recipes;
        if (excludeAllergen != null && !excludeAllergen.trim().isEmpty()) {
            recipes = recipeService.getRecipesExcludingAllergen(excludeAllergen);
        } else if (keyword != null && !keyword.trim().isEmpty()) {
            recipes = recipeService.searchRecipes(keyword);
        } else {
            recipes = recipeService.getAllRecipes();
        }

        return ApiResponse.<List<Recipe>>builder()
                .result(recipes)
                .build();
    }

    @GetMapping("/{id}")
    public ApiResponse<Recipe> getRecipeById(@PathVariable Long id) {
        return ApiResponse.<Recipe>builder()
                .result(recipeService.getRecipeById(id))
                .build();
    }
}
