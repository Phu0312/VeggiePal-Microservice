package com.veggiepal.ai.quota;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.Instant;
import java.time.LocalDate;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.security.web.method.annotation.AuthenticationPrincipalArgumentResolver;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

class QuotaControllerTest {

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void myQuotasReturnsCurrentUserOverview() throws Exception {
        PremiumQuotaService service = mock(PremiumQuotaService.class);
        LocalDate start = LocalDate.of(2026, 10, 1);
        LocalDate reset = LocalDate.of(2026, 11, 1);
        when(service.getQuotaOverview(7L)).thenReturn(new QuotaDtos.QuotaOverviewResponse(
                "GREEN",
                Instant.parse("2026-11-15T00:00:00Z"),
                new QuotaDtos.FeatureQuotaStatus("MEAL_PLAN", "MONTHLY", 30, 4, 26, start, reset),
                new QuotaDtos.FeatureQuotaStatus("CHAT", "DAILY", 30, 3, 27, LocalDate.of(2026, 10, 29), LocalDate.of(2026, 10, 30)),
                new QuotaDtos.FeatureQuotaStatus("VIDEO", "MONTHLY", 10, 1, 9, start, reset)));

        SecurityContextHolder.getContext().setAuthentication(new JwtAuthenticationToken(Jwt.withTokenValue("token")
                .header("alg", "HS256").claim("userId", 7L).issuedAt(Instant.now()).build()));
        MockMvc mockMvc = MockMvcBuilders.standaloneSetup(new QuotaController(service))
                .setCustomArgumentResolvers(new AuthenticationPrincipalArgumentResolver())
                .build();

        mockMvc.perform(get("/ai/quotas/me"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(1000))
                .andExpect(jsonPath("$.result.planCode").value("GREEN"))
                .andExpect(jsonPath("$.result.mealPlan.limit").value(30))
                .andExpect(jsonPath("$.result.mealPlan.used").value(4))
                .andExpect(jsonPath("$.result.mealPlan.remaining").value(26));
    }
}

