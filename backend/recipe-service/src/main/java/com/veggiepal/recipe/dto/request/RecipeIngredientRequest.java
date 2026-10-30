package com.veggiepal.recipe.dto.request;

import java.math.BigDecimal;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import lombok.*;
import lombok.experimental.FieldDefaults;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class RecipeIngredientRequest {

    @NotNull(message = "INGREDIENT_ID_REQUIRED")
    Long ingredientId;

    @NotNull(message = "QUANTITY_REQUIRED")
    @DecimalMin(value = "0.01", message = "INVALID_QUANTITY")
    BigDecimal quantity;

    @NotBlank(message = "RECIPE_UNIT_REQUIRED")
    @Size(max = 30, message = "INVALID_RECIPE_UNIT_LENGTH")
    String unit;

    @Size(max = 300, message = "INVALID_RECIPE_NOTE")
    String note;
}
