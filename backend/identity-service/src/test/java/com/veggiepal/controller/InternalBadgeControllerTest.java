package com.veggiepal.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

import com.veggiepal.exception.AppException;
import com.veggiepal.exception.ErrorCode;
import com.veggiepal.service.ProfileExtrasService;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

class InternalBadgeControllerTest {
    @Test
    void awardRequiresConfiguredServiceToken() {
        ProfileExtrasService badges = mock(ProfileExtrasService.class);
        InternalBadgeController controller = new InternalBadgeController(badges);
        ReflectionTestUtils.setField(controller, "internalToken", "long-shared-service-secret");

        assertThatThrownBy(() -> controller.awardGreenHeart(7L, "wrong"))
                .isInstanceOfSatisfying(AppException.class,
                        error -> assertThat(error.getErrorCode()).isEqualTo(ErrorCode.UNAUTHENTICATED));

        controller.awardGreenHeart(7L, "long-shared-service-secret");
        verify(badges).unlockBadge(7L, "VEGGIE_GREEN_HEART");
    }
}
