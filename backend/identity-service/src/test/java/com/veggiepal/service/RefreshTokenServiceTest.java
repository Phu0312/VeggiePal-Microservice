package com.veggiepal.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.time.LocalDateTime;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import com.veggiepal.dto.response.LoginResponse;
import com.veggiepal.entity.RefreshToken;
import com.veggiepal.entity.User;
import com.veggiepal.enums.Role;
import com.veggiepal.enums.UserStatus;
import com.veggiepal.exception.AppException;
import com.veggiepal.exception.ErrorCode;
import com.veggiepal.repository.RefreshTokenRepository;
import com.veggiepal.repository.UserRepository;

class RefreshTokenServiceTest {

    private RefreshTokenRepository refreshTokenRepository;
    private UserRepository userRepository;
    private JwtService jwtService;
    private RefreshTokenService service;

    @BeforeEach
    void setUp() {
        refreshTokenRepository = mock(RefreshTokenRepository.class);
        userRepository = mock(UserRepository.class);
        jwtService = mock(JwtService.class);
        service = new RefreshTokenService(refreshTokenRepository, userRepository, jwtService, 30L);
    }

    @Test
    void issueAndRotateRefreshToken() {
        RefreshTokenService.IssuedRefreshToken issued = service.issue(7L);
        assertThat(issued.rawToken()).isNotBlank();

        ArgumentCaptor<RefreshToken> tokenCaptor = ArgumentCaptor.forClass(RefreshToken.class);
        verify(refreshTokenRepository).save(tokenCaptor.capture());
        RefreshToken stored = tokenCaptor.getValue();

        User active = User.builder()
                .id(7L)
                .email("an@gmail.com")
                .fullName("An")
                .role(Role.USER)
                .status(UserStatus.ACTIVE)
                .build();
        when(refreshTokenRepository.findByTokenHash(stored.getTokenHash())).thenReturn(Optional.of(stored));
        when(userRepository.findById(7L)).thenReturn(Optional.of(active));
        when(jwtService.generateToken(active)).thenReturn("new-access-jwt");

        LoginResponse rotated = service.refresh(issued.rawToken());

        assertThat(stored.getRevoked()).isTrue();
        assertThat(rotated.getAccessToken()).isEqualTo("new-access-jwt");
        assertThat(rotated.getRefreshToken()).isNotBlank().isNotEqualTo(issued.rawToken());
    }

    @Test
    void refresh_blockedUser_revokesTokensAndThrowsUserBlocked() {
        RefreshToken stored = RefreshToken.builder()
                .id(1L)
                .userId(7L)
                .tokenHash(TokenHashUtils.sha256Hex("raw-token"))
                .revoked(false)
                .expiresAt(LocalDateTime.now().plusDays(10))
                .build();
        User blocked = User.builder().id(7L).status(UserStatus.BLOCKED).build();

        when(refreshTokenRepository.findByTokenHash(stored.getTokenHash())).thenReturn(Optional.of(stored));
        when(userRepository.findById(7L)).thenReturn(Optional.of(blocked));

        assertThatThrownBy(() -> service.refresh("raw-token"))
                .isInstanceOfSatisfying(AppException.class,
                        e -> assertThat(e.getErrorCode()).isEqualTo(ErrorCode.USER_BLOCKED));
        assertThat(stored.getRevoked()).isTrue();
        verify(refreshTokenRepository).revokeAllActiveByUserId(any(), any());
    }

    @Test
    void revoke_marksTokenRevoked() {
        RefreshToken stored = RefreshToken.builder()
                .id(1L)
                .userId(7L)
                .tokenHash(TokenHashUtils.sha256Hex("raw-token"))
                .revoked(false)
                .expiresAt(LocalDateTime.now().plusDays(10))
                .build();
        when(refreshTokenRepository.findByTokenHash(stored.getTokenHash())).thenReturn(Optional.of(stored));

        service.revoke("raw-token");

        assertThat(stored.getRevoked()).isTrue();
        assertThat(stored.getRevokedAt()).isNotNull();
    }
}

