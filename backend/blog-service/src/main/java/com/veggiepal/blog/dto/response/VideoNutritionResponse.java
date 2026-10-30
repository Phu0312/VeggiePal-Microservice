package com.veggiepal.blog.dto.response;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

import com.veggiepal.blog.entity.Video;

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
public class VideoNutritionResponse {

    Long videoId;
    String servingLabel;
    Integer kcal;
    BigDecimal proteinG;
    BigDecimal carbsG;
    BigDecimal fatG;
    BigDecimal fiberG;
    List<IngredientLine> ingredients;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    @FieldDefaults(level = AccessLevel.PRIVATE)
    public static class IngredientLine {
        String name;
        String amount;
    }

    public static VideoNutritionResponse fromVideo(Video video) {
        if (video == null) {
            return null;
        }
        List<IngredientLine> parsed = parseIngredients(video.getIngredientsText());
        boolean hasAny = video.getServingLabel() != null
                || video.getCalories() != null
                || video.getProteinG() != null
                || video.getCarbsG() != null
                || video.getFatG() != null
                || video.getFiberG() != null
                || !parsed.isEmpty();

        if (!hasAny) {
            return null;
        }

        return VideoNutritionResponse.builder()
                .videoId(video.getId())
                .servingLabel(video.getServingLabel())
                .kcal(video.getCalories())
                .proteinG(video.getProteinG())
                .carbsG(video.getCarbsG())
                .fatG(video.getFatG())
                .fiberG(video.getFiberG())
                .ingredients(parsed)
                .build();
    }

    public static List<IngredientLine> parseIngredients(String raw) {
        if (raw == null || raw.isBlank()) {
            return List.of();
        }
        List<IngredientLine> result = new ArrayList<>();
        for (String line : raw.split("\\R")) {
            String trimmed = line.trim();
            if (trimmed.isEmpty()) {
                continue;
            }
            int sep = trimmed.indexOf('|');
            if (sep < 0) {
                result.add(new IngredientLine(trimmed, null));
            } else {
                String name = trimmed.substring(0, sep).trim();
                String amount = trimmed.substring(sep + 1).trim();
                if (!name.isEmpty()) {
                    result.add(new IngredientLine(name, amount.isEmpty() ? null : amount));
                }
            }
        }
        return result;
    }
}

