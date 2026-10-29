package com.veggiepal.service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.veggiepal.dto.request.FavoriteRequest;
import com.veggiepal.dto.response.BadgeItemResponse;
import com.veggiepal.dto.response.FavoriteItemResponse;
import com.veggiepal.dto.response.UserBadgesResponse;
import com.veggiepal.entity.User;
import com.veggiepal.entity.UserBadge;
import com.veggiepal.entity.UserFavorite;
import com.veggiepal.enums.BadgeCode;
import com.veggiepal.enums.FavoriteTargetType;
import com.veggiepal.exception.AppException;
import com.veggiepal.exception.ErrorCode;
import com.veggiepal.repository.UserBadgeRepository;
import com.veggiepal.repository.UserFavoriteRepository;
import com.veggiepal.repository.UserRepository;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class ProfileExtrasService {

    UserRepository userRepository;
    UserFavoriteRepository userFavoriteRepository;
    UserBadgeRepository userBadgeRepository;

    @Transactional(readOnly = true)
    public List<FavoriteItemResponse> getFavorites(Long userId, FavoriteTargetType targetType) {
        List<UserFavorite> items = targetType == null
                ? userFavoriteRepository.findByUserIdOrderByCreatedAtDesc(userId)
                : userFavoriteRepository.findByUserIdAndTargetTypeOrderByCreatedAtDesc(userId, targetType);

        return items.stream().map(this::toFavoriteResponse).toList();
    }

    @Transactional
    public FavoriteItemResponse saveFavorite(Long userId, FavoriteRequest request) {
        UserFavorite favorite = userFavoriteRepository
                .findByUserIdAndTargetTypeAndTargetId(userId, request.getTargetType(), request.getTargetId())
                .orElseGet(() -> UserFavorite.builder()
                        .userId(userId)
                        .targetType(request.getTargetType())
                        .targetId(request.getTargetId())
                        .build());

        if (request.getTitle() != null) {
            favorite.setTitle(trimToNull(request.getTitle()));
        }
        if (request.getImageUrl() != null) {
            favorite.setImageUrl(trimToNull(request.getImageUrl()));
        }

        return toFavoriteResponse(userFavoriteRepository.save(favorite));
    }

    @Transactional
    public void removeFavorite(Long userId, FavoriteTargetType targetType, Long targetId) {
        userFavoriteRepository
                .findByUserIdAndTargetTypeAndTargetId(userId, targetType, targetId)
                .ifPresent(userFavoriteRepository::delete);
    }

    @Transactional(readOnly = true)
    public UserBadgesResponse getBadges(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_EXISTED));

        Map<BadgeCode, LocalDateTime> earnedMap = new EnumMap<>(BadgeCode.class);
        LocalDateTime createdOrNow = user.getCreatedAt() != null ? user.getCreatedAt() : LocalDateTime.now();
        for (UserBadge row : userBadgeRepository.findByUserId(userId)) {
            earnedMap.put(row.getBadgeCode(), row.getEarnedAt() != null ? row.getEarnedAt() : createdOrNow);
        }

        earnedMap.putIfAbsent(BadgeCode.GREEN_STARTER, createdOrNow);

        if (Boolean.TRUE.equals(user.getEmailVerified())) {
            earnedMap.putIfAbsent(
                    BadgeCode.VERIFIED_MEMBER,
                    user.getUpdatedAt() != null ? user.getUpdatedAt() : createdOrNow
            );
        }

        if (isProfileComplete(user)) {
            earnedMap.putIfAbsent(
                    BadgeCode.COMPLETE_PROFILE,
                    user.getUpdatedAt() != null ? user.getUpdatedAt() : createdOrNow
            );
        }

        List<BadgeItemResponse> list = new ArrayList<>();
        int earnedCount = 0;
        for (BadgeCode badge : BadgeCode.values()) {
            LocalDateTime earnedAt = earnedMap.get(badge);
            boolean earned = earnedAt != null;
            if (earned) {
                earnedCount++;
            }
            list.add(BadgeItemResponse.builder()
                    .code(badge)
                    .title(badge.getTitle())
                    .description(badge.getDescription())
                    .icon(badge.getIcon())
                    .earned(earned)
                    .earnedAt(earnedAt)
                    .build());
        }

        return UserBadgesResponse.builder()
                .earnedCount(earnedCount)
                .totalCount(BadgeCode.values().length)
                .badges(list)
                .build();
    }

    @Transactional
    public BadgeItemResponse unlockBadge(Long userId, String rawCode) {
        if (!userRepository.existsById(userId)) {
            throw new AppException(ErrorCode.USER_NOT_EXISTED);
        }
        BadgeCode code;
        try {
            code = BadgeCode.valueOf(rawCode.trim().toUpperCase());
        } catch (IllegalArgumentException | NullPointerException ex) {
            throw new AppException(ErrorCode.BADGE_NOT_EXISTED);
        }

        UserBadge saved = userBadgeRepository.findByUserIdAndBadgeCode(userId, code)
                .orElseGet(() -> userBadgeRepository.save(UserBadge.builder()
                        .userId(userId)
                        .badgeCode(code)
                        .earnedAt(LocalDateTime.now())
                        .build()));

        return BadgeItemResponse.builder()
                .code(code)
                .title(code.getTitle())
                .description(code.getDescription())
                .icon(code.getIcon())
                .earned(true)
                .earnedAt(saved.getEarnedAt())
                .build();
    }

    private static boolean isProfileComplete(User user) {
        return user.getFullName() != null && !user.getFullName().isBlank()
                && user.getDateOfBirth() != null
                && user.getGender() != null
                && user.getActivityLevel() != null;
    }

    private FavoriteItemResponse toFavoriteResponse(UserFavorite favorite) {
        return FavoriteItemResponse.builder()
                .id(favorite.getId())
                .targetType(favorite.getTargetType())
                .targetId(favorite.getTargetId())
                .title(favorite.getTitle())
                .imageUrl(favorite.getImageUrl())
                .createdAt(favorite.getCreatedAt())
                .build();
    }

    private static String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
