package com.veggiepal.dto.response;

import java.time.LocalDateTime;

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
public class FavoriteItemResponse {

    Long id;
    FavoriteTargetType targetType;
    Long targetId;
    String title;
    String imageUrl;
    LocalDateTime createdAt;
}

