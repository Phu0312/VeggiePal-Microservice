package com.veggiepal.blog.exception;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

import java.util.HashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

class ErrorCodeTest {

    @Test
    void allErrorCodesHaveUniqueNumericValues() {
        Map<Integer, ErrorCode> seen = new HashMap<>();
        for (ErrorCode errorCode : ErrorCode.values()) {
            ErrorCode previous = seen.put(errorCode.getCode(), errorCode);
            assertNull(previous, () -> "Duplicate error code " + errorCode.getCode()
                    + " between " + previous + " and " + errorCode);
        }
    }

    @Test
    void moderationAndBadgeFailuresHaveDistinctCodes() {
        assertEquals(3051, ErrorCode.INVALID_MODERATION_RESPONSE.getCode());
        assertEquals(3053, ErrorCode.BADGE_AWARD_UNAVAILABLE.getCode());
    }
}
