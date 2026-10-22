package com.veggiepal.moderation.dto.response;

import com.veggiepal.moderation.enums.ModerationDecision;

public record ModerationResult(ModerationDecision decision, String reason, String matchedKeywords) {

    public ModerationResult(ModerationDecision decision, String reason) {
        this(decision, reason, null);
    }

    public static ModerationResult approved() {
        return new ModerationResult(ModerationDecision.APPROVED, null, null);
    }
}
