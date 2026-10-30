package com.veggiepal.recipe.dto.request;

import java.util.List;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import lombok.*;
import lombok.experimental.FieldDefaults;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class RecipeRequest {

    @NotBlank(message = "RECIPE_TITLE_REQUIRED")
    @Size(max = 200, message = "INVALID_RECIPE_TITLE")
    String title;

    @Size(max = 2000, message = "INVALID_RECIPE_DESCRIPTION")
    String description;

    @Size(max = 500, message = "INVALID_RECIPE_IMAGE_URL")
    String imageUrl;

    @NotNull(message = "INVALID_SERVINGS")
    @Min(value = 1, message = "INVALID_SERVINGS")
    Integer servings;

    @Min(value = 0, message = "INVALID_PREP_TIME")
    Integer prepTime;

    @Min(value = 0, message = "INVALID_COOK_TIME")
    Integer cookTime;

    @NotEmpty(message = "RECIPE_INGREDIENTS_REQUIRED")
    List<@Valid RecipeIngredientRequest> ingredients;

    @NotEmpty(message = "RECIPE_STEPS_REQUIRED")
    List<@Valid RecipeStepRequest> steps;
}
