package com.veggiepal.location.service;

import java.util.List;

import org.springframework.stereotype.Service;

import com.veggiepal.location.dto.response.RestaurantResponse;
import com.veggiepal.location.entity.Restaurant;
import com.veggiepal.location.exception.AppException;
import com.veggiepal.location.exception.ErrorCode;
import com.veggiepal.location.repository.RestaurantRepository;
import com.veggiepal.location.repository.RestaurantRepository.NearbyRestaurant;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class RestaurantService {

    // Task sheet US15: the search radius is capped at 10 km.
    private static final double MAX_RADIUS_KM = 10;

    RestaurantRepository restaurantRepository;

    public List<RestaurantResponse> findNearby(double lat, double lng, double radiusKm, boolean veganOnly) {
        return findNearby(lat, lng, radiusKm, veganOnly, null);
    }

    public List<RestaurantResponse> findNearby(
            double lat, double lng, double radiusKm, boolean veganOnly, String keyword) {

        validateCoordinates(lat, lng);

        if (!(radiusKm > 0 && radiusKm <= MAX_RADIUS_KM)) {
            throw new AppException(ErrorCode.INVALID_SEARCH_RADIUS);
        }

        String normalizedKeyword = normalizeKeyword(keyword);
        List<NearbyRestaurant> rows = normalizedKeyword.isEmpty()
                ? restaurantRepository.findNearby(lat, lng, radiusKm * 1000, veganOnly)
                : restaurantRepository.findNearbyByKeyword(lat, lng, radiusKm * 1000, veganOnly, normalizedKeyword);

        return rows.stream()
                .map(RestaurantService::toResponse)
                .toList();
    }

    public List<RestaurantResponse> search(String keyword, boolean veganOnly, Double lat, Double lng) {
        String normalizedKeyword = normalizeKeyword(keyword);

        if (lat != null || lng != null) {
            if (lat == null || lng == null) {
                throw new AppException(ErrorCode.INVALID_COORDINATES);
            }
            validateCoordinates(lat, lng);
            return restaurantRepository.searchWithDistance(lat, lng, veganOnly, normalizedKeyword)
                    .stream()
                    .map(RestaurantService::toResponse)
                    .toList();
        }

        return restaurantRepository.searchByKeyword(veganOnly, normalizedKeyword)
                .stream()
                .map(RestaurantService::toResponse)
                .toList();
    }

    private static void validateCoordinates(double lat, double lng) {
        // Written as !(inside the range) so NaN, which Spring parses from "NaN", fails too.
        // Otherwise MySQL rejects it inside the query and the client gets a 500.
        if (!(lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180)) {
            throw new AppException(ErrorCode.INVALID_COORDINATES);
        }
    }

    private static String normalizeKeyword(String keyword) {
        return keyword == null ? "" : keyword.trim();
    }

    private static RestaurantResponse toResponse(NearbyRestaurant restaurant) {

        return RestaurantResponse.builder()
                .id(restaurant.getId())
                .name(restaurant.getName())
                .address(restaurant.getAddress())
                .latitude(restaurant.getLatitude())
                .longitude(restaurant.getLongitude())
                .phoneNumber(restaurant.getPhoneNumber())
                .rating(restaurant.getRating())
                .veganOnly(restaurant.getVeganOnly())
                .imageUrl(restaurant.getImageUrl())
                .distanceKm(Math.round(restaurant.getDistanceMeters() / 10) / 100.0)
                .build();
    }

    private static RestaurantResponse toResponse(Restaurant restaurant) {
        return RestaurantResponse.builder()
                .id(restaurant.getId())
                .name(restaurant.getName())
                .address(restaurant.getAddress())
                .latitude(restaurant.getLatitude())
                .longitude(restaurant.getLongitude())
                .phoneNumber(restaurant.getPhoneNumber())
                .rating(restaurant.getRating())
                .veganOnly(restaurant.getVeganOnly())
                .imageUrl(restaurant.getImageUrl())
                .distanceKm(null)
                .build();
    }
}
