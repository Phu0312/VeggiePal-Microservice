package com.veggiepal.blog.controller;

import java.util.List;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.veggiepal.blog.dto.response.ApiResponse;
import com.veggiepal.blog.dto.response.ChallengeProgressResponse;
import com.veggiepal.blog.dto.response.CommunityStatsResponse;
import com.veggiepal.blog.dto.response.FollowResponse;
import com.veggiepal.blog.dto.response.LeaderboardEntryResponse;
import com.veggiepal.blog.dto.response.TrendingTopicResponse;
import com.veggiepal.blog.dto.response.VideoChannelResponse;
import com.veggiepal.blog.service.CommunityService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;

@RestController
@Tag(name = "Community & Creators", description = "Leaderboard, author follows, trending topics, community stats, 7-day challenge & video channels")
public class CommunityController {

    private final CommunityService communityService;

    public CommunityController(CommunityService communityService) {
        this.communityService = communityService;
    }

    @Operation(summary = "Top community authors ranked by published posts and likes")
    @GetMapping("/blogs/community/leaderboard")
    ApiResponse<List<LeaderboardEntryResponse>> getLeaderboard(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @RequestParam(name = "limit", defaultValue = "5") int limit
    ) {
        return ApiResponse.<List<LeaderboardEntryResponse>>builder()
                .result(communityService.getLeaderboard(CurrentUser.idOrNull(jwt), limit))
                .build();
    }

    @Operation(summary = "Trending community topics ranked by published blogs and videos")
    @GetMapping("/blogs/community/trending-topics")
    ApiResponse<List<TrendingTopicResponse>> getTrendingTopics(
            @RequestParam(name = "limit", defaultValue = "8") int limit
    ) {
        return ApiResponse.<List<TrendingTopicResponse>>builder()
                .result(communityService.getTrendingTopics(limit))
                .build();
    }

    @Operation(summary = "Aggregate community statistics (published blogs, videos, active authors, comments)")
    @GetMapping("/blogs/community/stats")
    ApiResponse<CommunityStatsResponse> getCommunityStats() {
        return ApiResponse.<CommunityStatsResponse>builder()
                .result(communityService.getCommunityStats())
                .build();
    }

    @Operation(summary = "Recommended video creators / channels ranked by published videos and views")
    @GetMapping("/videos/channels")
    ApiResponse<List<VideoChannelResponse>> getVideoChannels(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @RequestParam(name = "limit", defaultValue = "10") int limit
    ) {
        return ApiResponse.<List<VideoChannelResponse>>builder()
                .result(communityService.getVideoChannels(CurrentUser.idOrNull(jwt), limit))
                .build();
    }

    @Operation(summary = "Follow a community author or video creator")
    @PostMapping("/blogs/authors/{authorId}/follow")
    ApiResponse<FollowResponse> followAuthor(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @PathVariable("authorId") Long authorId
    ) {
        return ApiResponse.<FollowResponse>builder()
                .result(communityService.followAuthor(CurrentUser.id(jwt), authorId))
                .build();
    }

    @Operation(summary = "Unfollow a community author or video creator")
    @DeleteMapping("/blogs/authors/{authorId}/follow")
    ApiResponse<FollowResponse> unfollowAuthor(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @PathVariable("authorId") Long authorId
    ) {
        return ApiResponse.<FollowResponse>builder()
                .result(communityService.unfollowAuthor(CurrentUser.id(jwt), authorId))
                .build();
    }

    @Operation(summary = "List author IDs followed by the current user")
    @GetMapping("/blogs/me/following")
    ApiResponse<List<Long>> getMyFollowing(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt
    ) {
        return ApiResponse.<List<Long>>builder()
                .result(communityService.getMyFollowingIds(CurrentUser.id(jwt)))
                .build();
    }

    @Operation(summary = "Get current user's 7-day vegan challenge streak progress")
    @GetMapping("/blogs/challenge/me")
    ApiResponse<ChallengeProgressResponse> getMyChallenge(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt
    ) {
        return ApiResponse.<ChallengeProgressResponse>builder()
                .result(communityService.getChallengeProgress(CurrentUser.id(jwt)))
                .build();
    }

    @Operation(summary = "Check in today for the 7-day vegan challenge")
    @PostMapping("/blogs/challenge/check-in")
    ApiResponse<ChallengeProgressResponse> checkInChallenge(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt
    ) {
        return ApiResponse.<ChallengeProgressResponse>builder()
                .result(communityService.checkInChallenge(CurrentUser.id(jwt)))
                .build();
    }
}
