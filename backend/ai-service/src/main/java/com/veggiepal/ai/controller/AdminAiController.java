package com.veggiepal.ai.controller;

import java.util.*;

import org.springframework.data.domain.PageRequest;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import com.veggiepal.ai.dto.response.ApiResponse;
import com.veggiepal.ai.entity.AiOperationLog;
import com.veggiepal.ai.repository.AiOperationLogRepository;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@RestController
@RequestMapping("/admin/ai")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@PreAuthorize("hasRole('ADMIN')")
@Tag(name = "Admin - AI Monitoring", description = "AI operation logs and metrics (ADMIN only)")
public class AdminAiController {

    AiOperationLogRepository aiOperationLogRepository;

    @Operation(summary = "Get recent AI operation logs")
    @GetMapping("/logs")
    public ApiResponse<List<AiOperationLog>> getLogs(
            @RequestParam(value = "page", defaultValue = "0") int page,
            @RequestParam(value = "size", defaultValue = "50") int size
    ) {
        int safeSize = Math.min(Math.max(size, 1), 100);
        return ApiResponse.<List<AiOperationLog>>builder()
                .result(aiOperationLogRepository.findAllByOrderByCreatedAtDesc(PageRequest.of(page, safeSize)))
                .build();
    }

    @Operation(summary = "Get AI metrics computed from actual operation logs")
    @GetMapping("/metrics")
    public ApiResponse<Map<String, Object>> getMetrics() {
        Map<String, Object> metrics = new LinkedHashMap<>();
        metrics.put("totalRequests", aiOperationLogRepository.count());
        metrics.put("successCount", aiOperationLogRepository.countByStatus("SUCCESS"));
        metrics.put("failureCount", aiOperationLogRepository.countByStatus("FAILURE"));
        metrics.put("chatRequests", aiOperationLogRepository.countByOperationType("CHAT"));
        metrics.put("mealPlanRequests", aiOperationLogRepository.countByOperationType("MEAL_PLAN"));
        metrics.put("moderationRequests", aiOperationLogRepository.countByOperationType("MODERATION"));
        metrics.put("videoSummaryRequests", aiOperationLogRepository.countByOperationType("VIDEO_SUMMARY"));

        return ApiResponse.<Map<String, Object>>builder()
                .result(metrics)
                .build();
    }
}
