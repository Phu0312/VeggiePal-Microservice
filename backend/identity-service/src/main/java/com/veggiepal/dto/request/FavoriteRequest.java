package com.veggiepal.dto.request;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import com.veggiepal.enums.FavoriteTargetType;

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
public class FavoriteRequest {

    @NotNull(message = "FAVORITE_TARGET_REQUIRED")
    FavoriteTargetType targetType;

    @NotNull(message = "FAVORITE_TARGET_REQUIRED")
    Long targetId;

    @Size(max = 255, message = "INVALID_REQUEST")
    String title;

    @Size(max = 512, message = "INVALID_REQUEST")
    String imageUrl;
}

