package com.veggiepal.ai.subscription;

import java.time.Instant;

public record SubscriptionEntitlement(String planCode, Instant expiresAt, int chatPerDay,
                                      int mealPlansPerMonth) {
    public static SubscriptionEntitlement free() {
        return new SubscriptionEntitlement("FREE", null, 5, 2);
    }

    public boolean isExpired(Instant now) {
        return expiresAt != null && !expiresAt.isAfter(now);
    }
}
