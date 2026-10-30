package com.veggiepal.controller;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.List;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.RequestPostProcessor;

import com.veggiepal.configuration.JwtConfig;
import com.veggiepal.configuration.SecurityConfig;
import com.veggiepal.configuration.SecurityExceptionHandler;
import com.veggiepal.dto.request.FavoriteRequest;
import com.veggiepal.dto.response.BadgeItemResponse;
import com.veggiepal.dto.response.FavoriteItemResponse;
import com.veggiepal.dto.response.UserBadgesResponse;
import com.veggiepal.enums.BadgeCode;
import com.veggiepal.enums.FavoriteTargetType;
import com.veggiepal.exception.GlobalExceptionHandler;
import com.veggiepal.service.ProfileExtrasService;

@WebMvcTest(ProfileExtrasController.class)
@Import({SecurityConfig.class, JwtConfig.class, SecurityExceptionHandler.class, GlobalExceptionHandler.class})
class ProfileExtrasControllerTest {

    @Autowired
    MockMvc mockMvc;

    @MockitoBean
    ProfileExtrasService profileExtrasService;

    static RequestPostProcessor currentUser() {
        return jwt().jwt(token -> token.claim("userId", 7L).claim("role", "USER"));
    }

    @Test
    void favoritesAndBadgesEndpointsWorkForAuthenticatedUser() throws Exception {
        when(profileExtrasService.saveFavorite(eq(7L), any(FavoriteRequest.class)))
                .thenReturn(FavoriteItemResponse.builder()
                        .id(1L)
                        .targetType(FavoriteTargetType.RECIPE)
                        .targetId(10L)
                        .title("Súp bí đỏ")
                        .build());

        when(profileExtrasService.getFavorites(7L, FavoriteTargetType.RECIPE))
                .thenReturn(List.of(FavoriteItemResponse.builder()
                        .id(1L)
                        .targetType(FavoriteTargetType.RECIPE)
                        .targetId(10L)
                        .title("Súp bí đỏ")
                        .build()));

        when(profileExtrasService.getBadges(7L))
                .thenReturn(UserBadgesResponse.builder()
                        .earnedCount(3)
                        .totalCount(6)
                        .badges(List.of(BadgeItemResponse.builder()
                                .code(BadgeCode.VEGGIE_GREEN_HEART)
                                .title(BadgeCode.VEGGIE_GREEN_HEART.getTitle())
                                .earned(true)
                                .build()))
                        .build());

        when(profileExtrasService.unlockBadge(7L, "VEGGIE_GREEN_HEART"))
                .thenReturn(BadgeItemResponse.builder()
                        .code(BadgeCode.VEGGIE_GREEN_HEART)
                        .earned(true)
                        .build());

        mockMvc.perform(post("/users/me/favorites")
                        .with(currentUser())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"targetType\":\"RECIPE\",\"targetId\":10,\"title\":\"Súp bí đỏ\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.title").value("Súp bí đỏ"));

        mockMvc.perform(get("/users/me/favorites").param("type", "RECIPE").with(currentUser()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result[0].targetId").value(10));

        mockMvc.perform(delete("/users/me/favorites/RECIPE/10").with(currentUser()))
                .andExpect(status().isOk());
        verify(profileExtrasService).removeFavorite(7L, FavoriteTargetType.RECIPE, 10L);

        mockMvc.perform(get("/users/me/badges").with(currentUser()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.earnedCount").value(3));

        mockMvc.perform(post("/users/me/badges/VEGGIE_GREEN_HEART").with(currentUser()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.code").value("VEGGIE_GREEN_HEART"));
    }
}

