package com.veggiepal.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.time.LocalDateTime;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.security.crypto.password.PasswordEncoder;

import com.veggiepal.dto.request.ForgotPasswordRequest;
import com.veggiepal.dto.request.ResetPasswordRequest;
import com.veggiepal.dto.request.VerifyOtpRequest;
import com.veggiepal.dto.response.OtpSentResponse;
import com.veggiepal.dto.response.UserProfileResponse;
import com.veggiepal.dto.response.VerifyOtpResponse;
import com.veggiepal.entity.User;
import com.veggiepal.entity.UserOtp;
import com.veggiepal.enums.OtpPurpose;
import com.veggiepal.enums.Role;
import com.veggiepal.enums.UserStatus;
import com.veggiepal.exception.AppException;
import com.veggiepal.exception.ErrorCode;
import com.veggiepal.mapper.UserMapper;
import com.veggiepal.repository.UserOtpRepository;
import com.veggiepal.repository.UserRepository;

class OtpServiceTest {

    private UserRepository userRepository;
    private UserOtpRepository userOtpRepository;
    private PasswordEncoder passwordEncoder;
    private EmailService emailService;
    private RefreshTokenService refreshTokenService;
    private UserMapper userMapper;
    private OtpService otpService;

    @BeforeEach
    void setUp() {
        userRepository = mock(UserRepository.class);
        userOtpRepository = mock(UserOtpRepository.class);
        passwordEncoder = mock(PasswordEncoder.class);
        emailService = mock(EmailService.class);
        refreshTokenService = mock(RefreshTokenService.class);
        userMapper = mock(UserMapper.class);
        otpService = new OtpService(
                userRepository,
                userOtpRepository,
                passwordEncoder,
                emailService,
                refreshTokenService,
                userMapper,
                300L,
                3
        );
    }

    @Test
    void forgotPassword_verifyOtp_andResetPasswordFlow() {
        User user = activeUser(false);
        when(userRepository.findByEmail("an@gmail.com")).thenReturn(Optional.of(user));
        when(userRepository.findById(7L)).thenReturn(Optional.of(user));

        OtpSentResponse sent = otpService.sendForgotPasswordOtp(new ForgotPasswordRequest(" An@Gmail.com "));
        assertThat(sent.getExpiresInSeconds()).isEqualTo(300L);

        ArgumentCaptor<String> codeCaptor = ArgumentCaptor.forClass(String.class);
        verify(emailService).sendOtpEmail(eq("an@gmail.com"), eq(OtpPurpose.PASSWORD_RESET), codeCaptor.capture(), eq(300L));
        String otpCode = codeCaptor.getValue();
        assertThat(otpCode).matches("\\d{6}");

        ArgumentCaptor<UserOtp> savedOtpCaptor = ArgumentCaptor.forClass(UserOtp.class);
        verify(userOtpRepository).save(savedOtpCaptor.capture());
        UserOtp storedOtp = savedOtpCaptor.getValue();
        assertThat(storedOtp.getCodeHash()).isNotEqualTo(otpCode);

        when(userOtpRepository.findFirstByEmailAndPurposeAndUsedFalseOrderByCreatedAtDesc(
                "an@gmail.com", OtpPurpose.PASSWORD_RESET)).thenReturn(Optional.of(storedOtp));

        VerifyOtpResponse verified = otpService.verifyForgotPasswordOtp(new VerifyOtpRequest("an@gmail.com", otpCode));
        assertThat(verified.isVerified()).isTrue();
        assertThat(verified.getResetToken()).isNotBlank();

        when(userOtpRepository.findFirstByResetTokenAndPurposeAndUsedFalse(
                storedOtp.getResetToken(), OtpPurpose.PASSWORD_RESET)).thenReturn(Optional.of(storedOtp));
        when(passwordEncoder.encode("newSecret123")).thenReturn("new-hash");

        otpService.resetPassword(ResetPasswordRequest.builder()
                .resetToken(verified.getResetToken())
                .newPassword("newSecret123")
                .build());

        assertThat(user.getPasswordHash()).isEqualTo("new-hash");
        assertThat(storedOtp.getUsed()).isTrue();
        verify(refreshTokenService).revokeAllForUser(7L);
    }

    @Test
    void forgotPassword_unknownEmail_doesNotLeakExistenceOrSendMail() {
        when(userRepository.findByEmail("nobody@gmail.com")).thenReturn(Optional.empty());

        OtpSentResponse response = otpService.sendForgotPasswordOtp(new ForgotPasswordRequest("nobody@gmail.com"));

        assertThat(response.getExpiresInSeconds()).isEqualTo(300L);
        verify(emailService, never()).sendOtpEmail(anyString(), any(), anyString(), anyLong());
    }

