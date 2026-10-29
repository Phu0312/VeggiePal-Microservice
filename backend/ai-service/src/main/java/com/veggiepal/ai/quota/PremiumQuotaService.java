package com.veggiepal.ai.quota;

import static com.veggiepal.ai.quota.QuotaDtos.*;

import com.veggiepal.ai.subscription.*;
import java.time.Instant;
import java.time.LocalDate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

@Service
public class PremiumQuotaService {
    private static final Logger log = LoggerFactory.getLogger(PremiumQuotaService.class);
    private final SubscriptionProvider subscriptions;
    private final QuotaService quotas;

    public PremiumQuotaService(SubscriptionProvider subscriptions, QuotaService quotas) {
        this.subscriptions = subscriptions; this.quotas = quotas;
    }

    public int reserveChat(Long userId) {
        SubscriptionEntitlement entitlement = effective(userId);
        return quotas.reserveFeature("user:" + userId, "CHAT", QuotaPeriod.DAILY, entitlement.chatPerDay());
    }

    public int reserveMealPlan(Long userId) {
        SubscriptionEntitlement entitlement = effective(userId);
        return quotas.reserveFeature("user:" + userId, "MEAL_PLAN", QuotaPeriod.MONTHLY,
                entitlement.mealPlansPerMonth());
    }

    public int reserveVideo(Long userId) {
        SubscriptionEntitlement entitlement = effective(userId);
        return quotas.reserveFeature("user:" + userId, "VIDEO", QuotaPeriod.MONTHLY,
                entitlement.videosPerMonth());
    }

    public void refundVideo(Long userId) {
        quotas.refundFeature("user:" + userId, "VIDEO", QuotaPeriod.MONTHLY);
    }

    public void refundVideo(Long userId, LocalDate quotaPeriodDate) {
        if (quotaPeriodDate == null) refundVideo(userId);
        else quotas.refundFeature("user:" + userId, "VIDEO", quotaPeriodDate);
    }

    public MealPlanQuotaStatus getMealPlanQuota(Long userId) {
        SubscriptionEntitlement entitlement = effective(userId);
        LocalDate today = LocalDate.now();
        LocalDate monthStart = today.withDayOfMonth(1);
        LocalDate nextMonthStart = monthStart.plusMonths(1);
        int limit = Math.max(0, entitlement.mealPlansPerMonth());
        int used = Math.max(0, quotas.getUsedCount("user:" + userId, "MEAL_PLAN", QuotaPeriod.MONTHLY));
        int remaining = Math.max(0, limit - used);
        return new MealPlanQuotaStatus(
                entitlement.planCode(),
                entitlement.expiresAt(),
                QuotaPeriod.MONTHLY.name(),
                limit,
                used,
                remaining,
                monthStart,
                nextMonthStart);
    }

    public QuotaOverviewResponse getQuotaOverview(Long userId) {
        SubscriptionEntitlement entitlement = effective(userId);
        String principalKey = "user:" + userId;
        LocalDate today = LocalDate.now();
        LocalDate monthStart = today.withDayOfMonth(1);
        LocalDate nextMonthStart = monthStart.plusMonths(1);

        int mealLimit = Math.max(0, entitlement.mealPlansPerMonth());
        int mealUsed = Math.max(0, quotas.getUsedCount(principalKey, "MEAL_PLAN", QuotaPeriod.MONTHLY));

        int chatLimit = Math.max(0, entitlement.chatPerDay());
        int chatUsed = Math.max(0, quotas.getUsedCount(principalKey, "CHAT", QuotaPeriod.DAILY));

        int videoLimit = Math.max(0, entitlement.videosPerMonth());
        int videoUsed = Math.max(0, quotas.getUsedCount(principalKey, "VIDEO", QuotaPeriod.MONTHLY));

        return new QuotaOverviewResponse(
                entitlement.planCode(),
                entitlement.expiresAt(),
                new FeatureQuotaStatus("MEAL_PLAN", QuotaPeriod.MONTHLY.name(), mealLimit, mealUsed,
                        Math.max(0, mealLimit - mealUsed), monthStart, nextMonthStart),
                new FeatureQuotaStatus("CHAT", QuotaPeriod.DAILY.name(), chatLimit, chatUsed,
                        Math.max(0, chatLimit - chatUsed), today, today.plusDays(1)),
                new FeatureQuotaStatus("VIDEO", QuotaPeriod.MONTHLY.name(), videoLimit, videoUsed,
                        Math.max(0, videoLimit - videoUsed), monthStart, nextMonthStart));
    }

    private SubscriptionEntitlement effective(Long userId) {
        try {
            SubscriptionEntitlement entitlement = subscriptions.getEffectiveSubscription(userId);
            if (entitlement == null || entitlement.isExpired(Instant.now())) return SubscriptionEntitlement.free();
            return entitlement;
        } catch (RuntimeException exception) {
            log.warn("Payment Service subscription lookup failed for user {}; applying FREE quotas", userId);
            return SubscriptionEntitlement.free();
        }
    }
}
