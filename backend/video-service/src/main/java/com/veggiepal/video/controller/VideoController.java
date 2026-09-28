package com.veggiepal.video.controller;

import jakarta.validation.Valid;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import com.veggiepal.video.configuration.CurrentUser;
import com.veggiepal.video.dto.request.VideoRequest;
import com.veggiepal.video.dto.response.ApiResponse;
import com.veggiepal.video.dto.response.PageResponse;
import com.veggiepal.video.dto.response.VideoResponse;
import com.veggiepal.video.dto.response.VideoSummaryResponse;
import com.veggiepal.video.enums.ContentStatus;
import com.veggiepal.video.service.VideoService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@RestController
@RequestMapping("/videos")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Tag(name = "Video", description = "Vegan cooking and nutrition videos with AI summarization")
public class VideoController {

    VideoService videoService;

    @Operation(summary = "Create a video post; publish=true publishes right away")
    @PostMapping
    public ApiResponse<VideoResponse> createVideo(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @RequestBody @Valid VideoRequest request
    ) {
        return ApiResponse.<VideoResponse>builder()
                .result(videoService.createVideo(CurrentUser.id(jwt), request))
                .build();
    }

    @Operation(summary = "My videos in any status")
    @GetMapping("/me")
    public ApiResponse<PageResponse<VideoSummaryResponse>> getOwnVideos(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @RequestParam(name = "status", required = false) ContentStatus status,
            @RequestParam(name = "page", defaultValue = "0") int page,
            @RequestParam(name = "size", defaultValue = "10") int size
    ) {
        return ApiResponse.<PageResponse<VideoSummaryResponse>>builder()
                .result(videoService.getOwnVideos(CurrentUser.id(jwt), status, page, size))
                .build();
    }

    @Operation(summary = "Edit a video post")
    @PutMapping("/{id}")
    public ApiResponse<VideoResponse> updateVideo(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @PathVariable Long id,
            @RequestBody @Valid VideoRequest request
    ) {
        return ApiResponse.<VideoResponse>builder()
                .result(videoService.updateVideo(CurrentUser.id(jwt), id, request))
                .build();
    }

    @Operation(summary = "Delete a video post")
    @DeleteMapping("/{id}")
    public ApiResponse<Void> deleteVideo(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @PathVariable Long id
    ) {
        videoService.deleteVideo(CurrentUser.id(jwt), id);
        return ApiResponse.<Void>builder()
                .message("Video deleted successfully")
                .build();
    }

    @Operation(summary = "List published videos (public)")
    @GetMapping
    public ApiResponse<PageResponse<VideoSummaryResponse>> getPublishedVideos(
            @RequestParam(name = "categoryId", required = false) Long categoryId,
            @RequestParam(name = "keyword", required = false) String keyword,
            @RequestParam(name = "page", defaultValue = "0") int page,
            @RequestParam(name = "size", defaultValue = "10") int size
    ) {
        return ApiResponse.<PageResponse<VideoSummaryResponse>>builder()
                .result(videoService.getPublishedVideos(categoryId, keyword, page, size))
                .build();
    }

    @Operation(summary = "Get video details by id and increment view count (public)")
    @GetMapping("/{id}")
    public ApiResponse<VideoResponse> getVideoDetail(@PathVariable Long id) {
        return ApiResponse.<VideoResponse>builder()
                .result(videoService.getVideoDetail(id))
                .build();
    }

    @Operation(summary = "AI Video Summarization: Extract cooking steps, vegan ingredients, and nutrition highlights")
    @PostMapping("/{id}/summarize")
    public ApiResponse<VideoResponse> summarizeVideo(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @PathVariable Long id
    ) {
        return ApiResponse.<VideoResponse>builder()
                .result(videoService.summarizeVideo(CurrentUser.id(jwt), id))
                .build();
    }
}
