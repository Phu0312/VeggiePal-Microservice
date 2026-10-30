package com.veggiepal.controller;

import com.veggiepal.dto.response.ApiResponse;
import com.veggiepal.dto.response.BadgeItemResponse;
import com.veggiepal.exception.AppException;
import com.veggiepal.exception.ErrorCode;
import com.veggiepal.service.ProfileExtrasService;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/internal/badges")
@RequiredArgsConstructor
public class InternalBadgeController {
    private final ProfileExtrasService badges;

    @Value("${services.internal-token:}")
    private String internalToken;

    @PostMapping("/green-heart/{userId}")
    ApiResponse<BadgeItemResponse> awardGreenHeart(
            @PathVariable Long userId,
            @RequestHeader(name = "X-Internal-Service-Token", required = false) String supplied) {
        byte[] expected = internalToken.getBytes(StandardCharsets.UTF_8);
        byte[] actual = supplied == null ? new byte[0] : supplied.getBytes(StandardCharsets.UTF_8);
        if (expected.length == 0 || !MessageDigest.isEqual(expected, actual)) {
            throw new AppException(ErrorCode.UNAUTHENTICATED);
        }
        return ApiResponse.<BadgeItemResponse>builder()
                .result(badges.unlockBadge(userId, "VEGGIE_GREEN_HEART"))
                .build();
    }
}
