package com.veggiepal.nutrition.service;

import java.util.List;

import org.springframework.stereotype.Service;

import com.veggiepal.nutrition.entity.Recipe;
import com.veggiepal.nutrition.exception.AppException;
import com.veggiepal.nutrition.exception.ErrorCode;
import com.veggiepal.nutrition.repository.RecipeRepository;

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

    public List<Recipe> searchRecipes(String keyword) {
        if (keyword == null || keyword.trim().isEmpty()) {
            return recipeRepository.findByVeganTrue();
        }
        return recipeRepository.searchRecipes(keyword.trim());
    }

    public List<Recipe> getRecipesExcludingAllergen(String allergen) {
        if (allergen == null || allergen.trim().isEmpty()) {
            return recipeRepository.findByVeganTrue();
        }
        return recipeRepository.findVeganExcludingAllergen(allergen.trim().toUpperCase());
    }
}
