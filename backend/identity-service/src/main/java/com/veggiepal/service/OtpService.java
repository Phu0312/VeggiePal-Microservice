package com.veggiepal.service;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Locale;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import com.veggiepal.dto.request.ForgotPasswordRequest;
import com.veggiepal.dto.request.ResetPasswordRequest;
import com.veggiepal.dto.request.VerifyOtpRequest;
import com.veggiepal.dto.response.OtpSentResponse;
import com.veggiepal.dto.response.UserProfileResponse;
import com.veggiepal.dto.response.VerifyOtpResponse;
import com.veggiepal.entity.User;
import com.veggiepal.entity.UserOtp;
import com.veggiepal.enums.OtpPurpose;
import com.veggiepal.enums.UserStatus;
import com.veggiepal.exception.AppException;
import com.veggiepal.exception.ErrorCode;
import com.veggiepal.mapper.UserMapper;
import com.veggiepal.repository.UserOtpRepository;
import com.veggiepal.repository.UserRepository;

import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
public class OtpService {

    private static final SecureRandom SECURE_RANDOM = new SecureRandom();
    private static final long RESET_TOKEN_GRACE_SECONDS = 600L;
    private static final int MAX_SENDS_PER_EMAIL_PER_HOUR = 3;
    private static final int MAX_SENDS_PER_IP_PER_HOUR = 10;
    private static final int MAX_FAILED_ATTEMPTS_PER_HOUR = 10;
    private final Map<String, SendWindow> sendWindows = new ConcurrentHashMap<>();

    private final UserRepository userRepository;
    private final UserOtpRepository userOtpRepository;
    private final PasswordEncoder passwordEncoder;
    private final EmailService emailService;
    private final RefreshTokenService refreshTokenService;
    private final UserMapper userMapper;
    private final long otpExpirationSeconds;
    private final int maxAttempts;

    public OtpService(
            UserRepository userRepository,
            UserOtpRepository userOtpRepository,
            PasswordEncoder passwordEncoder,
            EmailService emailService,
            RefreshTokenService refreshTokenService,
            UserMapper userMapper,
            @Value("${auth.otp.expiration-seconds:300}") long otpExpirationSeconds,
            @Value("${auth.otp.max-attempts:5}") int maxAttempts
    ) {
        this.userRepository = userRepository;
        this.userOtpRepository = userOtpRepository;
        this.passwordEncoder = passwordEncoder;
        this.emailService = emailService;
        this.refreshTokenService = refreshTokenService;
        this.userMapper = userMapper;
        this.otpExpirationSeconds = Math.max(60L, otpExpirationSeconds);
        this.maxAttempts = Math.max(1, maxAttempts);
    }

    @Transactional
    public void sendVerificationOtpSafely(User user) {
        if (user == null || user.getId() == null || Boolean.TRUE.equals(user.getEmailVerified())) {
            return;
        }
        try {
            issueAndSendOtp(user, OtpPurpose.EMAIL_VERIFICATION);
        } catch (RuntimeException exception) {
            log.warn("Could not send initial verification OTP to {}", user.getEmail(), exception);
        }
    }

    @Transactional
    public OtpSentResponse sendForgotPasswordOtp(ForgotPasswordRequest request) {
        return sendForgotPasswordOtp(request, "unknown");
    }

    @Transactional
    public OtpSentResponse sendForgotPasswordOtp(ForgotPasswordRequest request, String remoteAddress) {
        String email = normalizeEmail(request.getEmail());
        emailService.requireDeliveryAvailable();
        boolean allowed = allowSend(email, remoteAddress);
        if (allowed) {
            userRepository.findByEmail(email)
                    .filter(user -> user.getStatus() == UserStatus.ACTIVE)
                    .ifPresent(user -> issueAndSendOtp(user, OtpPurpose.PASSWORD_RESET));
        }

        return OtpSentResponse.builder()
                .message("If the email is registered, a 6-digit OTP code has been sent")
                .expiresInSeconds(otpExpirationSeconds)
                .build();
    }