    @Test
    void verifyOtp_exceedingMaxAttempts_locksOutCode() {
        UserOtp storedOtp = UserOtp.builder()
                .id(1L)
                .userId(7L)
                .email("an@gmail.com")
                .purpose(OtpPurpose.PASSWORD_RESET)
                .codeHash(TokenHashUtils.sha256Hex("an@gmail.com:PASSWORD_RESET:123456"))
                .attempts(2)
                .used(false)
                .expiresAt(LocalDateTime.now().plusMinutes(5))
                .build();
        when(userOtpRepository.findFirstByEmailAndPurposeAndUsedFalseOrderByCreatedAtDesc(
                "an@gmail.com", OtpPurpose.PASSWORD_RESET)).thenReturn(Optional.of(storedOtp));

        assertThatThrownBy(() -> otpService.verifyForgotPasswordOtp(new VerifyOtpRequest("an@gmail.com", "000000")))
                .isInstanceOfSatisfying(AppException.class,
                        e -> assertThat(e.getErrorCode()).isEqualTo(ErrorCode.OTP_MAX_ATTEMPTS_EXCEEDED));
        assertThat(storedOtp.getAttempts()).isEqualTo(3);
    }

    @Test
    void verifyEmail_marksUserVerified_andResendHasGenericResponse() {
        User user = activeUser(false);
        UserOtp storedOtp = UserOtp.builder()
                .id(2L)
                .userId(7L)
                .email("an@gmail.com")
                .purpose(OtpPurpose.EMAIL_VERIFICATION)
                .codeHash(TokenHashUtils.sha256Hex("an@gmail.com:EMAIL_VERIFICATION:654321"))
                .attempts(0)
                .used(false)
                .expiresAt(LocalDateTime.now().plusMinutes(5))
                .build();

        when(userOtpRepository.findFirstByEmailAndPurposeAndUsedFalseOrderByCreatedAtDesc(
                "an@gmail.com", OtpPurpose.EMAIL_VERIFICATION)).thenReturn(Optional.of(storedOtp));
        when(userRepository.findById(7L)).thenReturn(Optional.of(user));
        when(userMapper.toUserProfileResponse(user))
                .thenReturn(UserProfileResponse.builder().id(7L).email("an@gmail.com").emailVerified(true).build());

        UserProfileResponse profile = otpService.verifyEmail(new VerifyOtpRequest("an@gmail.com", "654321"));

        assertThat(profile.getEmailVerified()).isTrue();
        assertThat(user.getEmailVerified()).isTrue();
        assertThat(storedOtp.getUsed()).isTrue();

        assertThat(otpService.sendEmailVerificationOtp(7L, null).getMessage())
                .contains("If the email needs verification");
        verify(emailService, never()).sendOtpEmail(anyString(), any(), anyString(), anyLong());
    }

    @Test
    void sendVerification_doesNotRevealUnknownOrVerifiedEmail() {
        User verified = activeUser(true);
        when(userRepository.findByEmail("an@gmail.com")).thenReturn(Optional.of(verified));
        when(userRepository.findByEmail("nobody@gmail.com")).thenReturn(Optional.empty());

        String known = otpService.sendEmailVerificationOtp(null, "an@gmail.com", "192.0.2.1").getMessage();
        String unknown = otpService.sendEmailVerificationOtp(null, "nobody@gmail.com", "192.0.2.1").getMessage();

        assertThat(known).isEqualTo(unknown);
        verify(emailService, never()).sendOtpEmail(anyString(), any(), anyString(), anyLong());
    }

    @Test
    void repeatedSendsDoNotIssueMoreThanThreeCodesPerEmail() {
        User user = activeUser(false);
        when(userRepository.findByEmail("an@gmail.com")).thenReturn(Optional.of(user));
        ForgotPasswordRequest request = new ForgotPasswordRequest("an@gmail.com");
        for (int i = 0; i < 4; i++) otpService.sendForgotPasswordOtp(request, "192.0.2.2");
        org.mockito.Mockito.verify(emailService, org.mockito.Mockito.times(3))
                .sendOtpEmail(eq("an@gmail.com"), eq(OtpPurpose.PASSWORD_RESET), anyString(), eq(300L));
    }

    @Test
    void sendLimitAppliesAcrossEmailsFromSameIp() {
        for (int i = 0; i < 10; i++) {
            otpService.sendForgotPasswordOtp(new ForgotPasswordRequest("user" + i + "@example.com"), "192.0.2.9");
        }
        assertThatThrownBy(() -> otpService.sendForgotPasswordOtp(
                new ForgotPasswordRequest("user10@example.com"), "192.0.2.9"))
                .isInstanceOfSatisfying(AppException.class,
                        error -> assertThat(error.getErrorCode()).isEqualTo(ErrorCode.OTP_SEND_RATE_LIMITED));
    }

    @Test
    void failedAttemptsAcrossIssuedCodesBlockFurtherGuessing() {
        when(userOtpRepository.countFailedAttemptsSince(eq("an@gmail.com"), any())).thenReturn(10L);
        assertThatThrownBy(() -> otpService.verifyForgotPasswordOtp(new VerifyOtpRequest("an@gmail.com", "123456")))
                .isInstanceOfSatisfying(AppException.class,
                        e -> assertThat(e.getErrorCode()).isEqualTo(ErrorCode.OTP_MAX_ATTEMPTS_EXCEEDED));
        verify(userOtpRepository, never()).findFirstByEmailAndPurposeAndUsedFalseOrderByCreatedAtDesc(anyString(), any());
    }

    private static User activeUser(boolean verified) {
        return User.builder()
                .id(7L)
                .email("an@gmail.com")
                .fullName("An Nguyen")
                .passwordHash("old-hash")
                .role(Role.USER)
                .status(UserStatus.ACTIVE)
                .emailVerified(verified)
                .build();
    }
}

