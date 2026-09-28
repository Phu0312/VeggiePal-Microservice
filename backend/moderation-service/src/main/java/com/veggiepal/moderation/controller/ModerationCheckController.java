package com.veggiepal.moderation.controller;

import org.springframework.web.bind.annotation.*;

import com.veggiepal.moderation.dto.request.ModerationCheckRequest;
import com.veggiepal.moderation.dto.response.ApiResponse;
import com.veggiepal.moderation.dto.response.ModerationResult;
import com.veggiepal.moderation.service.ModerationService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@RestController
@RequestMapping("/moderation")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Tag(name = "Content Moderation Check", description = "Automated keyword-based moderation check")
public class ModerationCheckController {

    ModerationService moderationService;

    @Operation(summary = "Check content for toxic or non-vegan keywords")
    @PostMapping("/check")
    public ApiResponse<ModerationResult> checkContent(@RequestBody ModerationCheckRequest request) {
        return ApiResponse.<ModerationResult>builder()
                .result(moderationService.checkContent(
                        request.getText(),
                        request.getTargetType(),
                        request.getTargetId(),
                        request.getAuthorId()
                ))
                .build();
    }
}
