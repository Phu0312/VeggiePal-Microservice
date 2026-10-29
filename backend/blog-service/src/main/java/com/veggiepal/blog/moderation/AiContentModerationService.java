package com.veggiepal.blog.moderation;

import com.veggiepal.blog.exception.AppException;
import com.veggiepal.blog.exception.ErrorCode;
import java.time.Duration;
import java.util.Map;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
// Jackson 3: Spring Boot 4's RestClient cannot deserialize into Jackson 2's com.fasterxml JsonNode.
import tools.jackson.databind.JsonNode;

@Service
@Slf4j
public class AiContentModerationService implements ContentModerationService {

    static final String FALLBACK_REASON = "AI moderation temporarily unavailable; pending manual review";

    private final RestClient client;

    public AiContentModerationService(
            @Value("${services.ai.base-url}") String baseUrl,
            @Value("${services.ai.connect-timeout:3s}") Duration connectTimeout,
            @Value("${services.ai.read-timeout:20s}") Duration readTimeout
    ) {
        var requestFactory = new SimpleClientHttpRequestFactory();
        requestFactory.setConnectTimeout(connectTimeout);
        requestFactory.setReadTimeout(readTimeout);
        this.client = RestClient.builder().baseUrl(baseUrl).requestFactory(requestFactory).build();
    }

    @Override
    public ModerationResult moderate(
            String contentType,
            Long externalContentId,
            Long authorId,
            String text
    ) {
        String token = currentToken();
        try {
            JsonNode response = client.post()
                    .uri("/ai/moderation/check")
                    .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                    .body(Map.of(
                            "contentType", contentType,
                            "externalContentId", externalContentId,
                            "authorId", authorId,
                            "text", text
                    ))
                    .retrieve()
                    .body(JsonNode.class);

            JsonNode result = response == null ? null : response.path("result");
            if (result == null || result.isMissingNode() || result.path("decision").asString().isBlank()) {
                log.warn("AI moderation returned missing decision for {}:{}; falling back to REVIEW_REQUIRED",
                        contentType, externalContentId);
                return new ModerationResult(ModerationDecision.REVIEW_REQUIRED, FALLBACK_REASON);
            }

            ModerationDecision decision;
            try {
                decision = ModerationDecision.valueOf(result.path("decision").asString());
            } catch (IllegalArgumentException exception) {
                log.warn("AI moderation returned unknown decision '{}' for {}:{}; falling back to REVIEW_REQUIRED",
                        result.path("decision").asString(), contentType, externalContentId);
                return new ModerationResult(ModerationDecision.REVIEW_REQUIRED, FALLBACK_REASON);
            }
            return new ModerationResult(decision, result.path("reason").asString(null));
        } catch (RestClientException exception) {
            log.warn("AI moderation unavailable for {}:{}; falling back to REVIEW_REQUIRED",
                    contentType, externalContentId, exception);
            return new ModerationResult(ModerationDecision.REVIEW_REQUIRED, FALLBACK_REASON);
        }
    }

    private String currentToken() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication instanceof JwtAuthenticationToken jwtAuthentication) {
            return jwtAuthentication.getToken().getTokenValue();
        }
        throw new AppException(ErrorCode.UNAUTHENTICATED);
    }
}
