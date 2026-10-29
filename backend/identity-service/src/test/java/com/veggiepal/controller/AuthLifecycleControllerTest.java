package com.veggiepal.controller;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import com.veggiepal.configuration.JwtConfig;
import com.veggiepal.configuration.SecurityConfig;
import com.veggiepal.configuration.SecurityExceptionHandler;
import com.veggiepal.dto.response.LoginResponse;
import com.veggiepal.dto.response.OtpSentResponse;
import com.veggiepal.dto.response.UserProfileResponse;
import com.veggiepal.dto.response.VerifyOtpResponse;
import com.veggiepal.exception.GlobalExceptionHandler;
import com.veggiepal.service.OtpService;
import com.veggiepal.service.RefreshTokenService;

@WebMvcTest(AuthLifecycleController.class)
@Import({SecurityConfig.class, JwtConfig.class, SecurityExceptionHandler.class, GlobalExceptionHandler.class})
class AuthLifecycleControllerTest {

    @Autowired
    MockMvc mockMvc;

    @MockitoBean
    OtpService otpService;

    @MockitoBean
    RefreshTokenService refreshTokenService;

    @Test
    void forgotVerifyAndResetPasswordArePublicAndAcceptContactAlias() throws Exception {
        when(otpService.sendForgotPasswordOtp(any()))
                .thenReturn(OtpSentResponse.builder().message("sent").expiresInSeconds(300).build());
        when(otpService.verifyForgotPasswordOtp(any()))
                .thenReturn(VerifyOtpResponse.builder().verified(true).resetToken("rst-1").expiresInSeconds(600).build());

        mockMvc.perform(post("/auth/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"contact\":\"an@gmail.com\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.expiresInSeconds").value(300));

        mockMvc.perform(post("/auth/verify-otp")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"an@gmail.com\",\"otp\":\"123456\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.verified").value(true))
                .andExpect(jsonPath("$.result.resetToken").value("rst-1"));

        mockMvc.perform(post("/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"resetToken\":\"rst-1\",\"newPassword\":\"secret123\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(1000));
    }

    @Test
    void emailVerificationAndRefreshLogoutEndpointsWork() throws Exception {
        when(otpService.sendEmailVerificationOtp(7L, null))
                .thenReturn(OtpSentResponse.builder().message("sent").expiresInSeconds(300).build());
        when(otpService.verifyEmail(any()))
                .thenReturn(UserProfileResponse.builder().id(7L).email("an@gmail.com").emailVerified(true).build());
        when(refreshTokenService.refresh("ref-token"))
                .thenReturn(LoginResponse.builder().accessToken("acc-2").refreshToken("ref-2").build());

        mockMvc.perform(post("/auth/send-verification")
                        .with(jwt().jwt(token -> token.claim("userId", 7L).claim("role", "USER"))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.expiresInSeconds").value(300));

        mockMvc.perform(post("/auth/verify-email")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"an@gmail.com\",\"otp\":\"654321\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.emailVerified").value(true));

        mockMvc.perform(post("/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"refreshToken\":\"ref-token\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.accessToken").value("acc-2"))
                .andExpect(jsonPath("$.result.refreshToken").value("ref-2"));

        mockMvc.perform(post("/auth/logout")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"refreshToken\":\"ref-2\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(1000));
        verify(refreshTokenService).revoke("ref-2");
    }
}

