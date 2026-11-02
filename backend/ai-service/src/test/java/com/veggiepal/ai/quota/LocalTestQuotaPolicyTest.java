package com.veggiepal.ai.quota;

import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.Test;
import org.springframework.mock.env.MockEnvironment;

class LocalTestQuotaPolicyTest {
    @Test
    void requiresExplicitLocalProfileModeAndFlag() {
        MockEnvironment local = new MockEnvironment();
        local.setActiveProfiles("local-testing");
        assertTrue(new LocalTestQuotaPolicy(local, true, 100, 5000000, "local").enabled());
        assertFalse(new LocalTestQuotaPolicy(local, false, 100, 5000000, "production").enabled());
        assertThrows(IllegalStateException.class,
                () -> new LocalTestQuotaPolicy(local, true, 100, 5000000, "production"));
        assertThrows(IllegalStateException.class,
                () -> new LocalTestQuotaPolicy(new MockEnvironment(), true, 100, 5000000, "local"));
        local.setActiveProfiles("local-testing", "prod");
        assertThrows(IllegalStateException.class,
                () -> new LocalTestQuotaPolicy(local, true, 100, 5000000, "local"));
    }

    @Test
    void rejectsInvalidLocalLimits() {
        MockEnvironment local = new MockEnvironment();
        local.setActiveProfiles("local-testing");
        assertThrows(IllegalArgumentException.class,
                () -> new LocalTestQuotaPolicy(local, true, 0, 5000000, "local"));
        assertThrows(IllegalArgumentException.class,
                () -> new LocalTestQuotaPolicy(local, true, 100, 0, "local"));
    }
}
