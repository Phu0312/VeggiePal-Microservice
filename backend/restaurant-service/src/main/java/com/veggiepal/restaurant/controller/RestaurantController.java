package com.veggiepal.restaurant.controller;

import java.util.List;
import java.util.Map;

import org.springframework.web.bind.annotation.*;

import com.veggiepal.restaurant.dto.response.ApiResponse;
import com.veggiepal.restaurant.entity.Restaurant;
import com.veggiepal.restaurant.service.RestaurantService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@RestController
@RequestMapping("/restaurants")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Tag(name = "Restaurant", description = "Vegan restaurant discovery and nearby search using Haversine formula")
public class RestaurantController {

    RestaurantService restaurantService;

    @Operation(summary = "Find nearby vegan restaurants within radiusKm of GPS coordinates")
    @GetMapping("/nearby")
    public ApiResponse<List<Map<String, Object>>> getNearby(
            @RequestParam double lat,
            @RequestParam double lng,
            @RequestParam(defaultValue = "10.0") double radiusKm,
            @RequestParam(required = false) String food
    ) {
        return ApiResponse.<List<Map<String, Object>>>builder()
                .result(restaurantService.findNearby(lat, lng, radiusKm, food))
                .build();
    }

    @Operation(summary = "Get restaurant detail by ID")
    @GetMapping("/{id}")
    public ApiResponse<Restaurant> getRestaurant(@PathVariable Long id) {
        return ApiResponse.<Restaurant>builder()
                .result(restaurantService.getRestaurant(id))
                .build();
    }
}
