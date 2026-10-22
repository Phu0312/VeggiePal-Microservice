package com.veggiepal.moderation.dto.request;

import jakarta.validation.constraints.NotNull;

import com.veggiepal.moderation.enums.ModerationDecision;

import lombok.*;
import lombok.experimental.FieldDefaults;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class ReviewModerationRequest {

    @NotNull(message = "MODERATION_ACTION_INVALID")
    ModerationDecision decision;

    String reason;
}
