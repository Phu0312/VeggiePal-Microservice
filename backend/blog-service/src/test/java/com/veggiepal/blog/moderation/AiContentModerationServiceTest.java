package com.veggiepal.blog.moderation;

import static org.assertj.core.api.Assertions.assertThat;

import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;

import com.sun.net.httpserver.HttpServer;

// A real HTTP server rather than a mocked RestClient: the defect this guards against lives in
// the default message converters, which only run when a response is actually deserialized.
class AiContentModerationServiceTest {

    HttpServer server;

    @BeforeEach
    void setUp() {
        SecurityContextHolder.getContext().setAuthentication(new JwtAuthenticationToken(Jwt.withTokenValue("token")
                .header("alg", "HS256").claim("userId", 7L).issuedAt(Instant.now()).build()));
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
        if (server != null) server.stop(0);
    }

    @Test
    void moderate_readsDecisionAndReasonFromAiService() throws Exception {
        String baseUrl = respondWith(200, "{\"code\":1000,\"result\":{\"decision\":\"REJECTED\",\"reason\":\"spam\"}}");
        var service = new AiContentModerationService(baseUrl, Duration.ofSeconds(2), Duration.ofSeconds(2));

        ModerationResult result = service.moderate("VIDEO", 2L, 7L, "text");

        assertThat(result).isEqualTo(new ModerationResult(ModerationDecision.REJECTED, "spam"));
    }

    @Test
    void moderate_whenAiServiceReturns503_fallsBackToReviewRequired() throws Exception {
        String baseUrl = respondWith(503, "{\"code\":6004,\"message\":\"unavailable\"}");
        var service = new AiContentModerationService(baseUrl, Duration.ofSeconds(1), Duration.ofSeconds(1));

        ModerationResult result = service.moderate("BLOG", 10L, 7L, "text");

        assertThat(result.decision()).isEqualTo(ModerationDecision.REVIEW_REQUIRED);
    }

    @Test
    void moderate_whenAiServiceUnreachable_fallsBackToReviewRequired() {
        var service = new AiContentModerationService("http://127.0.0.1:1", Duration.ofMillis(200), Duration.ofMillis(200));

        ModerationResult result = service.moderate("BLOG", 10L, 7L, "text");

        assertThat(result.decision()).isEqualTo(ModerationDecision.REVIEW_REQUIRED);
    }

    private String respondWith(int status, String json) throws Exception {
        server = HttpServer.create(new InetSocketAddress("localhost", 0), 0);
        server.createContext("/ai/moderation/check", exchange -> {
            byte[] body = json.getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().add("Content-Type", "application/json");
            exchange.sendResponseHeaders(status, body.length);
            exchange.getResponseBody().write(body);
            exchange.close();
        });
        server.start();
        return "http://localhost:" + server.getAddress().getPort();
    }
}
