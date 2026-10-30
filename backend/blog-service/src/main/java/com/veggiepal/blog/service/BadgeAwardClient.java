package com.veggiepal.blog.service;

import com.veggiepal.blog.exception.AppException;
import com.veggiepal.blog.exception.ErrorCode;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Service
public class BadgeAwardClient {
    private final RestClient client;
    private final String token;

    public BadgeAwardClient(
            @Value("${services.identity.base-url:http://localhost:8081}") String baseUrl,
            @Value("${services.internal-token:}") String token) {
        SimpleClientHttpRequestFactory requests = new SimpleClientHttpRequestFactory();
        requests.setConnectTimeout(3000);
        requests.setReadTimeout(5000);
        this.client = RestClient.builder().baseUrl(baseUrl).requestFactory(requests).build();
        this.token = token;
    }

    public void awardGreenHeart(Long userId) {
        if (token.isBlank()) throw new AppException(ErrorCode.BADGE_AWARD_UNAVAILABLE);
        try {
            client.post().uri("/internal/badges/green-heart/{userId}", userId)
                    .header("X-Internal-Service-Token", token)
                    .retrieve().toBodilessEntity();
        } catch (RestClientException exception) {
            throw new AppException(ErrorCode.BADGE_AWARD_UNAVAILABLE);
        }
    }
}
