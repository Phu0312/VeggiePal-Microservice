package com.veggiepal.nutrition.dto.response;

import java.time.LocalDate;

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
public class DailyActivityResponse {

    LocalDate date;
    Integer waterMl;
    Integer waterTargetMl;
    Integer waterGlasses;
    Integer exerciseMinutes;
    Integer steps;
    Integer caloriesBurned;
    String activityNote;
}

