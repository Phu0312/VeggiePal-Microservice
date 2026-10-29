package com.veggiepal.blog.controller;

import java.util.List;

import jakarta.validation.Valid;

import org.springframework.http.MediaType;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import com.veggiepal.blog.dto.request.VideoNutritionRequest;
import com.veggiepal.blog.dto.request.VideoRequest;
import com.veggiepal.blog.dto.request.VoteRequest;
import com.veggiepal.blog.dto.response.ApiResponse;
import com.veggiepal.blog.dto.response.PageResponse;
import com.veggiepal.blog.dto.response.VideoNutritionResponse;
import com.veggiepal.blog.dto.response.VideoResponse;
import com.veggiepal.blog.dto.response.VoteResponse;
import com.veggiepal.blog.enums.ContentStatus;
import com.veggiepal.blog.service.VideoService;
import com.veggiepal.blog.service.VoteService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;


@RestController
@RequestMapping("/videos")
@Tag(name = "Video", description = "Community cooking videos")
public class VideoController {

    private final VideoService videoService;
    private final VoteService voteService;

    public VideoController(VideoService videoService, VoteService voteService) {
        this.videoService = videoService;
        this.voteService = voteService;
    }

    // One multipart request, so the FE upload form drives a single progress bar (task sheet US4)
    @Operation(summary = "Post a video: exactly one of an .mp4 file or a YouTube link; publish=true runs moderation right away")
    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    ApiResponse<VideoResponse> createVideo(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @ModelAttribute @Valid VideoRequest request,
            @RequestPart(name = "file", required = false) MultipartFile file
    ) {

        return ApiResponse
                .<VideoResponse>builder()
                .result(videoService.createVideo(CurrentUser.id(jwt), request, file))
                .build();
    }

    @Operation(summary = "My videos in any status")
    @GetMapping("/me")
    ApiResponse<PageResponse<VideoResponse>> getOwnVideos(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @RequestParam(name = "status", required = false) ContentStatus status,
            @RequestParam(name = "page", defaultValue = "0") int page,
            @RequestParam(name = "size", defaultValue = "10") int size
    ) {

        return ApiResponse
                .<PageResponse<VideoResponse>>builder()
                .result(videoService.getOwnVideos(CurrentUser.id(jwt), status, page, size))
                .build();
    }

    @Operation(summary = "Edit title, description and category (youtubeUrl and publish are ignored; the source cannot change). Anything already reviewed goes back through moderation")
    @PutMapping("/{id}")
    ApiResponse<VideoResponse> updateVideo(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @PathVariable("id") Long id,
            @RequestBody @Valid VideoRequest request
    ) {

        return ApiResponse
                .<VideoResponse>builder()
                .result(videoService.updateVideo(CurrentUser.id(jwt), CurrentUser.isAdmin(jwt), id, request))
                .build();
    }

    @Operation(summary = "Submit a draft for moderation")
    @PostMapping("/{id}/submit")
    ApiResponse<VideoResponse> submitVideo(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @PathVariable("id") Long id
    ) {

        return ApiResponse
                .<VideoResponse>builder()
                .result(videoService.submitVideo(CurrentUser.id(jwt), id))
                .build();
    }

    @Operation(summary = "Delete a video; the owner deletes it, an admin takes someone else's down")
    @DeleteMapping("/{id}")
    ApiResponse<Void> deleteVideo(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @PathVariable("id") Long id
    ) {

        videoService.deleteVideo(CurrentUser.id(jwt), CurrentUser.isAdmin(jwt), id);
        return ApiResponse.<Void>builder().build();
    }

    @Operation(summary = "Published videos, most recently published first (filterable by categoryId and/or authorId)")
    @GetMapping
    ApiResponse<PageResponse<VideoResponse>> getPublishedVideos(
            @RequestParam(name = "categoryId", required = false) Long categoryId,
            @RequestParam(name = "authorId", required = false) Long authorId,
            @RequestParam(name = "page", defaultValue = "0") int page,
            @RequestParam(name = "size", defaultValue = "10") int size
    ) {

        return ApiResponse
                .<PageResponse<VideoResponse>>builder()
                .result(authorId == null
                        ? videoService.getPublishedVideos(categoryId, page, size)
                        : videoService.getPublishedVideos(categoryId, authorId, page, size))
                .build();
    }

    @Operation(summary = "One published video; counts a view")
    @GetMapping("/{id}")
    ApiResponse<VideoResponse> getPublishedVideo(
            @PathVariable("id") Long id
    ) {

        return ApiResponse
                .<VideoResponse>builder()
                .result(videoService.getPublishedVideo(id))
                .build();
    }

    @Operation(summary = "Get nutrition facts and ingredients for a published video")
    @GetMapping("/{id}/nutrition")
    ApiResponse<VideoNutritionResponse> getVideoNutrition(
            @PathVariable("id") Long id
    ) {
        return ApiResponse
                .<VideoNutritionResponse>builder()
                .result(videoService.getVideoNutrition(id))
                .build();
    }

    @Operation(summary = "Save or update nutrition facts and ingredients for a video (owner or ADMIN)")
    @PutMapping("/{id}/nutrition")
    ApiResponse<VideoNutritionResponse> updateVideoNutrition(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @PathVariable("id") Long id,
            @RequestBody @Valid VideoNutritionRequest request
    ) {
        return ApiResponse
                .<VideoNutritionResponse>builder()
                .result(videoService.updateVideoNutrition(CurrentUser.id(jwt), CurrentUser.isAdmin(jwt), id, request))
                .build();
    }

    @Operation(summary = "Vote on a video with 1 or -1; the same value again takes the vote back")
    @PostMapping("/{id}/vote")
    ApiResponse<VoteResponse> voteVideo(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @PathVariable("id") Long id,
            @RequestBody @Valid VoteRequest request
    ) {

        return ApiResponse
                .<VoteResponse>builder()
                .result(voteService.voteVideo(CurrentUser.id(jwt), id, request.getValue()))
                .build();
    }

    @Operation(summary = "Remove your vote on a video; doing it twice is harmless")
    @DeleteMapping("/{id}/vote")
    ApiResponse<VoteResponse> removeVideoVote(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @PathVariable("id") Long id
    ) {

        return ApiResponse
                .<VoteResponse>builder()
                .result(voteService.removeVideoVote(CurrentUser.id(jwt), id))
                .build();
    }

    @Operation(summary = "My vote on a list of videos, to overlay on a public listing")
    @GetMapping("/me/votes")
    ApiResponse<List<VoteResponse>> getMyVideoVotes(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @RequestParam(name = "videoIds") List<Long> videoIds
    ) {

        return ApiResponse
                .<List<VoteResponse>>builder()
                .result(voteService.getMyVideoVotes(CurrentUser.id(jwt), videoIds))
                .build();
    }
}
