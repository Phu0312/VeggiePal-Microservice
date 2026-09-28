package com.veggiepal.moderation.dto.request;

import com.veggiepal.moderation.enums.TargetType;

import lombok.*;
import lombok.experimental.FieldDefaults;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class ModerationCheckRequest {
    String text;
    TargetType targetType;
    Long targetId;
    Long authorId;
}