    @Transactional(noRollbackFor = AppException.class)
    public VerifyOtpResponse verifyForgotPasswordOtp(VerifyOtpRequest request) {
        String email = normalizeEmail(request.getEmail());
        String code = normalizeOtp(request.getOtp());

        UserOtp otp = validateOtpCode(email, OtpPurpose.PASSWORD_RESET, code);

        String rawResetToken = UUID.randomUUID().toString();
        otp.setResetToken(TokenHashUtils.sha256Hex(rawResetToken));
        LocalDateTime extendedExpiry = LocalDateTime.now().plusSeconds(RESET_TOKEN_GRACE_SECONDS);
        if (otp.getExpiresAt().isBefore(extendedExpiry)) {
            otp.setExpiresAt(extendedExpiry);
        }
        userOtpRepository.save(otp);

        return VerifyOtpResponse.builder()
                .verified(true)
                .resetToken(rawResetToken)
                .expiresInSeconds(RESET_TOKEN_GRACE_SECONDS)
                .build();
    }

    @Transactional(noRollbackFor = AppException.class)
    public void resetPassword(ResetPasswordRequest request) {
        UserOtp otp;
        if (StringUtils.hasText(request.getResetToken())) {
            String resetTokenHash = TokenHashUtils.sha256Hex(request.getResetToken().trim());
            otp = userOtpRepository.findFirstByResetTokenAndPurposeAndUsedFalse(
                            resetTokenHash, OtpPurpose.PASSWORD_RESET)
                    .orElseThrow(() -> new AppException(ErrorCode.RESET_TOKEN_INVALID));
            if (!otp.getExpiresAt().isAfter(LocalDateTime.now())) {
                throw new AppException(ErrorCode.RESET_TOKEN_INVALID);
            }
        } else {
            if (!StringUtils.hasText(request.getEmail())) {
                throw new AppException(ErrorCode.EMAIL_REQUIRED);
            }
            if (!StringUtils.hasText(request.getOtp())) {
                throw new AppException(ErrorCode.OTP_REQUIRED);
            }
            otp = validateOtpCode(
                    normalizeEmail(request.getEmail()),
                    OtpPurpose.PASSWORD_RESET,
                    normalizeOtp(request.getOtp())
            );
        }

        User user = userRepository.findById(otp.getUserId())
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_EXISTED));
        if (user.getStatus() != UserStatus.ACTIVE) {
            throw new AppException(ErrorCode.USER_BLOCKED);
        }

        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);

        otp.setUsed(true);
        userOtpRepository.save(otp);

        refreshTokenService.revokeAllForUser(user.getId());
    }

    @Transactional
    public OtpSentResponse sendEmailVerificationOtp(Long authenticatedUserId, String requestedEmail) {
        return sendEmailVerificationOtp(authenticatedUserId, requestedEmail, "unknown");
    }

    @Transactional
    public OtpSentResponse sendEmailVerificationOtp(Long authenticatedUserId, String requestedEmail, String remoteAddress) {
        String email = authenticatedUserId == null ? normalizeEmail(requestedEmail) : null;
        emailService.requireDeliveryAvailable();
        User user;
        if (authenticatedUserId != null) {
            user = userRepository.findById(authenticatedUserId)
                    .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_EXISTED));
        } else {
            user = userRepository.findByEmail(email).orElse(null);
        }

        if (authenticatedUserId != null) {
            email = user.getEmail();
        }
        boolean allowed = allowSend(email, remoteAddress);
        if (allowed && user != null
                && (user.getStatus() == UserStatus.ACTIVE || user.getStatus() == UserStatus.PENDING)
                && !Boolean.TRUE.equals(user.getEmailVerified())) {
            issueAndSendOtp(user, OtpPurpose.EMAIL_VERIFICATION);
        }
        return OtpSentResponse.builder()
                .message("If the email needs verification, a 6-digit OTP code has been sent")
                .expiresInSeconds(otpExpirationSeconds)
                .build();
    }

    @Transactional(noRollbackFor = AppException.class)
    public UserProfileResponse verifyEmail(VerifyOtpRequest request) {
        String email = normalizeEmail(request.getEmail());
        String code = normalizeOtp(request.getOtp());

        UserOtp otp = validateOtpCode(email, OtpPurpose.EMAIL_VERIFICATION, code);
        User user = userRepository.findById(otp.getUserId())
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_EXISTED));

        user.setEmailVerified(true);
        if (user.getStatus() == UserStatus.PENDING) {
            user.setStatus(UserStatus.ACTIVE);
        }
        userRepository.save(user);

        otp.setUsed(true);
        userOtpRepository.save(otp);

        return userMapper.toUserProfileResponse(user);
    }

    private void issueAndSendOtp(User user, OtpPurpose purpose) {
        userOtpRepository.invalidateActiveOtps(user.getId(), purpose);

        String otpCode = String.format("%06d", SECURE_RANDOM.nextInt(1_000_000));
        LocalDateTime now = LocalDateTime.now();

        UserOtp otp = UserOtp.builder()
                .userId(user.getId())
                .email(user.getEmail())
                .purpose(purpose)
                .codeHash(hashOtp(user.getEmail(), purpose, otpCode))
                .attempts(0)
                .used(false)
                .expiresAt(now.plusSeconds(otpExpirationSeconds))
                .createdAt(now)
                .build();
        userOtpRepository.save(otp);

        emailService.sendOtpEmail(user.getEmail(), purpose, otpCode, otpExpirationSeconds);
    }

    private UserOtp validateOtpCode(String email, OtpPurpose purpose, String code) {
        if (userOtpRepository.countFailedAttemptsSince(email, LocalDateTime.now().minusHours(1)) >= MAX_FAILED_ATTEMPTS_PER_HOUR) {
            throw new AppException(ErrorCode.OTP_MAX_ATTEMPTS_EXCEEDED);
        }
        UserOtp otp = userOtpRepository
                .findFirstByEmailAndPurposeAndUsedFalseOrderByCreatedAtDesc(email, purpose)
                .orElseThrow(() -> new AppException(ErrorCode.OTP_INVALID_OR_EXPIRED));

        if (!otp.getExpiresAt().isAfter(LocalDateTime.now())) {
            throw new AppException(ErrorCode.OTP_INVALID_OR_EXPIRED);
        }

        int currentAttempts = otp.getAttempts() == null ? 0 : otp.getAttempts();
        if (currentAttempts >= maxAttempts) {
            throw new AppException(ErrorCode.OTP_MAX_ATTEMPTS_EXCEEDED);
        }

        String candidateHash = hashOtp(email, purpose, code);
        if (!TokenHashUtils.constantTimeEquals(otp.getCodeHash(), candidateHash)) {
            otp.setAttempts(currentAttempts + 1);
            userOtpRepository.save(otp);
            if (currentAttempts + 1 >= maxAttempts) {
                throw new AppException(ErrorCode.OTP_MAX_ATTEMPTS_EXCEEDED);
            }
            throw new AppException(ErrorCode.OTP_INVALID_OR_EXPIRED);
        }

        return otp;
    }

    private static String hashOtp(String email, OtpPurpose purpose, String otpCode) {
        return TokenHashUtils.sha256Hex(email + ":" + purpose.name() + ":" + otpCode);
    }

    private boolean allowSend(String email, String remoteAddress) {
        long now = System.currentTimeMillis();
        if (sendWindows.size() > 10_000) {
            sendWindows.entrySet().removeIf(entry -> now - entry.getValue().startedAt >= 3_600_000L);
        }
        String ip = remoteAddress == null ? "unknown" : remoteAddress;
        if (!takeSendSlot("ip:" + ip, MAX_SENDS_PER_IP_PER_HOUR, now)) {
            throw new AppException(ErrorCode.OTP_SEND_RATE_LIMITED);
        }
        return takeSendSlot("email:" + email, MAX_SENDS_PER_EMAIL_PER_HOUR, now);
    }

    private boolean takeSendSlot(String key, int limit, long now) {
        SendWindow window = sendWindows.compute(key, (ignored, old) ->
                old == null || now - old.startedAt >= 3_600_000L ? new SendWindow(now) : old);
        synchronized (window) {
            if (window.count >= limit) return false;
            window.count++;
            return true;
        }
    }

    private static final class SendWindow {
        final long startedAt;
        int count;
        SendWindow(long startedAt) { this.startedAt = startedAt; }
    }

    private static String normalizeEmail(String email) {
        if (!StringUtils.hasText(email)) {
            throw new AppException(ErrorCode.EMAIL_REQUIRED);
        }
        return email.trim().toLowerCase(Locale.ROOT);
    }

    private static String normalizeOtp(String otp) {
        if (!StringUtils.hasText(otp)) {
            throw new AppException(ErrorCode.OTP_REQUIRED);
        }
        return otp.trim();
    }
}

