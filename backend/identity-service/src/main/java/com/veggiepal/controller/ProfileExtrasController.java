package com.veggiepal.controller;

import java.util.List;

import jakarta.validation.Valid;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.veggiepal.dto.request.FavoriteRequest;
import com.veggiepal.dto.response.ApiResponse;
import com.veggiepal.dto.response.BadgeItemResponse;
import com.veggiepal.dto.response.FavoriteItemResponse;
import com.veggiepal.dto.response.UserBadgesResponse;
import com.veggiepal.enums.FavoriteTargetType;
import com.veggiepal.service.ProfileExtrasService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@RestController
@RequestMapping("/users/me")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Tag(name = "Profile Extras", description = "Green badges and saved favorite collections")
public class ProfileExtrasController {

    ProfileExtrasService profileExtrasService;

    @Operation(summary = "List saved favorite recipes, blogs or videos for the current user")
    @GetMapping("/favorites")
    ApiResponse<List<FavoriteItemResponse>> getFavorites(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @RequestParam(name = "type", required = false) FavoriteTargetType type
    ) {
        return ApiResponse.<List<FavoriteItemResponse>>builder()
                .result(profileExtrasService.getFavorites(CurrentUser.id(jwt), type))
                .build();
    }

    @Operation(summary = "Add or update an item in the current user's favorite collection")
    @PostMapping("/favorites")
    ApiResponse<FavoriteItemResponse> saveFavorite(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @RequestBody @Valid FavoriteRequest request
    ) {
        return ApiResponse.<FavoriteItemResponse>builder()
                .result(profileExtrasService.saveFavorite(CurrentUser.id(jwt), request))
                .build();
    }

    @Operation(summary = "Remove an item from the current user's favorite collection")
    @DeleteMapping("/favorites/{targetType}/{targetId}")
    ApiResponse<Void> removeFavorite(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @PathVariable("targetType") FavoriteTargetType targetType,
            @PathVariable("targetId") Long targetId
    ) {
        profileExtrasService.removeFavorite(CurrentUser.id(jwt), targetType, targetId);
        return ApiResponse.<Void>builder().build();
    }

    @Operation(summary = "Get green badges and earned status for the current user")
    @GetMapping("/badges")
    ApiResponse<UserBadgesResponse> getBadges(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt
    ) {
        return ApiResponse.<UserBadgesResponse>builder()
                .result(profileExtrasService.getBadges(CurrentUser.id(jwt)))
                .build();
    }

    @Operation(summary = "Unlock a green badge for the current user (idempotent)")
    @PostMapping("/badges/{code}")
    ApiResponse<BadgeItemResponse> unlockBadge(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @PathVariable("code") String code
    ) {
        return ApiResponse.<BadgeItemResponse>builder()
                .result(profileExtrasService.unlockBadge(CurrentUser.id(jwt), code))
                .build();
    }
}

