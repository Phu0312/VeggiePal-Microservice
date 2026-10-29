package com.veggiepal.controller;

import jakarta.validation.Valid;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.veggiepal.dto.request.ForgotPasswordRequest;
import com.veggiepal.dto.request.RefreshTokenRequest;
import com.veggiepal.dto.request.ResetPasswordRequest;
import com.veggiepal.dto.request.SendVerificationRequest;
import com.veggiepal.dto.request.VerifyOtpRequest;
import com.veggiepal.dto.response.ApiResponse;
import com.veggiepal.dto.response.LoginResponse;
import com.veggiepal.dto.response.OtpSentResponse;
import com.veggiepal.dto.response.UserProfileResponse;
import com.veggiepal.dto.response.VerifyOtpResponse;
import com.veggiepal.service.OtpService;
import com.veggiepal.service.RefreshTokenService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Tag(name = "Auth Lifecycle", description = "Password reset OTP, email verification, refresh token and logout APIs")
public class AuthLifecycleController {

    OtpService otpService;
    RefreshTokenService refreshTokenService;

    @Operation(summary = "Request a 6-digit password reset OTP by email")
    @PostMapping("/forgot-password")
    ApiResponse<OtpSentResponse> forgotPassword(@RequestBody @Valid ForgotPasswordRequest request) {
        return ApiResponse.<OtpSentResponse>builder()
                .result(otpService.sendForgotPasswordOtp(request))
                .build();
    }

    @Operation(summary = "Verify a 6-digit password reset OTP and obtain a short-lived reset token")
    @PostMapping("/verify-otp")
    ApiResponse<VerifyOtpResponse> verifyOtp(@RequestBody @Valid VerifyOtpRequest request) {
        return ApiResponse.<VerifyOtpResponse>builder()
                .result(otpService.verifyForgotPasswordOtp(request))
                .build();
    }

    @Operation(summary = "Reset password using a verified reset token or email + 6-digit OTP")
    @PostMapping("/reset-password")
    ApiResponse<Void> resetPassword(@RequestBody @Valid ResetPasswordRequest request) {
        otpService.resetPassword(request);
        return ApiResponse.<Void>builder().build();
    }

    @Operation(summary = "Send or resend a 6-digit email verification OTP")
    @PostMapping("/send-verification")
    ApiResponse<OtpSentResponse> sendVerification(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @RequestBody(required = false) SendVerificationRequest request
    ) {
        Long userId = jwt != null ? CurrentUser.id(jwt) : null;
        String email = request != null ? request.getEmail() : null;
        return ApiResponse.<OtpSentResponse>builder()
                .result(otpService.sendEmailVerificationOtp(userId, email))
                .build();
    }

    @Operation(summary = "Verify user email using a 6-digit OTP")
    @PostMapping("/verify-email")
    ApiResponse<UserProfileResponse> verifyEmail(@RequestBody @Valid VerifyOtpRequest request) {
        return ApiResponse.<UserProfileResponse>builder()
                .result(otpService.verifyEmail(request))
                .build();
    }

    @Operation(summary = "Rotate refresh token and issue a new access token")
    @PostMapping("/refresh")
    ApiResponse<LoginResponse> refresh(@RequestBody @Valid RefreshTokenRequest request) {
        return ApiResponse.<LoginResponse>builder()
                .result(refreshTokenService.refresh(request.getRefreshToken()))
                .build();
    }

    @Operation(summary = "Revoke a refresh token to terminate the session")
    @PostMapping("/logout")
    ApiResponse<Void> logout(@RequestBody @Valid RefreshTokenRequest request) {
        refreshTokenService.revoke(request.getRefreshToken());
        return ApiResponse.<Void>builder().build();
    }
}

