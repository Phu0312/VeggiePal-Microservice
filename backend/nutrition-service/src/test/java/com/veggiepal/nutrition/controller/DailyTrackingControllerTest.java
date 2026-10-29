package com.veggiepal.nutrition.controller;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.LocalDate;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.RequestPostProcessor;

import com.veggiepal.nutrition.configuration.JwtConfig;
import com.veggiepal.nutrition.configuration.SecurityConfig;
import com.veggiepal.nutrition.configuration.SecurityExceptionHandler;
import com.veggiepal.nutrition.dto.request.AddWaterRequest;
import com.veggiepal.nutrition.dto.request.DailyActivityRequest;
import com.veggiepal.nutrition.dto.request.FoodLogRequest;
import com.veggiepal.nutrition.dto.response.DailyActivityResponse;
import com.veggiepal.nutrition.dto.response.DailyNutritionSummaryResponse;
import com.veggiepal.nutrition.dto.response.FoodLogResponse;
import com.veggiepal.nutrition.enums.MealType;
import com.veggiepal.nutrition.service.DailyTrackingService;

@WebMvcTest(DailyTrackingController.class)
@Import({SecurityConfig.class, JwtConfig.class, SecurityExceptionHandler.class})
class DailyTrackingControllerTest {

    static final Long USER_ID = 7L;

    @Autowired
    MockMvc mockMvc;

    @MockitoBean
    DailyTrackingService dailyTrackingService;

    static RequestPostProcessor currentUser() {
        return jwt().jwt(token -> token.claim("userId", USER_ID).claim("role", "USER"));
    }

    @Test
    void foodLogsWaterActivityAndSummaryEndpointsWork() throws Exception {
        when(dailyTrackingService.addFoodLog(eq(USER_ID), any(FoodLogRequest.class)))
                .thenReturn(FoodLogResponse.builder()
                        .id(1L)
                        .mealType(MealType.LUNCH)
                        .foodName("Salad đậu gà")
                        .calories(450)
                        .build());

        when(dailyTrackingService.updateDailyActivity(eq(USER_ID), any(DailyActivityRequest.class)))
                .thenReturn(DailyActivityResponse.builder()
                        .date(LocalDate.of(2026, 10, 29))
                        .waterMl(1800)
                        .waterTargetMl(2400)
                        .waterGlasses(6)
                        .exerciseMinutes(25)
                        .steps(7850)
                        .build());

        when(dailyTrackingService.addWater(eq(USER_ID), any(AddWaterRequest.class)))
                .thenReturn(DailyActivityResponse.builder()
                        .waterMl(2100)
                        .waterGlasses(7)
                        .build());

        when(dailyTrackingService.getDailySummary(eq(USER_ID), any()))
                .thenReturn(DailyNutritionSummaryResponse.builder()
                        .consumedCalories(1640)
                        .targetCalories(2100)
                        .remainingCalories(460)
                        .waterMl(2100)
                        .steps(7850)
                        .build());

        mockMvc.perform(post("/nutrition/me/food-logs")
                        .with(currentUser())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"mealType\":\"LUNCH\",\"foodName\":\"Salad đậu gà\",\"calories\":450}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.foodName").value("Salad đậu gà"));

        mockMvc.perform(put("/nutrition/me/daily-activity")
                        .with(currentUser())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"waterMl\":1800,\"exerciseMinutes\":25,\"steps\":7850}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.waterGlasses").value(6));

        mockMvc.perform(post("/nutrition/me/water")
                        .with(currentUser())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"amountMl\":300}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.waterMl").value(2100));

        mockMvc.perform(get("/nutrition/me/daily-summary").with(currentUser()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.consumedCalories").value(1640))
                .andExpect(jsonPath("$.result.remainingCalories").value(460));
    }

    @Test
    void addFoodLog_blankName_returnsFoodNameRequired() throws Exception {
        mockMvc.perform(post("/nutrition/me/food-logs")
                        .with(currentUser())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"foodName\":\"  \",\"calories\":200}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(2008));
    }
}

