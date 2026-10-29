package com.veggiepal.ai.quota;

import java.time.Instant;
import java.time.LocalDate;

public final class QuotaDtos {
    private QuotaDtos() {}

    public record FeatureQuotaStatus(
            String feature,
            String period,
            int limit,
            int used,
            int remaining,
            LocalDate periodStart,
            LocalDate resetsAt) {}

    public record MealPlanQuotaStatus(
            String planCode,
            Instant expiresAt,
            String period,
            int limit,
            int used,
            int remaining,
            LocalDate periodStart,
            LocalDate resetsAt) {}

    public record QuotaOverviewResponse(
            String planCode,
            Instant expiresAt,
            FeatureQuotaStatus mealPlan,
            FeatureQuotaStatus chat,
            FeatureQuotaStatus video) {}
}

