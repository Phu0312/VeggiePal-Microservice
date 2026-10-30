package com.veggiepal.service;

import java.util.UUID;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import com.veggiepal.dto.request.LoginRequest;
import com.veggiepal.dto.request.RegisterRequest;
import com.veggiepal.dto.response.LoginResponse;
import com.veggiepal.dto.response.RegisterResponse;
import com.veggiepal.entity.User;
import com.veggiepal.enums.Role;
import com.veggiepal.enums.UserStatus;
import com.veggiepal.exception.AppException;
import com.veggiepal.exception.ErrorCode;
import com.veggiepal.mapper.UserMapper;
import com.veggiepal.repository.UserRepository;

import lombok.AccessLevel;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;

@Service
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Slf4j
public class UserService {

    UserRepository userRepository;
    UserMapper userMapper;
    PasswordEncoder passwordEncoder;
    JwtService jwtService;
    GoogleTokenVerifier googleTokenVerifier;
    RefreshTokenService refreshTokenService;
    OtpService otpService;

    public UserService(
            UserRepository userRepository,
            UserMapper userMapper,
            PasswordEncoder passwordEncoder,
            JwtService jwtService,
            GoogleTokenVerifier googleTokenVerifier
    ) {
        this(userRepository, userMapper, passwordEncoder, jwtService, googleTokenVerifier, null, null);
    }

    @Autowired
    public UserService(
            UserRepository userRepository,
            UserMapper userMapper,
            PasswordEncoder passwordEncoder,
            JwtService jwtService,
            GoogleTokenVerifier googleTokenVerifier,
            RefreshTokenService refreshTokenService,
            OtpService otpService
    ) {
        this.userRepository = userRepository;
        this.userMapper = userMapper;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.googleTokenVerifier = googleTokenVerifier;
        this.refreshTokenService = refreshTokenService;
        this.otpService = otpService;
    }

    public RegisterResponse createUser(RegisterRequest request) {

        String email = request.getEmail().trim().toLowerCase();

        if (userRepository.existsByEmail(email)) {
            throw new AppException(ErrorCode.EMAIL_EXISTED);
        }

        User user = userMapper.toUser(request);

        user.setEmail(email);
        user.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        user.setRole(Role.USER);
        user.setStatus(UserStatus.ACTIVE);
        user.setEmailVerified(false);

        userRepository.save(user);
        if (otpService != null) {
            otpService.sendVerificationOtpSafely(user);
        }
        return userMapper.toUserResponse(user);
    }

    public LoginResponse login(LoginRequest request) {

        String email =
                request.getEmail()
                        .trim()
                        .toLowerCase();

        User user = userRepository
                .findByEmail(email)
                .orElseThrow(
                        () -> new AppException(
                                ErrorCode.UNAUTHENTICATED
                        )
                );

        boolean passwordMatched =
                passwordEncoder.matches(
                        request.getPassword(),
                        user.getPasswordHash()
                );

        if (!passwordMatched) {
            throw new AppException(
                    ErrorCode.UNAUTHENTICATED
            );
        }

        return toLoginResponse(user);
    }

    public LoginResponse loginWithGoogle(String idToken) {

        Jwt google = googleTokenVerifier.verify(idToken);
        String email = google.getClaimAsString("email");

        if (!Boolean.TRUE.equals(google.getClaimAsBoolean("email_verified")) || !StringUtils.hasText(email)) {
            throw new AppException(ErrorCode.GOOGLE_TOKEN_INVALID);
        }

        String normalizedEmail = email.trim().toLowerCase();

        User user = userRepository.findByEmail(normalizedEmail)
                .map(this::linkGoogleAccount)
                .orElseGet(() -> createGoogleUser(normalizedEmail, google));

        return toLoginResponse(user);
    }

    // Google proved who owns this email, so a password set by whoever registered it first must stop working.
    private User linkGoogleAccount(User user) {

        if (Boolean.TRUE.equals(user.getEmailVerified())) {
            return user;
        }

        user.setPasswordHash(randomPasswordHash());
        user.setEmailVerified(true);
        if (user.getStatus() == UserStatus.PENDING) {
            user.setStatus(UserStatus.ACTIVE);
        }
        userRepository.save(user);
        return user;
    }

    private User createGoogleUser(String email, Jwt google) {

        String name = google.getClaimAsString("name");

        return userRepository.save(User.builder()
                .email(email)
                .fullName(StringUtils.hasText(name) ? name.trim() : email.substring(0, email.indexOf('@')))
                .avatarUrl(google.getClaimAsString("picture"))
                .passwordHash(randomPasswordHash())
                .role(Role.USER)
                .status(UserStatus.ACTIVE)
                .emailVerified(true)
                .build());
    }

    private String randomPasswordHash() {
        return passwordEncoder.encode(UUID.randomUUID().toString());
    }

    private LoginResponse toLoginResponse(User user) {
        if (user.getStatus() != UserStatus.ACTIVE) {
            throw new AppException(ErrorCode.USER_BLOCKED);
        }

        RefreshTokenService.IssuedRefreshToken refresh =
                refreshTokenService != null && user.getId() != null
                        ? refreshTokenService.issue(user.getId())
                        : null;

        return LoginResponse.builder()
                .accessToken(jwtService.generateToken(user))
                .refreshToken(refresh != null ? refresh.rawToken() : null)
                .refreshExpiresIn(refresh != null ? refresh.expiresInSeconds() : null)
                .userId(user.getId())
                .email(user.getEmail())
                .emailVerified(user.getEmailVerified())
                .fullName(user.getFullName())
                .role(user.getRole())
                .build();
    }
}
