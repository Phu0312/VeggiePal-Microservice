package com.veggiepal.ai.quota;

import java.time.LocalDate;
import java.util.Set;
import com.veggiepal.ai.common.AppException;
import com.veggiepal.ai.common.ErrorCode;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.env.StandardEnvironment;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.annotation.Propagation;

@Service
public class QuotaService {
    private static final Set<String> LOCAL_TEST_FEATURES = Set.of("CHAT", "MEAL_PLAN", "RECOMMENDATION", "MODERATION");
    private final DailyQuotaRepository repository;
    private final QuotaProperties properties;
    private final TokenProperties tokenProperties;
    private final LocalTestQuotaPolicy localTestPolicy;

    @Autowired
    public QuotaService(DailyQuotaRepository repository, QuotaProperties properties,
            TokenProperties tokenProperties, LocalTestQuotaPolicy localTestPolicy) {
        this.repository = repository;
        this.properties = properties;
        this.tokenProperties = tokenProperties;
        this.localTestPolicy = localTestPolicy;
    }

    // Existing unit tests construct this service without a Spring context.
    QuotaService(DailyQuotaRepository repository, QuotaProperties properties, TokenProperties tokenProperties) {
        this(repository, properties, tokenProperties,
                new LocalTestQuotaPolicy(new StandardEnvironment(), false, 100, 5000000, "production"));
    }

    @Transactional(readOnly = true)
    public void checkTokenBudget(String principalKey) {
        checkBudgetAtLimit(principalKey, tokenProperties.dailyLimit());
    }

    @Transactional(readOnly = true)
    public void checkLocalTextTokenBudget(String principalKey) {
        long limit = localTestPolicy.enabled() && principalKey.startsWith("user:")
                ? localTestPolicy.dailyTokenLimit() : tokenProperties.dailyLimit();
        checkBudgetAtLimit(principalKey, limit);
    }

    private void checkBudgetAtLimit(String principalKey, long limit) {
        if (repository.totalTokens(principalKey, LocalDate.now()) >= limit) {
            throw new AppException(ErrorCode.QUOTA_EXCEEDED);
        }
    }

    @Transactional(readOnly = true)
    public int getUsedCount(String principalKey, String feature, QuotaPeriod period) {
        LocalDate today = LocalDate.now();
        LocalDate periodDate = period == QuotaPeriod.MONTHLY ? today.withDayOfMonth(1) : today;
        // Read-only transaction: must not use the PESSIMISTIC_WRITE finder (SELECT ... FOR UPDATE).
        return repository.findRequestCount(principalKey, feature, periodDate).orElse(0);
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public int reserveChat(String principalKey, boolean guest) {
        checkTokenBudget(principalKey);
        repository.ensureExists(principalKey, "CHAT", LocalDate.now());
        DailyQuota quota = repository.findByPrincipalKeyAndFeatureAndUsageDate(principalKey, "CHAT", LocalDate.now())
                .orElseThrow();
        int limit = guest ? properties.guestDailyLimit() : properties.memberDailyLimit();
        if (quota.getRequestCount() >= limit) throw new AppException(ErrorCode.QUOTA_EXCEEDED);
        quota.reserve();
        return limit - quota.getRequestCount();
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public int reserveFeature(String principalKey, String feature, QuotaPeriod period, int limit) {
        checkTokenBudget(principalKey);
        return reserveFeatureRow(principalKey, feature, period, limit);
    }

    private int reserveFeatureRow(String principalKey, String feature, QuotaPeriod period, int limit) {
        LocalDate today = LocalDate.now();
        LocalDate periodDate = period == QuotaPeriod.MONTHLY ? today.withDayOfMonth(1) : today;
        repository.ensureExists(principalKey, feature, periodDate);
        DailyQuota quota = repository.findByPrincipalKeyAndFeatureAndUsageDate(principalKey, feature, periodDate)
                .orElseThrow();
        if (limit <= 0 || quota.getRequestCount() >= limit) throw new AppException(ErrorCode.QUOTA_EXCEEDED);
        quota.reserve();
        return limit - quota.getRequestCount();
    }

    public boolean isLocalTestEnabled() { return localTestPolicy.enabled(); }
    public int localTestLimit() { return localTestPolicy.dailyRequestsPerFeature(); }
    public String localTestFeature(String feature) { return feature + "_LOCAL_TEST"; }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public int reserveLocalTestFeature(String principalKey, String feature) {
        if (!localTestPolicy.enabled()) return -1;
        if (!principalKey.startsWith("user:") || !LOCAL_TEST_FEATURES.contains(feature)) {
            throw new IllegalArgumentException("Local test quota is only for signed-in text features");
        }
        checkLocalTextTokenBudget(principalKey);
        return reserveFeatureRow(principalKey, localTestFeature(feature), QuotaPeriod.DAILY,
                localTestPolicy.dailyRequestsPerFeature());
    }

    @Transactional
    public void refundFeature(String principalKey, String feature, QuotaPeriod period) {
        LocalDate today = LocalDate.now();
        LocalDate periodDate = period == QuotaPeriod.MONTHLY ? today.withDayOfMonth(1) : today;
        repository.findByPrincipalKeyAndFeatureAndUsageDate(principalKey, feature, periodDate)
                .ifPresent(DailyQuota::refund);
    }

    @Transactional
    public void refundFeature(String principalKey, String feature, LocalDate usageDate) {
        repository.findByPrincipalKeyAndFeatureAndUsageDate(principalKey, feature, usageDate)
                .ifPresent(DailyQuota::refund);
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void addTokens(String principalKey, String feature, int input, int output) {
        repository.ensureExists(principalKey, feature, LocalDate.now());
        DailyQuota quota = repository.findByPrincipalKeyAndFeatureAndUsageDate(principalKey, feature, LocalDate.now())
                .orElseThrow();
        quota.addTokens(input, output);
    }
}
