package com.veggiepal.meal.service;

import java.util.List;

import org.springframework.stereotype.Service;

import com.veggiepal.meal.entity.Recipe;
import com.veggiepal.meal.exception.AppException;
import com.veggiepal.meal.exception.ErrorCode;
import com.veggiepal.meal.repository.RecipeRepository;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class RecipeService {

    RecipeRepository recipeRepository;

    public List<Recipe> getAllRecipes() {
        return recipeRepository.findByVeganTrue();
    }

    public Recipe getRecipeById(Long id) {
        return recipeRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.RECIPE_NOT_FOUND));
    }

    public List<Recipe> searchRecipes(String keyword, String excludeAllergen) {
        List<Recipe> recipes;
        if (keyword != null && !keyword.trim().isEmpty()) {
            recipes = recipeRepository.searchRecipes(keyword.trim());
        } else {
            recipes = recipeRepository.findByVeganTrue();
        }

        if (excludeAllergen != null && !excludeAllergen.trim().isEmpty()) {
            java.util.List<String> codesToExclude = java.util.Arrays.stream(excludeAllergen.split(","))
                    .map(String::trim).map(String::toUpperCase).collect(java.util.stream.Collectors.toList());
            recipes = recipes.stream()
                    .filter(r -> {
                        if (r.getAllergenCodes() == null || r.getAllergenCodes().isBlank()) return true;
                        String[] recipeCodes = r.getAllergenCodes().split(",");
                        return java.util.Arrays.stream(recipeCodes).map(String::trim).noneMatch(codesToExclude::contains);
                    })
                    .collect(java.util.stream.Collectors.toList());
        }
        return recipes;
    }
}
