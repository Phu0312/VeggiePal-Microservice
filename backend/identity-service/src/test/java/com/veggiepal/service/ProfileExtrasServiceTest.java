package com.veggiepal.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.veggiepal.dto.request.FavoriteRequest;
import com.veggiepal.dto.response.BadgeItemResponse;
import com.veggiepal.dto.response.FavoriteItemResponse;
import com.veggiepal.dto.response.UserBadgesResponse;
import com.veggiepal.entity.User;
import com.veggiepal.entity.UserBadge;
import com.veggiepal.entity.UserFavorite;
import com.veggiepal.enums.ActivityLevel;
import com.veggiepal.enums.BadgeCode;
import com.veggiepal.enums.FavoriteTargetType;
import com.veggiepal.enums.Gender;
import com.veggiepal.exception.AppException;
import com.veggiepal.exception.ErrorCode;
import com.veggiepal.repository.UserBadgeRepository;
import com.veggiepal.repository.UserFavoriteRepository;
import com.veggiepal.repository.UserRepository;

@ExtendWith(MockitoExtension.class)
class ProfileExtrasServiceTest {

    @Mock
    UserRepository userRepository;

    @Mock
    UserFavoriteRepository userFavoriteRepository;

    @Mock
    UserBadgeRepository userBadgeRepository;

    @InjectMocks
    ProfileExtrasService profileExtrasService;

    @Test
    void saveAndListFavorites_isIdempotentPerTarget() {
        when(userFavoriteRepository.findByUserIdAndTargetTypeAndTargetId(7L, FavoriteTargetType.RECIPE, 12L))
                .thenReturn(Optional.empty());
        when(userFavoriteRepository.save(any(UserFavorite.class))).thenAnswer(inv -> {
            UserFavorite f = inv.getArgument(0);
            f.setId(5L);
            return f;
        });

        FavoriteItemResponse saved = profileExtrasService.saveFavorite(7L, FavoriteRequest.builder()
                .targetType(FavoriteTargetType.RECIPE)
                .targetId(12L)
                .title(" Súp bí đỏ ")
                .imageUrl("https://example.com/soup.jpg")
                .build());

        assertThat(saved.getId()).isEqualTo(5L);
        assertThat(saved.getTitle()).isEqualTo("Súp bí đỏ");
    }

    @Test
    void getBadges_autoEvaluatesProfileAndVerificationAndUnlocksBadges() {
        User user = new User();
        user.setId(7L);
        user.setFullName("Veggie User");
        user.setEmailVerified(true);
        user.setDateOfBirth(LocalDate.of(2002, 5, 10));
        user.setGender(Gender.FEMALE);
        user.setActivityLevel(ActivityLevel.MODERATE);

        when(userRepository.findById(7L)).thenReturn(Optional.of(user));
        when(userBadgeRepository.findByUserId(7L)).thenReturn(List.of(
                UserBadge.builder().userId(7L).badgeCode(BadgeCode.VEGGIE_GREEN_HEART).build()
        ));

        UserBadgesResponse badges = profileExtrasService.getBadges(7L);
        assertThat(badges.getEarnedCount()).isEqualTo(4);
        assertThat(badges.getTotalCount()).isEqualTo(BadgeCode.values().length);

        when(userRepository.existsById(7L)).thenReturn(true);
        assertThatThrownBy(() -> profileExtrasService.unlockBadge(7L, "UNKNOWN_BADGE"))
                .isInstanceOf(AppException.class)
                .extracting("errorCode")
                .isEqualTo(ErrorCode.BADGE_NOT_EXISTED);

        when(userBadgeRepository.findByUserIdAndBadgeCode(7L, BadgeCode.AI_MASTER_CHEF))
                .thenReturn(Optional.empty());
        when(userBadgeRepository.save(any(UserBadge.class))).thenAnswer(inv -> inv.getArgument(0));

        BadgeItemResponse unlocked = profileExtrasService.unlockBadge(7L, "ai_master_chef");
        assertThat(unlocked.getCode()).isEqualTo(BadgeCode.AI_MASTER_CHEF);
        assertThat(unlocked.isEarned()).isTrue();
    }
}
