package com.veggiepal.blog.controller;

import jakarta.validation.Valid;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import com.veggiepal.blog.dto.request.VideoRequest;
import com.veggiepal.blog.dto.response.ApiResponse;
import com.veggiepal.blog.dto.response.PageResponse;
import com.veggiepal.blog.dto.response.VideoResponse;
import com.veggiepal.blog.dto.response.VideoSummaryResponse;
import com.veggiepal.blog.enums.ContentStatus;
import com.veggiepal.blog.service.VideoService;

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

    @Operation(summary = "Create a video post; publish=true runs moderation right away")
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
            @PathVariable("id") Long id,
            @RequestBody @Valid VideoRequest request
    ) {
        return ApiResponse.<VideoResponse>builder()
                .result(videoService.updateVideo(CurrentUser.id(jwt), CurrentUser.isAdmin(jwt), id, request))
                .build();
    }

    @Operation(summary = "Submit a draft video post for moderation")
    @PostMapping("/{id}/submit")
    public ApiResponse<VideoResponse> submitVideo(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @PathVariable("id") Long id
    ) {
        return ApiResponse.<VideoResponse>builder()
                .result(videoService.submitVideo(CurrentUser.id(jwt), id))
                .build();
    }

    @Operation(summary = "Delete a video; owner or admin")
    @DeleteMapping("/{id}")
    public ApiResponse<Void> deleteVideo(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @PathVariable("id") Long id
    ) {
        videoService.deleteVideo(CurrentUser.id(jwt), CurrentUser.isAdmin(jwt), id);
        return ApiResponse.<Void>builder().build();
    }

    @Operation(summary = "Published videos with optional keyword search and category filtering")
    @GetMapping
    public ApiResponse<PageResponse<VideoSummaryResponse>> getPublishedVideos(
            @RequestParam(name = "categoryId", required = false) Long categoryId,
            @RequestParam(name = "keyword", required = false) String keyword,
            @RequestParam(name = "sort", required = false) String sort,
            @RequestParam(name = "page", defaultValue = "0") int page,
            @RequestParam(name = "size", defaultValue = "10") int size
    ) {
        return ApiResponse.<PageResponse<VideoSummaryResponse>>builder()
                .result(videoService.getPublishedVideos(categoryId, keyword, sort, page, size))
                .build();
    }

    @Operation(summary = "One published video with AI summary; counts a view")
    @GetMapping("/{id}")
    public ApiResponse<VideoResponse> getPublishedVideo(
            @PathVariable("id") Long id
    ) {
        return ApiResponse.<VideoResponse>builder()
                .result(videoService.getPublishedVideo(id))
                .build();
    }

    @Operation(summary = "Run AI summarization on a video")
    @PostMapping("/{id}/summarize")
    public ApiResponse<VideoResponse> summarizeVideo(
            @PathVariable("id") Long id
    ) {
        return ApiResponse.<VideoResponse>builder()
                .result(videoService.summarizeVideo(id))
                .build();
    }
}
