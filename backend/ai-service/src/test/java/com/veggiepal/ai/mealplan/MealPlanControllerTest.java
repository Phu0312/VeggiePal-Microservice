package com.veggiepal.ai.mealplan;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.veggiepal.ai.groq.GroqClient;
import com.veggiepal.ai.groq.ModelProperties;
import com.veggiepal.ai.monitoring.UsageService;
import com.veggiepal.ai.quota.PremiumQuotaService;
import com.veggiepal.ai.quota.QuotaDtos;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.http.MediaType;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.security.web.method.annotation.AuthenticationPrincipalArgumentResolver;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.client.RestClient;

// Goes through MockMvc on purpose: the plan is written by Spring MVC's Jackson 3 converter,
// which service-level tests never run.
class MealPlanControllerTest {

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void listReturnsStoredPlanDaysAsJson() throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        MealPlanRepository repository = mock(MealPlanRepository.class);
        String planJson = "{\"days\":[" + String.join(",", List.of("MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY",
                "FRIDAY", "SATURDAY", "SUNDAY").stream().map(day -> "{\"day\":\"" + day + "\",\"meals\":[]}").toList()) + "]}";
        when(repository.findByUserIdOrderByCreatedAtDesc(7L))
                .thenReturn(List.of(new MealPlan(7L, "Tuần này", "Ăn lành mạnh", planJson)));
        MealPlanService service = new MealPlanService(repository, mock(RestClient.class), "http://recipe",
                "http://nutrition", mock(GroqClient.class), new ModelProperties("c", "m", "r", "p", "v", "w"),
                mapper, mock(UsageService.class), new MealPlanValidator(mapper), mock(PremiumQuotaService.class));
        MockMvc mockMvc = MockMvcBuilders.standaloneSetup(new MealPlanController(service))
                .setCustomArgumentResolvers(new AuthenticationPrincipalArgumentResolver()).build();
        SecurityContextHolder.getContext().setAuthentication(new JwtAuthenticationToken(Jwt.withTokenValue("token")
                .header("alg", "HS256").claim("userId", 7L).issuedAt(Instant.now()).build()));

