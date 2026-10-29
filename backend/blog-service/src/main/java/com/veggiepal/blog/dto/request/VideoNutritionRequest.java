package com.veggiepal.blog.dto.request;

import java.math.BigDecimal;
import java.util.List;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class VideoNutritionRequest {

    @Size(max = 100, message = "INVALID_REQUEST")
    String servingLabel;

    @Min(value = 0, message = "INVALID_VIDEO_NUTRITION")
    Integer kcal;

    @DecimalMin(value = "0.0", message = "INVALID_VIDEO_NUTRITION")
    BigDecimal proteinG;

    @DecimalMin(value = "0.0", message = "INVALID_VIDEO_NUTRITION")
    BigDecimal carbsG;

    @DecimalMin(value = "0.0", message = "INVALID_VIDEO_NUTRITION")
    BigDecimal fatG;

    @DecimalMin(value = "0.0", message = "INVALID_VIDEO_NUTRITION")
    BigDecimal fiberG;

    @Valid
    List<IngredientItem> ingredients;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    @FieldDefaults(level = AccessLevel.PRIVATE)
    public static class IngredientItem {

        @NotBlank(message = "INVALID_REQUEST")
        @Size(max = 150, message = "INVALID_REQUEST")
        String name;

        @Size(max = 80, message = "INVALID_REQUEST")
        String amount;
    }
}

