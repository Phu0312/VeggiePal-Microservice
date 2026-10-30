package com.veggiepal.location.controller;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.veggiepal.location.dto.response.ApiResponse;
import com.veggiepal.location.dto.response.RestaurantResponse;
import com.veggiepal.location.service.RestaurantService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@RestController
@RequestMapping("/restaurants")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Tag(name = "Restaurant", description = "Vegetarian and vegan restaurants on the map")
public class RestaurantController {

    RestaurantService restaurantService;

    @Operation(summary = "Search restaurants by name or address across all locations; optional lat/lng computes distanceKm")
    @GetMapping({"", "/search"})
    ApiResponse<List<RestaurantResponse>> search(
            @RequestParam(name = "keyword", required = false) String keyword,
            @RequestParam(name = "veganOnly", defaultValue = "false") boolean veganOnly,
            @RequestParam(name = "lat", required = false) Double lat,
            @RequestParam(name = "lng", required = false) Double lng
    ) {

        return ApiResponse
                .<List<RestaurantResponse>>builder()
                .result(restaurantService.search(keyword, veganOnly, lat, lng))
                .build();
    }

    @Operation(summary = "Restaurants within radiusKm (max 10) of a point, optionally filtered by keyword, nearest first")
    @GetMapping("/nearby")
    ApiResponse<List<RestaurantResponse>> findNearby(
            @RequestParam("lat") double lat,
            @RequestParam("lng") double lng,
            @RequestParam(name = "radiusKm", defaultValue = "5") double radiusKm,
            @RequestParam(name = "veganOnly", defaultValue = "false") boolean veganOnly,
            @RequestParam(name = "keyword", required = false) String keyword
    ) {

        return ApiResponse
                .<List<RestaurantResponse>>builder()
                .result(restaurantService.findNearby(lat, lng, radiusKm, veganOnly, keyword))
                .build();
    }
}
