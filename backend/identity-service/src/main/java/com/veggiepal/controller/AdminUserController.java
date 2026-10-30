package com.veggiepal.controller;

import jakarta.validation.Valid;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.veggiepal.dto.request.UpdateUserRoleRequest;
import com.veggiepal.dto.request.UpdateUserStatusRequest;
import com.veggiepal.dto.response.ApiResponse;
import com.veggiepal.dto.response.PageResponse;
import com.veggiepal.dto.response.UserProfileResponse;
import com.veggiepal.enums.Role;
import com.veggiepal.enums.UserStatus;
import com.veggiepal.service.AdminUserService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@RestController
@RequestMapping("/admin/users")
@PreAuthorize("hasRole('ADMIN')")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Tag(name = "Admin Users", description = "Admin user management APIs")
public class AdminUserController {

    AdminUserService adminUserService;

    @Operation(summary = "Search and list users (admin only)")
    @GetMapping
    ApiResponse<PageResponse<UserProfileResponse>> listUsers(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Role role,
            @RequestParam(required = false) UserStatus status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        return ApiResponse.<PageResponse<UserProfileResponse>>builder()
                .result(adminUserService.listUsers(keyword, role, status, page, size))
                .build();
    }

    @Operation(summary = "Get user detail by ID (admin only)")
    @GetMapping("/{id}")
    ApiResponse<UserProfileResponse> getUser(@PathVariable Long id) {
        return ApiResponse.<UserProfileResponse>builder()
                .result(adminUserService.getUser(id))
                .build();
    }

    @Operation(summary = "Lock, unlock or change user account status (admin only)")
    @PatchMapping("/{id}/status")
    ApiResponse<UserProfileResponse> updateUserStatus(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @PathVariable Long id,
            @RequestBody @Valid UpdateUserStatusRequest request
    ) {
        return ApiResponse.<UserProfileResponse>builder()
                .result(adminUserService.updateStatus(CurrentUser.id(jwt), id, request.getStatus()))
                .build();
    }

    @Operation(summary = "Change user role between USER and ADMIN (admin only)")
    @PatchMapping("/{id}/role")
    ApiResponse<UserProfileResponse> updateUserRole(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @PathVariable Long id,
            @RequestBody @Valid UpdateUserRoleRequest request
    ) {
        return ApiResponse.<UserProfileResponse>builder()
                .result(adminUserService.updateRole(CurrentUser.id(jwt), id, request.getRole()))
                .build();
    }
}

