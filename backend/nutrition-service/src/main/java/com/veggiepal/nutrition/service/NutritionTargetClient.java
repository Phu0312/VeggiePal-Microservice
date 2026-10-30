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
    /** ai-service ErrorCode.AGE_NOT_SUPPORTED: the calorie target is only calculated for adults. */
    static final int AI_AGE_NOT_SUPPORTED = 6021;

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
                // Every ai-service 400 used to become "profile incomplete", so a user under 18 was told to
                // complete a profile that could never produce a target.
                throw new AppException(aiErrorCode(exception) == AI_AGE_NOT_SUPPORTED
                        ? ErrorCode.NUTRITION_AGE_NOT_SUPPORTED
                        : ErrorCode.NUTRITION_PROFILE_INCOMPLETE);
            }
            if (exception.getStatusCode().value() == 401) {
                throw new AppException(ErrorCode.UNAUTHENTICATED);
            }
            throw new AppException(ErrorCode.NUTRITION_TARGET_UNAVAILABLE);
        } catch (RestClientException exception) {
            throw new AppException(ErrorCode.NUTRITION_TARGET_UNAVAILABLE);
        }
    }

    /** The ErrorCode number in an ai-service error body, or -1 when the body is empty or not an ApiResponse. */
    private static int aiErrorCode(RestClientResponseException exception) {
        try {
            AiError error = exception.getResponseBodyAs(AiError.class);
            return error == null || error.code() == null ? -1 : error.code();
        } catch (RuntimeException unreadableBody) {
            return -1;
        }
    }

    private record AiError(Integer code) {}
    private record TargetEnvelope(TargetResult result) {}
    private record TargetResult(int targetCalories) {}
}
