package com.veggiepal.dto.response;

import java.time.LocalDateTime;

import com.veggiepal.enums.BadgeCode;

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
public class BadgeItemResponse {

    BadgeCode code;
    String title;
    String description;
    String icon;
    boolean earned;
    LocalDateTime earnedAt;
}

