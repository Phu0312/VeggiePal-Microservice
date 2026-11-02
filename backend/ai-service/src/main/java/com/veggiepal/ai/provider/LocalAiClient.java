package com.veggiepal.ai.provider;

import com.veggiepal.ai.common.AppException;
import com.veggiepal.ai.common.ErrorCode;
import com.veggiepal.ai.groq.GroqClient.GroqResult;
import com.veggiepal.ai.groq.dto.GroqRequest;
import com.veggiepal.ai.groq.dto.GroqResponse;
import java.util.List;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Component
public class LocalAiClient implements AiProviderClient {
    private final RestClient http;
    private final String model;

    public LocalAiClient(@Qualifier("localAiRestClient") RestClient http,
                         @Value("${ai.local.model:qwen2.5-1.5b-instruct}") String model) {
        this.http = http;
        this.model = model;
    }

    public String configuredModel() { return model; }

    @Override
    public GroqResult complete(String ignoredGroqModel, List<GroqRequest.Message> messages,
                               double temperature, int maxTokens) {
        try {
            GroqResponse response = http.post().uri("/chat/completions")
                    .body(java.util.Map.of("model", model, "messages", messages,
                            "temperature", temperature, "max_tokens", maxTokens))
                    .retrieve().body(GroqResponse.class);
            if (response == null || response.choices() == null || response.choices().isEmpty()
                    || response.choices().getFirst().message() == null
                    || response.choices().getFirst().message().content() == null
                    || response.choices().getFirst().message().content().isBlank()) {
                throw new AppException(ErrorCode.INVALID_AI_RESPONSE);
            }
            var choice = response.choices().getFirst();
            var usage = response.usage();
            return new GroqResult(choice.message().content(),
                    usage == null ? 0 : usage.prompt_tokens(),
                    usage == null ? 0 : usage.completion_tokens(), choice.finishReason());
        } catch (RestClientException exception) {
            throw new AppException(ErrorCode.GROQ_UNAVAILABLE, exception);
        }
    }
}
