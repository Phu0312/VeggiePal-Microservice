package com.veggiepal.controller;

import jakarta.validation.Valid;

import org.springframework.data.domain.Page;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import com.veggiepal.dto.request.UpdateUserStatusRequest;
import com.veggiepal.dto.response.ApiResponse;
import com.veggiepal.dto.response.UserProfileResponse;
import com.veggiepal.service.AdminUserService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@RestController
@RequestMapping("/admin/users")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@PreAuthorize("hasRole('ADMIN')")
@Tag(name = "Admin - Users", description = "Admin user management APIs")
public class AdminUserController {

    AdminUserService adminUserService;

    @Operation(summary = "List all users with optional search")
    @GetMapping
    ApiResponse<Page<UserProfileResponse>> getUsers(
            @RequestParam(name = "keyword", required = false) String keyword,
            @RequestParam(name = "page", defaultValue = "0") int page,
            @RequestParam(name = "size", defaultValue = "20") int size
    ) {

        return ApiResponse
                .<Page<UserProfileResponse>>builder()
                .result(adminUserService.getUsers(keyword, page, size))
                .build();
    }

    @Operation(summary = "Get user detail by ID")
    @GetMapping("/{id}")
    ApiResponse<UserProfileResponse> getUser(@PathVariable("id") Long id) {

        return ApiResponse
                .<UserProfileResponse>builder()
                .result(adminUserService.getUser(id))
                .build();
    }

    @Operation(summary = "Update user status (ACTIVE, BLOCKED, etc.)")
    @PatchMapping("/{id}/status")
    ApiResponse<UserProfileResponse> updateUserStatus(
            @PathVariable("id") Long id,
            @RequestBody @Valid UpdateUserStatusRequest request
    ) {

        return ApiResponse
                .<UserProfileResponse>builder()
                .result(adminUserService.updateUserStatus(id, request.getStatus()))
                .build();
    }
}
