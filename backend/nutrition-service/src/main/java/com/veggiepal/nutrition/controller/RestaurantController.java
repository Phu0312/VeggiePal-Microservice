package com.veggiepal.nutrition.controller;

import java.util.List;
import java.util.Map;

import org.springframework.web.bind.annotation.*;

import com.veggiepal.nutrition.dto.response.ApiResponse;
import com.veggiepal.nutrition.entity.Restaurant;
import com.veggiepal.nutrition.service.RestaurantService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@RestController
@RequestMapping("/restaurants")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Tag(name = "Restaurants", description = "Find nearby vegan/vegetarian restaurants (DEMO DATA)")
public class RestaurantController {

    RestaurantService restaurantService;

    @Operation(summary = "Find nearby restaurants using Haversine distance")
    @GetMapping("/nearby")
    ApiResponse<List<Map<String, Object>>> findNearby(
            @RequestParam("lat") double lat,
            @RequestParam("lng") double lng,
            @RequestParam(value = "radiusKm", defaultValue = "10") double radiusKm,
            @RequestParam(value = "food", required = false) String food
    ) {
        return ApiResponse.<List<Map<String, Object>>>builder()
                .result(restaurantService.findNearby(lat, lng, radiusKm, food))
                .build();
    }

    @Operation(summary = "Get restaurant detail")
    @GetMapping("/{id}")
    ApiResponse<Restaurant> getRestaurant(@PathVariable("id") Long id) {
        return ApiResponse.<Restaurant>builder()
                .result(restaurantService.getRestaurant(id))
                .build();
    }
}
