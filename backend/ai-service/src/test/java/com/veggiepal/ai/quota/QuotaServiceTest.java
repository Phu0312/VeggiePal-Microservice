package com.veggiepal.ai.quota;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import java.util.Optional;
import com.veggiepal.ai.common.AppException;
import org.junit.jupiter.api.Test;
import org.springframework.mock.env.MockEnvironment;

class QuotaServiceTest {
    @Test
    void guestQuotaRejectsFourthRequest() {
        DailyQuotaRepository repository=mock(DailyQuotaRepository.class);
        DailyQuota row=new DailyQuota("guest:abc","CHAT",java.time.LocalDate.now());
        when(repository.totalTokens(anyString(),any())).thenReturn(0L);
        when(repository.findByPrincipalKeyAndFeatureAndUsageDate(anyString(),anyString(),any())).thenReturn(Optional.of(row));
        QuotaService service=new QuotaService(repository,new QuotaProperties(3,50,12,4000),new TokenProperties(50000));
        assertEquals(2,service.reserveChat("guest:abc",true));
        assertEquals(1,service.reserveChat("guest:abc",true));
        assertEquals(0,service.reserveChat("guest:abc",true));
        assertThrows(AppException.class,()->service.reserveChat("guest:abc",true));
    }

    @Test
    void tokenLimitRejectsBeforeProviderCall() {
        DailyQuotaRepository repository=mock(DailyQuotaRepository.class);
        when(repository.totalTokens(anyString(),any())).thenReturn(50000L);
        QuotaService service=new QuotaService(repository,new QuotaProperties(3,50,12,4000),new TokenProperties(50000));
        assertThrows(AppException.class,()->service.reserveChat("user:1",false));
        verify(repository,never()).findByPrincipalKeyAndFeatureAndUsageDate(anyString(),anyString(),any());
    }

    @Test
    void usedCountReadsWithoutTheRowLockSoItWorksInAReadOnlyTransaction() {
        DailyQuotaRepository repository = mock(DailyQuotaRepository.class);
        java.time.LocalDate monthStart = java.time.LocalDate.now().withDayOfMonth(1);
        when(repository.findRequestCount("user:1", "MEAL_PLAN", monthStart)).thenReturn(Optional.of(4));
        QuotaService service = new QuotaService(repository, new QuotaProperties(3, 50, 12, 4000), new TokenProperties(50000));

        assertEquals(4, service.getUsedCount("user:1", "MEAL_PLAN", QuotaPeriod.MONTHLY));
        // The locking finder is what made GET /ai/quotas/me fail with HTTP 500 on MySQL.
        verify(repository, never()).findByPrincipalKeyAndFeatureAndUsageDate(anyString(), anyString(), any());
    }

    @Test
    void usedCountIsZeroWhenNothingWasUsedYetAndDailyUsesToday() {
        DailyQuotaRepository repository = mock(DailyQuotaRepository.class);
        when(repository.findRequestCount(anyString(), anyString(), any())).thenReturn(Optional.empty());
        QuotaService service = new QuotaService(repository, new QuotaProperties(3, 50, 12, 4000), new TokenProperties(50000));

        assertEquals(0, service.getUsedCount("user:1", "CHAT", QuotaPeriod.DAILY));
        verify(repository).findRequestCount("user:1", "CHAT", java.time.LocalDate.now());
    }

    @Test
    void monthlyFeatureQuotaRejectsAfterConfiguredLimit() {
        DailyQuotaRepository repository = mock(DailyQuotaRepository.class);
        DailyQuota row = new DailyQuota("user:1", "MEAL_PLAN", java.time.LocalDate.now().withDayOfMonth(1));
        when(repository.totalTokens(anyString(), any())).thenReturn(0L);
        when(repository.findByPrincipalKeyAndFeatureAndUsageDate(anyString(), anyString(), any())).thenReturn(Optional.of(row));
        QuotaService service = new QuotaService(repository, new QuotaProperties(3, 50, 12, 4000), new TokenProperties(50000));

        service.reserveFeature("user:1", "MEAL_PLAN", QuotaPeriod.MONTHLY, 2);
        service.reserveFeature("user:1", "MEAL_PLAN", QuotaPeriod.MONTHLY, 2);
        assertThrows(AppException.class,
                () -> service.reserveFeature("user:1", "MEAL_PLAN", QuotaPeriod.MONTHLY, 2));
    }

