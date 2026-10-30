package com.veggiepal.nutrition.dto.request;

import java.time.LocalDate;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;

import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class DailyActivityRequest {

    LocalDate date;

    @Min(value = 0, message = "INVALID_NUTRITION_VALUE")
    Integer waterMl;

    @Min(value = 1, message = "INVALID_NUTRITION_VALUE")
    Integer waterTargetMl;

    @Min(value = 0, message = "INVALID_NUTRITION_VALUE")
    Integer exerciseMinutes;

    @Min(value = 0, message = "INVALID_NUTRITION_VALUE")
    Integer steps;

    @Min(value = 0, message = "INVALID_NUTRITION_VALUE")
    Integer caloriesBurned;

    @Size(max = 200, message = "INVALID_REQUEST")
    String activityNote;
}

