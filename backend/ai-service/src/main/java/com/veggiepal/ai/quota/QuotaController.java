package com.veggiepal.ai.quota;

import com.veggiepal.ai.common.ApiResponse;
import com.veggiepal.ai.security.CurrentUser;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/ai/quotas")
@RequiredArgsConstructor
public class QuotaController {

    private final PremiumQuotaService premiumQuotaService;

    @GetMapping("/me")
    public ApiResponse<QuotaDtos.QuotaOverviewResponse> myQuotas(@AuthenticationPrincipal Jwt jwt) {
        return ApiResponse.success(premiumQuotaService.getQuotaOverview(CurrentUser.id(jwt)));
    }
}

