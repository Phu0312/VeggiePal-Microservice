package com.veggiepal.ai.quota;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.env.Environment;
import org.springframework.core.env.Profiles;
import org.springframework.stereotype.Component;

/** Explicit, local-only quota policy. A production process fails startup if the override is requested. */
@Component
public class LocalTestQuotaPolicy {
    private final boolean enabled;
    private final int dailyRequestsPerFeature;
    private final long dailyTokenLimit;

    public LocalTestQuotaPolicy(Environment environment,
            @Value("${ai.local-test-quota.enabled:false}") boolean enabled,
            @Value("${ai.local-test-quota.daily-requests-per-feature:100}") int dailyRequestsPerFeature,
            @Value("${ai.local-test-quota.daily-token-limit:5000000}") long dailyTokenLimit,
            @Value("${ai.deployment-mode:production}") String deploymentMode) {
        if (enabled && (!environment.acceptsProfiles(Profiles.of("local-testing & !prod"))
                || !"local".equalsIgnoreCase(deploymentMode))) {
            throw new IllegalStateException("Local test quota requires the local-testing profile and local deployment mode");
        }
        if (enabled && (dailyRequestsPerFeature < 1 || dailyTokenLimit < 1)) {
            throw new IllegalArgumentException("Local test quota limits must be positive");
        }
        this.enabled = enabled;
        this.dailyRequestsPerFeature = dailyRequestsPerFeature;
        this.dailyTokenLimit = dailyTokenLimit;
    }

    public boolean enabled() { return enabled; }
    public int dailyRequestsPerFeature() { return dailyRequestsPerFeature; }
    public long dailyTokenLimit() { return dailyTokenLimit; }
}
