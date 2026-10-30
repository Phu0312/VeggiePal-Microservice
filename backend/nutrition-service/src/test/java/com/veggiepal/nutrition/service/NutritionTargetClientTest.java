package com.veggiepal.nutrition.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.sun.net.httpserver.HttpServer;
import com.veggiepal.nutrition.exception.AppException;
import com.veggiepal.nutrition.exception.ErrorCode;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.jupiter.api.Test;

class NutritionTargetClientTest {
    @Test
    void readsAiTargetWithSameGoalAndBearerToken() throws Exception {
        HttpServer server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        AtomicReference<String> query = new AtomicReference<>();
        AtomicReference<String> authorization = new AtomicReference<>();
        server.createContext("/ai/meal-plans/nutrition-target", exchange -> {
            query.set(exchange.getRequestURI().getQuery());
            authorization.set(exchange.getRequestHeaders().getFirst("Authorization"));
            byte[] body = "{\"code\":1000,\"result\":{\"targetCalories\":2100}}".getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().set("Content-Type", "application/json");
            exchange.sendResponseHeaders(200, body.length);
            try (var out = exchange.getResponseBody()) { out.write(body); }
        });
        server.start();
        try {
            NutritionTargetClient client = new NutritionTargetClient("http://127.0.0.1:" + server.getAddress().getPort());
            assertThat(client.targetCalories("test-jwt", "MAINTAIN")).isEqualTo(2100);
            assertThat(query.get()).isEqualTo("goalType=MAINTAIN");
            assertThat(authorization.get()).isEqualTo("Bearer test-jwt");
        } finally {
            server.stop(0);
        }
    }

    @Test
    void rejectsUnknownGoalBeforeCallingAi() {
        NutritionTargetClient client = new NutritionTargetClient("http://127.0.0.1:1");
        assertThatThrownBy(() -> client.targetCalories("test-jwt", "UNKNOWN"))
                .isInstanceOfSatisfying(AppException.class,
                        error -> assertThat(error.getErrorCode()).isEqualTo(ErrorCode.INVALID_REQUEST));
    }

    @Test
    void reportsUnderageUserSeparatelyFromAnIncompleteProfile() throws Exception {
        assertThat(errorFor(400, "{\"code\":6021,\"message\":\"under 18\"}"))
                .isEqualTo(ErrorCode.NUTRITION_AGE_NOT_SUPPORTED);
    }

    @Test
    void otherAiBadRequestsStayIncompleteProfile() throws Exception {
        assertThat(errorFor(400, "{\"code\":6020,\"message\":\"profile\"}"))
                .isEqualTo(ErrorCode.NUTRITION_PROFILE_INCOMPLETE);
        assertThat(errorFor(400, "{\"code\":6010,\"message\":\"health record\"}"))
                .isEqualTo(ErrorCode.NUTRITION_PROFILE_INCOMPLETE);
        assertThat(errorFor(400, "not json")).isEqualTo(ErrorCode.NUTRITION_PROFILE_INCOMPLETE);
    }

    @Test
    void aiServerErrorsMeanTheTargetIsUnavailable() throws Exception {
        assertThat(errorFor(500, "{\"code\":6999}")).isEqualTo(ErrorCode.NUTRITION_TARGET_UNAVAILABLE);
    }

    private ErrorCode errorFor(int status, String body) throws Exception {
        HttpServer server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/ai/meal-plans/nutrition-target", exchange -> {
            byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().set("Content-Type", "application/json");
            exchange.sendResponseHeaders(status, bytes.length);
            try (var out = exchange.getResponseBody()) { out.write(bytes); }
        });
        server.start();
        try {
            NutritionTargetClient client = new NutritionTargetClient("http://127.0.0.1:" + server.getAddress().getPort());
            AtomicReference<ErrorCode> thrown = new AtomicReference<>();
            assertThatThrownBy(() -> client.targetCalories("test-jwt", "MAINTAIN"))
                    .isInstanceOfSatisfying(AppException.class, error -> thrown.set(error.getErrorCode()));
            return thrown.get();
        } finally {
            server.stop(0);
        }
    }

    @Test
    void reportsIncompleteProfileWhenAiCannotCalculateTarget() throws Exception {
        HttpServer server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/ai/meal-plans/nutrition-target", exchange -> {
            exchange.sendResponseHeaders(400, -1);
            exchange.close();
        });
        server.start();
        try {
            NutritionTargetClient client = new NutritionTargetClient("http://127.0.0.1:" + server.getAddress().getPort());
            assertThatThrownBy(() -> client.targetCalories("test-jwt", "MAINTAIN"))
                    .isInstanceOfSatisfying(AppException.class,
                            error -> assertThat(error.getErrorCode()).isEqualTo(ErrorCode.NUTRITION_PROFILE_INCOMPLETE));
        } finally {
            server.stop(0);
        }
    }
}
