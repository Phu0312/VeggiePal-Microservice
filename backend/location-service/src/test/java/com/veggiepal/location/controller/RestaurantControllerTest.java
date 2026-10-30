package com.veggiepal.location.controller;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.anyDouble;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.List;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import com.veggiepal.location.dto.response.RestaurantResponse;
import com.veggiepal.location.exception.AppException;
import com.veggiepal.location.exception.ErrorCode;
import com.veggiepal.location.service.RestaurantService;

@WebMvcTest(RestaurantController.class)
class RestaurantControllerTest {

    @Autowired
    MockMvc mockMvc;

    @MockitoBean
    RestaurantService restaurantService;

    @Test
    void nearby_withoutToken_defaultsTo5KmAndAllRestaurants() throws Exception {
        when(restaurantService.findNearby(10.7725, 106.698, 5.0, false, null)).thenReturn(List.of(
                RestaurantResponse.builder()
                        .id(2L)
                        .name("Shamballa Vegetarian Restaurant")
                        .latitude(10.7768)
                        .longitude(106.7001)
                        .veganOnly(true)
                        .imageUrl("https://res.cloudinary.com/demo/image/upload/veggiepal/restaurants/restaurant-3")
                        .distanceKm(0.53)
                        .build()));

        mockMvc.perform(get("/restaurants/nearby").param("lat", "10.7725").param("lng", "106.698"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(1000))
                .andExpect(jsonPath("$.result[0].id").value(2))
                .andExpect(jsonPath("$.result[0].name").value("Shamballa Vegetarian Restaurant"))
                .andExpect(jsonPath("$.result[0].veganOnly").value(true))
                .andExpect(jsonPath("$.result[0].imageUrl")
                        .value("https://res.cloudinary.com/demo/image/upload/veggiepal/restaurants/restaurant-3"))
                .andExpect(jsonPath("$.result[0].distanceKm").value(0.53));
    }

    @Test
    void nearby_passesRadiusVeganOnlyAndKeywordThrough() throws Exception {
        when(restaurantService.findNearby(10.7725, 106.698, 2.5, true, "Shamballa")).thenReturn(List.of());

        mockMvc.perform(get("/restaurants/nearby")
                        .param("lat", "10.7725")
                        .param("lng", "106.698")
                        .param("radiusKm", "2.5")
                        .param("veganOnly", "true")
                        .param("keyword", "Shamballa"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result").isEmpty());

        verify(restaurantService).findNearby(10.7725, 106.698, 2.5, true, "Shamballa");
    }

    @Test
    void search_byKeywordWithoutCoordinates_returnsMatchingRestaurants() throws Exception {
        when(restaurantService.search("Hum", true, null, null)).thenReturn(List.of(
                RestaurantResponse.builder()
                        .id(5L)
                        .name("Hum Vegetarian")
                        .veganOnly(true)
                        .build()));

        mockMvc.perform(get("/restaurants")
                        .param("keyword", "Hum")
                        .param("veganOnly", "true"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(1000))
                .andExpect(jsonPath("$.result[0].id").value(5))
                .andExpect(jsonPath("$.result[0].name").value("Hum Vegetarian"));

        verify(restaurantService).search("Hum", true, null, null);
    }

    @Test
    void search_aliasEndpointWithCoordinates_passesLatAndLng() throws Exception {
        when(restaurantService.search("Chay", false, 10.7725, 106.698)).thenReturn(List.of());

        mockMvc.perform(get("/restaurants/search")
                        .param("keyword", "Chay")
                        .param("lat", "10.7725")
                        .param("lng", "106.698"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result").isEmpty());

        verify(restaurantService).search("Chay", false, 10.7725, 106.698);
    }

    @Test
    void nearby_withoutLat_isInvalidRequest() throws Exception {
        mockMvc.perform(get("/restaurants/nearby").param("lng", "106.698"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(1018));

        verifyNoInteractions(restaurantService);
    }

    @Test
    void nearby_withNonNumericLat_isInvalidRequest() throws Exception {
        mockMvc.perform(get("/restaurants/nearby").param("lat", "abc").param("lng", "106.698"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(1018));

        verifyNoInteractions(restaurantService);
    }

    @Test
    void nearby_serviceRejection_returnsItsErrorCode() throws Exception {
        when(restaurantService.findNearby(anyDouble(), anyDouble(), anyDouble(), anyBoolean(), any()))
                .thenThrow(new AppException(ErrorCode.INVALID_SEARCH_RADIUS));

        mockMvc.perform(get("/restaurants/nearby")
                        .param("lat", "10.7725")
                        .param("lng", "106.698")
                        .param("radiusKm", "50"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(5002))
                .andExpect(jsonPath("$.message").value("Search radius must be greater than 0 and at most 10 km"));
    }
}