        mockMvc.perform(get("/ai/meal-plans"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result[0].plan.days.length()").value(7))
                .andExpect(jsonPath("$.result[0].plan.days[0].day").value("MONDAY"));
    }

    private MockMvc mockMvcFor(MealPlanService service) {
        SecurityContextHolder.getContext().setAuthentication(new JwtAuthenticationToken(Jwt.withTokenValue("token")
                .header("alg", "HS256").claim("userId", 7L).issuedAt(Instant.now()).build()));
        return MockMvcBuilders.standaloneSetup(new MealPlanController(service))
                .setControllerAdvice(new com.veggiepal.ai.common.GlobalExceptionHandler())
                .setCustomArgumentResolvers(new AuthenticationPrincipalArgumentResolver()).build();
    }

    @Test
    void quotaReturnsMonthlyMealPlanUsage() throws Exception {
        MealPlanService service = mock(MealPlanService.class);
        when(service.getQuota(7L)).thenReturn(new QuotaDtos.MealPlanQuotaStatus(
                "FREE", null, "MONTHLY", 2, 1, 1,
                LocalDate.of(2026, 10, 1), LocalDate.of(2026, 11, 1)));

        mockMvcFor(service).perform(get("/ai/meal-plans/quota"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(1000))
                .andExpect(jsonPath("$.result.planCode").value("FREE"))
                .andExpect(jsonPath("$.result.limit").value(2))
                .andExpect(jsonPath("$.result.used").value(1))
                .andExpect(jsonPath("$.result.remaining").value(1));
    }

    @Test
    void restoreVersionArchivesCurrentStateAndRestoresSelectedVersion() throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        MealPlanRepository repository = mock(MealPlanRepository.class);
        MealPlanVersionRepository versionRepository = mock(MealPlanVersionRepository.class);
        MealPlan current = new MealPlan(7L, "Thực đơn v2", "Tăng cơ", "{\"days\":[{\"day\":\"MONDAY\",\"meals\":[]}]}" , 2);
        MealPlanVersion archivedV1 = new MealPlanVersion(
                current, 1, "Thực đơn v1", "Giữ cân", "{\"days\":[{\"day\":\"SUNDAY\",\"meals\":[]}]}", "Bản đầu tiên");

        when(repository.findByIdAndUserId(15L, 7L)).thenReturn(Optional.of(current));
        when(versionRepository.findByMealPlanIdAndVersion(15L, 1)).thenReturn(Optional.of(archivedV1));
        when(repository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        MealPlanService service = new MealPlanService(repository, mock(RestClient.class), "http://recipe",
                "http://nutrition", "http://identity", mock(GroqClient.class),
                new ModelProperties("c", "m", "r", "p", "v", "w"),
                mapper, mock(UsageService.class), new MealPlanValidator(mapper),
                mock(MealPlanFavoriteRepository.class), versionRepository, mock(PremiumQuotaService.class));

        mockMvcFor(service).perform(post("/ai/meal-plans/15/versions/1/restore")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"changeSummary\":\"Quay về bản tuần trước\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(1000))
                .andExpect(jsonPath("$.result.name").value("Thực đơn v1"))
                .andExpect(jsonPath("$.result.goal").value("Giữ cân"))
                .andExpect(jsonPath("$.result.version").value(3))
                .andExpect(jsonPath("$.result.plan.days[0].day").value("SUNDAY"));

        ArgumentCaptor<MealPlanVersion> archivedCaptor = ArgumentCaptor.forClass(MealPlanVersion.class);
        verify(versionRepository).save(archivedCaptor.capture());
        assertThat(archivedCaptor.getValue().getVersion()).isEqualTo(2);
        assertThat(archivedCaptor.getValue().getName()).isEqualTo("Thực đơn v2");
        assertThat(archivedCaptor.getValue().getChangeSummary()).isEqualTo("Quay về bản tuần trước");
    }

    @Test
    void restoreVersionWhenVersionMissingReturns404Code6017() throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        MealPlanRepository repository = mock(MealPlanRepository.class);
        MealPlanVersionRepository versionRepository = mock(MealPlanVersionRepository.class);
        MealPlan current = new MealPlan(7L, "Thực đơn v2", "Tăng cơ", "{\"days\":[]}", 2);

        when(repository.findByIdAndUserId(15L, 7L)).thenReturn(Optional.of(current));
        when(versionRepository.findByMealPlanIdAndVersion(15L, 99)).thenReturn(Optional.empty());

        MealPlanService service = new MealPlanService(repository, mock(RestClient.class), "http://recipe",
                "http://nutrition", "http://identity", mock(GroqClient.class),
                new ModelProperties("c", "m", "r", "p", "v", "w"),
                mapper, mock(UsageService.class), new MealPlanValidator(mapper),
                mock(MealPlanFavoriteRepository.class), versionRepository, mock(PremiumQuotaService.class));

        mockMvcFor(service).perform(post("/ai/meal-plans/15/versions/99/restore"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value(6017));
    }

    @Test
    void nutritionTargetReturnsTheComputedTarget() throws Exception {
        MealPlanService service = mock(MealPlanService.class);
        when(service.nutritionTarget("token", GoalType.GAIN)).thenReturn(new MealPlanDtos.NutritionTargetResponse(
                GoalType.GAIN, 1805, 2482, 2854, new MealPlanDtos.NutritionTarget(
                        java.math.BigDecimal.valueOf(2569), java.math.BigDecimal.valueOf(3140),
                        null, null, null, null, null, null)));

        mockMvcFor(service).perform(get("/ai/meal-plans/nutrition-target").param("goalType", "GAIN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.goalType").value("GAIN"))
                .andExpect(jsonPath("$.result.bmr").value(1805))
                .andExpect(jsonPath("$.result.targetCalories").value(2854))
                .andExpect(jsonPath("$.result.target.minCalories").value(2569));
    }

    @Test
    void nutritionTargetWithoutGoalTypeIs400() throws Exception {
        mockMvcFor(mock(MealPlanService.class)).perform(get("/ai/meal-plans/nutrition-target"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(6000));
    }

    @Test
    void nutritionTargetWithUnknownGoalTypeIs400() throws Exception {
        mockMvcFor(mock(MealPlanService.class)).perform(get("/ai/meal-plans/nutrition-target").param("goalType", "FOO"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(6000));
    }

    @Test
    void generateWithoutGoalTypeIs400() throws Exception {
        mockMvcFor(mock(MealPlanService.class)).perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                        .post("/ai/meal-plans").contentType(org.springframework.http.MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Tuần này\",\"healthGoal\":\"Tăng cơ\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(6000));
    }

    @Test
    void generateWithUnknownGoalTypeIs400NotA500() throws Exception {
        mockMvcFor(mock(MealPlanService.class)).perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                        .post("/ai/meal-plans").contentType(org.springframework.http.MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Tuần này\",\"healthGoal\":\"Tăng cơ\",\"goalType\":\"FOO\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(6000));
    }
}