    @Test
    void localFeatureHasDailyLimitAndDoesNotUseMonthlySubscriptionRow() {
        DailyQuotaRepository repository = mock(DailyQuotaRepository.class);
        DailyQuota row = new DailyQuota("user:1", "MEAL_PLAN_LOCAL_TEST", java.time.LocalDate.now());
        when(repository.findByPrincipalKeyAndFeatureAndUsageDate("user:1", "MEAL_PLAN_LOCAL_TEST",
                java.time.LocalDate.now())).thenReturn(Optional.of(row));
        MockEnvironment environment = new MockEnvironment();
        environment.setActiveProfiles("local-testing");
        QuotaService service = new QuotaService(repository, new QuotaProperties(3, 50, 12, 4000),
                new TokenProperties(50000), new LocalTestQuotaPolicy(environment, true, 100, 5000000, "local"));

        for (int i = 0; i < 100; i++) assertEquals(99 - i, service.reserveLocalTestFeature("user:1", "MEAL_PLAN"));
        assertThrows(AppException.class, () -> service.reserveLocalTestFeature("user:1", "MEAL_PLAN"));
        verify(repository, never()).findByPrincipalKeyAndFeatureAndUsageDate("user:1", "MEAL_PLAN",
                java.time.LocalDate.now().withDayOfMonth(1));
    }

    @Test
    void localQuotaResetsByDate() {
        DailyQuotaRepository repository = mock(DailyQuotaRepository.class);
        java.time.LocalDate today = java.time.LocalDate.now();
        DailyQuota yesterday = new DailyQuota("user:1", "CHAT_LOCAL_TEST", today.minusDays(1));
        for (int i = 0; i < 100; i++) yesterday.reserve();
        DailyQuota current = new DailyQuota("user:1", "CHAT_LOCAL_TEST", today);
        when(repository.findByPrincipalKeyAndFeatureAndUsageDate("user:1", "CHAT_LOCAL_TEST", today))
                .thenReturn(Optional.of(current));
        MockEnvironment environment = new MockEnvironment();
        environment.setActiveProfiles("local-testing");
        QuotaService service = new QuotaService(repository, new QuotaProperties(3, 50, 12, 4000),
                new TokenProperties(50000), new LocalTestQuotaPolicy(environment, true, 100, 5000000, "local"));

        assertEquals(99, service.reserveLocalTestFeature("user:1", "CHAT"));
        assertEquals(1, current.getRequestCount());
        assertEquals(98, service.reserveLocalTestFeature("user:1", "CHAT"));
        verify(repository, never()).findByPrincipalKeyAndFeatureAndUsageDate("user:1", "CHAT_LOCAL_TEST",
                today.minusDays(1));
    }

    @Test
    void localMemberTokenBudgetDoesNotRaiseGuestBudget() {
        DailyQuotaRepository repository = mock(DailyQuotaRepository.class);
        when(repository.totalTokens(anyString(), any())).thenReturn(50000L);
        MockEnvironment environment = new MockEnvironment();
        environment.setActiveProfiles("local-testing");
        QuotaService service = new QuotaService(repository, new QuotaProperties(3, 50, 12, 4000),
                new TokenProperties(50000), new LocalTestQuotaPolicy(environment, true, 100, 5000000, "local"));

        assertThrows(AppException.class, () -> service.checkTokenBudget("guest-ip:abc"));
        assertDoesNotThrow(() -> service.checkLocalTextTokenBudget("user:1"));
        assertThrows(AppException.class, () -> service.checkTokenBudget("user:1"));
        assertThrows(IllegalArgumentException.class, () -> service.reserveLocalTestFeature("guest-ip:abc", "CHAT"));
        assertThrows(IllegalArgumentException.class, () -> service.reserveLocalTestFeature("user:1", "VIDEO"));
    }
}
