package com.veggiepal.ai.quota;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

import com.veggiepal.ai.subscription.*;
import java.time.Instant;
import java.time.LocalDate;
import org.junit.jupiter.api.*;

class PremiumQuotaServiceTest {
    private SubscriptionProvider subscriptions;
    private QuotaService quotas;
    private PremiumQuotaService service;

    @BeforeEach
    void setUp() {
        subscriptions = mock(SubscriptionProvider.class);
        quotas = mock(QuotaService.class);
        service = new PremiumQuotaService(subscriptions, quotas);
    }

    @Test void freePlanUsesFreeLimits() { assertLimits(new SubscriptionEntitlement("FREE", null, 5, 2, 0), 5, 2, 0); }
    @Test void plusPlanUsesPlusLimits() { assertLimits(new SubscriptionEntitlement("PLUS", Instant.now().plusSeconds(3600), 20, 8, 3), 20, 8, 3); }
    @Test void proPlanUsesProLimits() { assertLimits(new SubscriptionEntitlement("PRO", Instant.now().plusSeconds(3600), 50, 20, 8), 50, 20, 8); }

    @Test
    void expiredSubscriptionFallsBackToFreeLimits() {
        when(subscriptions.getEffectiveSubscription(7L)).thenReturn(
                new SubscriptionEntitlement("PRO", Instant.now().minusSeconds(1), 50, 20, 8));
        service.reserveChat(7L);
        verify(quotas).reserveFeature("user:7", "CHAT", QuotaPeriod.DAILY, 5);
    }

    @Test
    void paymentServiceFailureFallsBackToFreeLimits() {
        when(subscriptions.getEffectiveSubscription(7L)).thenThrow(new RuntimeException("payment unavailable"));
        service.reserveMealPlan(7L);
        verify(quotas).reserveFeature("user:7", "MEAL_PLAN", QuotaPeriod.MONTHLY, 2);
    }

    @Test
    void getMealPlanQuotaReturnsLimitUsedAndRemaining() {
        Instant exp = Instant.now().plusSeconds(7200);
        when(subscriptions.getEffectiveSubscription(7L))
                .thenReturn(new SubscriptionEntitlement("GREEN", exp, 30, 30, 10));
        when(quotas.getUsedCount("user:7", "MEAL_PLAN", QuotaPeriod.MONTHLY)).thenReturn(9);

        QuotaDtos.MealPlanQuotaStatus status = service.getMealPlanQuota(7L);

        assertThat(status.planCode()).isEqualTo("GREEN");
        assertThat(status.expiresAt()).isEqualTo(exp);
        assertThat(status.period()).isEqualTo("MONTHLY");
        assertThat(status.limit()).isEqualTo(30);
        assertThat(status.used()).isEqualTo(9);
        assertThat(status.remaining()).isEqualTo(21);
        assertThat(status.periodStart()).isEqualTo(LocalDate.now().withDayOfMonth(1));
    }

    @Test
    void getQuotaOverviewClampsRemainingToZeroWhenPlanDowngraded() {
        when(subscriptions.getEffectiveSubscription(7L))
                .thenReturn(SubscriptionEntitlement.free());
        when(quotas.getUsedCount("user:7", "MEAL_PLAN", QuotaPeriod.MONTHLY)).thenReturn(5);
        when(quotas.getUsedCount("user:7", "CHAT", QuotaPeriod.DAILY)).thenReturn(2);
        when(quotas.getUsedCount("user:7", "VIDEO", QuotaPeriod.MONTHLY)).thenReturn(1);

        QuotaDtos.QuotaOverviewResponse overview = service.getQuotaOverview(7L);

        assertThat(overview.planCode()).isEqualTo("FREE");
        assertThat(overview.mealPlan().limit()).isEqualTo(2);
        assertThat(overview.mealPlan().used()).isEqualTo(5);
        assertThat(overview.mealPlan().remaining()).isEqualTo(0);
        assertThat(overview.chat().remaining()).isEqualTo(3);
        assertThat(overview.video().remaining()).isEqualTo(0);
    }

    private void assertLimits(SubscriptionEntitlement entitlement, int chat, int meals, int videos) {
        when(subscriptions.getEffectiveSubscription(7L)).thenReturn(entitlement);
        service.reserveChat(7L);
        service.reserveMealPlan(7L);
        service.reserveVideo(7L);
        verify(quotas).reserveFeature("user:7", "CHAT", QuotaPeriod.DAILY, chat);
        verify(quotas).reserveFeature("user:7", "MEAL_PLAN", QuotaPeriod.MONTHLY, meals);
        verify(quotas).reserveFeature("user:7", "VIDEO", QuotaPeriod.MONTHLY, videos);
    }
}
