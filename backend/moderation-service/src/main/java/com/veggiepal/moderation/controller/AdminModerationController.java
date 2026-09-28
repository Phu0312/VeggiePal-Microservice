package com.veggiepal.moderation.controller;

import java.util.List;

import jakarta.validation.Valid;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import com.veggiepal.moderation.configuration.CurrentUser;
import com.veggiepal.moderation.dto.request.ReviewModerationRequest;
import com.veggiepal.moderation.dto.response.ApiResponse;
import com.veggiepal.moderation.entity.ModerationCase;
import com.veggiepal.moderation.enums.ModerationDecision;
import com.veggiepal.moderation.service.ModerationService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@RestController
@RequestMapping("/admin/moderation")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Tag(name = "Admin Moderation", description = "Admin content moderation queue and review")
@PreAuthorize("hasRole('ADMIN')")
public class AdminModerationController {

    ModerationService moderationService;

    @Operation(summary = "Get moderation cases queue (optionally filtered by status PENDING, APPROVED, REJECTED)")
    @GetMapping("/queue")
    public ApiResponse<List<ModerationCase>> getQueue(
            @RequestParam(required = false) ModerationDecision status
    ) {
        return ApiResponse.<List<ModerationCase>>builder()
                .result(moderationService.getQueue(status))
                .build();
    }

    @Operation(summary = "Get single moderation case detail")
    @GetMapping("/{id}")
    public ApiResponse<ModerationCase> getCase(
            @PathVariable Long id
    ) {
        return ApiResponse.<ModerationCase>builder()
                .result(moderationService.getCaseById(id))
                .build();
    }

    @Operation(summary = "Review a moderation case: approve or reject")
    @PostMapping("/{id}/review")
    public ApiResponse<ModerationCase> reviewCase(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @PathVariable Long id,
            @RequestBody @Valid ReviewModerationRequest request
    ) {
        return ApiResponse.<ModerationCase>builder()
                .result(moderationService.reviewCase(CurrentUser.id(jwt), id, request))
                .build();
    }
}
