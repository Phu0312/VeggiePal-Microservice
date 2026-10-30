package com.veggiepal.service;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Base64;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import com.veggiepal.dto.response.LoginResponse;
import com.veggiepal.entity.RefreshToken;
import com.veggiepal.entity.User;
import com.veggiepal.enums.UserStatus;
import com.veggiepal.exception.AppException;
import com.veggiepal.exception.ErrorCode;
import com.veggiepal.repository.RefreshTokenRepository;
import com.veggiepal.repository.UserRepository;

@Service
public class RefreshTokenService {

    private static final SecureRandom SECURE_RANDOM = new SecureRandom();
    private static final int TOKEN_BYTES = 32;

    private final RefreshTokenRepository refreshTokenRepository;
    private final UserRepository userRepository;
    private final JwtService jwtService;
    private final long refreshExpirationDays;

    public RefreshTokenService(
            RefreshTokenRepository refreshTokenRepository,
            UserRepository userRepository,
            JwtService jwtService,
            @Value("${jwt.refresh-expiration-days:30}") long refreshExpirationDays
    ) {
        this.refreshTokenRepository = refreshTokenRepository;
        this.userRepository = userRepository;
        this.jwtService = jwtService;
        this.refreshExpirationDays = Math.max(1L, refreshExpirationDays);
    }

    @Transactional
    public IssuedRefreshToken issue(Long userId) {
        byte[] bytes = new byte[TOKEN_BYTES];
        SECURE_RANDOM.nextBytes(bytes);
        String rawToken = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);

        LocalDateTime now = LocalDateTime.now();
        RefreshToken entity = RefreshToken.builder()
                .userId(userId)
                .tokenHash(TokenHashUtils.sha256Hex(rawToken))
                .revoked(false)
                .expiresAt(now.plusDays(refreshExpirationDays))
                .createdAt(now)
                .build();
        refreshTokenRepository.save(entity);

        return new IssuedRefreshToken(rawToken, refreshExpirationDays * 86_400L);
    }

    @Transactional(noRollbackFor = AppException.class)
    public LoginResponse refresh(String rawRefreshToken) {
        if (!StringUtils.hasText(rawRefreshToken)) {
            throw new AppException(ErrorCode.REFRESH_TOKEN_REQUIRED);
        }

        String hash = TokenHashUtils.sha256Hex(rawRefreshToken.trim());
        RefreshToken existing = refreshTokenRepository.findByTokenHash(hash)
                .orElseThrow(() -> new AppException(ErrorCode.REFRESH_TOKEN_INVALID));

        LocalDateTime now = LocalDateTime.now();
        if (Boolean.TRUE.equals(existing.getRevoked()) || !existing.getExpiresAt().isAfter(now)) {
            throw new AppException(ErrorCode.REFRESH_TOKEN_INVALID);
        }

        User user = userRepository.findById(existing.getUserId())
                .orElseThrow(() -> new AppException(ErrorCode.REFRESH_TOKEN_INVALID));

        existing.setRevoked(true);
        existing.setRevokedAt(now);
        refreshTokenRepository.save(existing);

        if (user.getStatus() != UserStatus.ACTIVE) {
            refreshTokenRepository.revokeAllActiveByUserId(user.getId(), now);
            throw new AppException(ErrorCode.USER_BLOCKED);
        }

        IssuedRefreshToken rotated = issue(user.getId());
        return LoginResponse.builder()
                .accessToken(jwtService.generateToken(user))
                .refreshToken(rotated.rawToken())
                .refreshExpiresIn(rotated.expiresInSeconds())
                .userId(user.getId())
                .email(user.getEmail())
                .emailVerified(user.getEmailVerified())
                .fullName(user.getFullName())
                .role(user.getRole())
                .build();
    }

    @Transactional
    public void revoke(String rawRefreshToken) {
        if (!StringUtils.hasText(rawRefreshToken)) {
            throw new AppException(ErrorCode.REFRESH_TOKEN_REQUIRED);
        }
        String hash = TokenHashUtils.sha256Hex(rawRefreshToken.trim());
        refreshTokenRepository.findByTokenHash(hash).ifPresent(token -> {
            if (!Boolean.TRUE.equals(token.getRevoked())) {
                token.setRevoked(true);
                token.setRevokedAt(LocalDateTime.now());
                refreshTokenRepository.save(token);
            }
        });
    }

    @Transactional
    public int revokeAllForUser(Long userId) {
        return refreshTokenRepository.revokeAllActiveByUserId(userId, LocalDateTime.now());
    }

    public record IssuedRefreshToken(String rawToken, long expiresInSeconds) {
    }
}

