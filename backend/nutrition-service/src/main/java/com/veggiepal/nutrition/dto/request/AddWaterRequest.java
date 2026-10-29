package com.veggiepal.nutrition.dto.request;

import java.time.LocalDate;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

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
public class AddWaterRequest {

    LocalDate date;

    @NotNull(message = "INVALID_WATER_AMOUNT")
    @Min(value = 1, message = "INVALID_WATER_AMOUNT")
    @Max(value = 5000, message = "INVALID_WATER_AMOUNT")
    Integer amountMl;
}

