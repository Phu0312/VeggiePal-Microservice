package com.veggiepal.restaurant.service;

import java.util.*;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import com.veggiepal.restaurant.entity.Restaurant;
import com.veggiepal.restaurant.exception.AppException;
import com.veggiepal.restaurant.exception.ErrorCode;
import com.veggiepal.restaurant.repository.RestaurantRepository;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class RestaurantService {

    private static final double EARTH_RADIUS_KM = 6371.0;

    RestaurantRepository restaurantRepository;

    public List<Map<String, Object>> findNearby(double lat, double lng, double radiusKm, String food) {
        List<Restaurant> all = restaurantRepository.findAll();

        return all.stream()
                .map(r -> {
                    double distance = haversine(lat, lng, r.getLatitude(), r.getLongitude());
                    Map<String, Object> result = new LinkedHashMap<>();
                    result.put("id", r.getId());
                    result.put("name", r.getName());
                    result.put("address", r.getAddress());
                    result.put("latitude", r.getLatitude());
                    result.put("longitude", r.getLongitude());
                    result.put("description", r.getDescription());
                    result.put("type", r.getType());
                    result.put("supportedDishes", r.getSupportedDishes());
                    result.put("distanceKm", Math.round(distance * 10.0) / 10.0);
                    return result;
                })
                .filter(r -> (double) r.get("distanceKm") <= radiusKm)
                .sorted((a, b) -> {
                    if (food != null && !food.isBlank()) {
                        String fl = food.toLowerCase();
                        boolean aMatch = dishMatch(a, fl);
                        boolean bMatch = dishMatch(b, fl);
                        if (aMatch != bMatch) return aMatch ? -1 : 1;
                    }
                    return Double.compare((double) a.get("distanceKm"), (double) b.get("distanceKm"));
                })
                .collect(Collectors.toList());
    }

    public Restaurant getRestaurant(Long id) {
        return restaurantRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.RESTAURANT_NOT_FOUND));
    }

    private boolean dishMatch(Map<String, Object> restaurant, String foodLower) {
        String dishes = (String) restaurant.get("supportedDishes");
        String name = (String) restaurant.get("name");
        String desc = (String) restaurant.get("description");

        return (dishes != null && dishes.toLowerCase().contains(foodLower))
                || (name != null && name.toLowerCase().contains(foodLower))
                || (desc != null && desc.toLowerCase().contains(foodLower));
    }

    private double haversine(double lat1, double lon1, double lat2, double lon2) {
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);

        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLon / 2) * Math.sin(dLon / 2);

        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return EARTH_RADIUS_KM * c;
    }
}
