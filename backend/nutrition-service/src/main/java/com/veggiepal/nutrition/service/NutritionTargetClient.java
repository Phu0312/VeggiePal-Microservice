package com.veggiepal.nutrition.service;

import com.veggiepal.nutrition.exception.AppException;
import com.veggiepal.nutrition.exception.ErrorCode;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestClientResponseException;

@Service
public class NutritionTargetClient {
    private final RestClient client;

    public NutritionTargetClient(@Value("${services.ai.base-url:http://localhost:8086}") String baseUrl) {
        SimpleClientHttpRequestFactory requests = new SimpleClientHttpRequestFactory();
        requests.setConnectTimeout(3000);
        requests.setReadTimeout(10000);
        client = RestClient.builder().baseUrl(baseUrl).requestFactory(requests).build();
    }

    public int targetCalories(String jwt, String goalType) {
        if (!"LOSE".equals(goalType) && !"MAINTAIN".equals(goalType) && !"GAIN".equals(goalType)) {
            throw new AppException(ErrorCode.INVALID_REQUEST);
        }
        try {
            TargetEnvelope response = client.get()
                    .uri(uri -> uri.path("/ai/meal-plans/nutrition-target")
                            .queryParam("goalType", goalType).build())
                    .headers(headers -> headers.setBearerAuth(jwt))
                    .retrieve().body(TargetEnvelope.class);
            int calories = response == null || response.result() == null ? 0 : response.result().targetCalories();
            if (calories <= 0) throw new AppException(ErrorCode.NUTRITION_TARGET_UNAVAILABLE);
            return calories;
        } catch (RestClientResponseException exception) {
            if (exception.getStatusCode().value() == 400) {
                throw new AppException(ErrorCode.NUTRITION_PROFILE_INCOMPLETE);
            }
            if (exception.getStatusCode().value() == 401) {
                throw new AppException(ErrorCode.UNAUTHENTICATED);
            }
            throw new AppException(ErrorCode.NUTRITION_TARGET_UNAVAILABLE);
        } catch (RestClientException exception) {
            throw new AppException(ErrorCode.NUTRITION_TARGET_UNAVAILABLE);
        }
    }

    private record TargetEnvelope(TargetResult result) {}
    private record TargetResult(int targetCalories) {}
}
