package com.veggiepal.recipe.dto.request;

import jakarta.validation.constraints.Min;
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
public class RecipeStepRequest {

    @NotNull(message = "STEP_NUMBER_REQUIRED")
    @Min(value = 1, message = "INVALID_STEP_NUMBER")
    Integer stepNumber;

    @NotBlank(message = "STEP_INSTRUCTION_REQUIRED")
    @Size(max = 2000, message = "INVALID_STEP_INSTRUCTION")
    String instruction;
}
