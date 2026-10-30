package com.veggiepal.blog.controller;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.when;

import com.veggiepal.blog.dto.response.ChallengeProgressResponse;
import com.veggiepal.blog.service.BadgeAwardClient;
import com.veggiepal.blog.service.CommunityService;
import org.junit.jupiter.api.Test;
import org.springframework.security.oauth2.jwt.Jwt;

class CommunityControllerTest {
    private final CommunityService community = mock(CommunityService.class);
    private final BadgeAwardClient badges = mock(BadgeAwardClient.class);
    private final CommunityController controller = new CommunityController(community, badges);
    private final Jwt jwt = Jwt.withTokenValue("test-token").header("alg", "HS256").claim("userId", 7L).build();

    @Test
    void completedChallengeAwardsGreenHeart() {
        when(community.checkInChallenge(7L)).thenReturn(ChallengeProgressResponse.builder().completed(true).build());
        controller.checkInChallenge(jwt);
        verify(badges).awardGreenHeart(7L);
    }

    @Test
    void incompleteChallengeDoesNotAwardBadge() {
        when(community.checkInChallenge(7L)).thenReturn(ChallengeProgressResponse.builder().completed(false).build());
        controller.checkInChallenge(jwt);
        verify(badges, never()).awardGreenHeart(7L);
    }
}
