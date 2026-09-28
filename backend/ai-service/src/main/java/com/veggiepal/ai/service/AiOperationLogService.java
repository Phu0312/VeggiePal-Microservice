package com.veggiepal.ai.service;

import org.springframework.stereotype.Service;

import com.veggiepal.ai.entity.AiOperationLog;
import com.veggiepal.ai.repository.AiOperationLogRepository;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class AiOperationLogService {

    AiOperationLogRepository aiOperationLogRepository;

    public void logOperation(String operationType, String provider, String status, Long durationMs, String errorMessage) {
        AiOperationLog log = AiOperationLog.builder()
                .operationType(operationType)
                .provider(provider)
                .status(status)
                .durationMs(durationMs)
                .errorMessage(errorMessage)
                .build();

        aiOperationLogRepository.save(log);
    }
}
