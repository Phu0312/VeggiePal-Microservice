package com.veggiepal.nutrition.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.veggiepal.nutrition.dto.request.AddWaterRequest;
import com.veggiepal.nutrition.dto.request.DailyActivityRequest;
import com.veggiepal.nutrition.dto.request.FoodLogRequest;
import com.veggiepal.nutrition.dto.response.DailyActivityResponse;
import com.veggiepal.nutrition.dto.response.DailyNutritionSummaryResponse;
import com.veggiepal.nutrition.dto.response.FoodLogResponse;
import com.veggiepal.nutrition.entity.DailyWellnessLog;
import com.veggiepal.nutrition.entity.FoodLog;
import com.veggiepal.nutrition.entity.HealthRecord;
import com.veggiepal.nutrition.enums.MealType;
import com.veggiepal.nutrition.exception.AppException;
import com.veggiepal.nutrition.exception.ErrorCode;
import com.veggiepal.nutrition.repository.DailyWellnessLogRepository;
import com.veggiepal.nutrition.repository.FoodLogRepository;
import com.veggiepal.nutrition.repository.HealthRecordRepository;

@ExtendWith(MockitoExtension.class)
class DailyTrackingServiceTest {

    @Mock
    FoodLogRepository foodLogRepository;

    @Mock
    DailyWellnessLogRepository dailyWellnessLogRepository;

    @Mock
    HealthRecordRepository healthRecordRepository;

    @Mock
    NutritionTargetClient nutritionTargetClient;

    @InjectMocks
    DailyTrackingService dailyTrackingService;

    @Test
    void addAndDeleteFoodLog_handlesOwnership() {
        LocalDate today = LocalDate.of(2026, 10, 29);
        when(foodLogRepository.save(any(FoodLog.class))).thenAnswer(inv -> {
            FoodLog saved = inv.getArgument(0);
            saved.setId(11L);
            return saved;
        });

        FoodLogResponse created = dailyTrackingService.addFoodLog(7L, FoodLogRequest.builder()
                .logDate(today)
                .mealType(MealType.BREAKFAST)
                .foodName("  Phở chay nấm hương ")
                .calories(420)
                .proteinG(new BigDecimal("18.5"))
                .carbsG(new BigDecimal("58"))
                .fatG(new BigDecimal("9.2"))
                .build());

        assertThat(created.getId()).isEqualTo(11L);
        assertThat(created.getFoodName()).isEqualTo("Phở chay nấm hương");
        assertThat(created.getCalories()).isEqualTo(420);

        when(foodLogRepository.findByIdAndUserId(99L, 7L)).thenReturn(Optional.empty());
        assertThatThrownBy(() -> dailyTrackingService.deleteFoodLog(7L, 99L))
                .isInstanceOf(AppException.class)
                .extracting("errorCode")
                .isEqualTo(ErrorCode.FOOD_LOG_NOT_EXISTED);
    }

    @Test
    void waterAndDailySummary_combinesFoodLogsWellnessAndHealthTarget() {
        LocalDate date = LocalDate.of(2026, 10, 29);
        when(dailyWellnessLogRepository.findByUserIdAndLogDate(7L, date)).thenReturn(Optional.empty());
        when(dailyWellnessLogRepository.save(any(DailyWellnessLog.class))).thenAnswer(inv -> inv.getArgument(0));

        DailyActivityResponse afterWater = dailyTrackingService.addWater(7L, AddWaterRequest.builder()
                .date(date)
                .amountMl(600)
                .build());
        assertThat(afterWater.getWaterMl()).isEqualTo(600);
        assertThat(afterWater.getWaterGlasses()).isEqualTo(2);

        DailyWellnessLog persistedWellness = DailyWellnessLog.builder()
                .userId(7L)
                .logDate(date)
                .waterMl(1800)
                .waterTargetMl(2400)
                .exerciseMinutes(25)
                .steps(7850)
                .caloriesBurned(320)
                .activityNote("25 phút Yoga sáng")
                .build();
        when(dailyWellnessLogRepository.findByUserIdAndLogDate(7L, date)).thenReturn(Optional.of(persistedWellness));

        dailyTrackingService.updateDailyActivity(7L, DailyActivityRequest.builder()
                .date(date)
                .exerciseMinutes(30)
                .build());
        verify(dailyWellnessLogRepository, org.mockito.Mockito.times(2)).save(any(DailyWellnessLog.class));

        when(foodLogRepository.findByUserIdAndLogDateOrderByCreatedAtAsc(7L, date)).thenReturn(List.of(
                FoodLog.builder()
                        .id(1L)
                        .userId(7L)
                        .logDate(date)
                        .mealType(MealType.LUNCH)
                        .foodName("Cơm gạo lứt đậu hũ")
                        .calories(640)
                        .proteinG(new BigDecimal("25.00"))
                        .carbsG(new BigDecimal("85.00"))
                        .fatG(new BigDecimal("18.00"))
                        .fiberG(new BigDecimal("11.00"))
                        .build()
        ));
        when(nutritionTargetClient.targetCalories("jwt", "MAINTAIN")).thenReturn(2100);

        DailyNutritionSummaryResponse summary = dailyTrackingService.getDailySummary(7L, date, "jwt", "MAINTAIN");
        assertThat(summary.getTargetCalories()).isEqualTo(2100);
        assertThat(summary.getConsumedCalories()).isEqualTo(640);
        assertThat(summary.getRemainingCalories()).isEqualTo(1460);
        assertThat(summary.getWaterMl()).isEqualTo(1800);
        assertThat(summary.getExerciseMinutes()).isEqualTo(30);
    }
}

