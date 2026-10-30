package com.veggiepal.ai.common;

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
            ErrorCode previous = seen.put(errorCode.code, errorCode);
            assertNull(previous, () -> "Duplicate error code " + errorCode.code
                    + " between " + previous + " and " + errorCode);
        }
        assertEquals(6020, ErrorCode.PROFILE_INCOMPLETE.code);
        assertEquals(6021, ErrorCode.AGE_NOT_SUPPORTED.code);
        assertEquals(6025, ErrorCode.VIDEO_QUEUE_FULL.code);
        assertEquals(6026, ErrorCode.VIDEO_SOURCE_UNSUPPORTED.code);
    }
}

