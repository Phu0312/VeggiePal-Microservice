package com.veggiepal.ai.chat;

import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import com.veggiepal.ai.mealplan.AllergenDetector;

/**
 * Immutable dietary restrictions and allergen profile extracted from user requests,
 * multi-turn conversation history, and saved health records.
 */
public record DietaryRestrictions(
        Set<String> allergenCodes,
        Set<String> excludedKeywords,
        List<String> userFriendlyDescriptions) {

    public DietaryRestrictions {
        allergenCodes = allergenCodes == null ? Set.of() : Set.copyOf(allergenCodes);
        excludedKeywords = excludedKeywords == null ? Set.of() : Set.copyOf(excludedKeywords);
        userFriendlyDescriptions = userFriendlyDescriptions == null ? List.of() : List.copyOf(userFriendlyDescriptions);
    }

    public static DietaryRestrictions empty() {
        return new DietaryRestrictions(Set.of(), Set.of(), List.of());
    }

    public boolean isEmpty() {
        return allergenCodes.isEmpty() && excludedKeywords.isEmpty();
    }

    /**
     * Checks whether an ingredient name or keyword violates this restriction profile.
     */
    public boolean violates(String ingredientName) {
        if (isEmpty() || ingredientName == null || ingredientName.isBlank()) {
            return false;
        }
        String normalized = AllergenDetector.normalizeText(ingredientName);
        if (normalized.isBlank()) {
            return false;
        }

        // 1. Direct keyword match (e.g. "dau nanh", "dau hu", "lac", "me")
        for (String excluded : excludedKeywords) {
            if (AllergenDetector.matchesWord(normalized, excluded)) {
                return true;
            }
        }

        // 2. Allergen code match via AllergenDetector
        Set<String> detected = AllergenDetector.detectAllergenCodes(ingredientName, normalized);
        for (String code : detected) {
            if (allergenCodes.contains(code)) {
                return true;
            }
        }

        return false;
    }

    /**
     * Checks if a collection of allergen codes from a meal or recipe contains any excluded allergen.
     */
    public boolean containsAnyAllergen(Set<String> mealAllergenCodes) {
        if (mealAllergenCodes == null || mealAllergenCodes.isEmpty() || allergenCodes.isEmpty()) {
            return false;
        }
        for (String code : mealAllergenCodes) {
            if (allergenCodes.contains(code.toUpperCase(Locale.ROOT))) {
                return true;
            }
        }
        return false;
    }

    /**
     * Returns a comma-separated list of prohibited items suitable for prompt instructions.
     */
    public String toPromptWarning() {
        if (isEmpty()) {
            return "";
        }
        StringBuilder sb = new StringBuilder();
        if (!userFriendlyDescriptions.isEmpty()) {
            sb.append(String.join(", ", userFriendlyDescriptions));
        } else {
            sb.append(String.join(", ", allergenCodes));
        }
        return sb.toString();
    }
}

