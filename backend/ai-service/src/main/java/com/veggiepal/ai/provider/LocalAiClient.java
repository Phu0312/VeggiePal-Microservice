package com.veggiepal.ai.provider;

import com.veggiepal.ai.common.AppException;
import com.veggiepal.ai.common.ErrorCode;
import java.util.List;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Component
public class LocalAiClient {
    private final RestClient http;
    private final String model;

    public LocalAiClient(@Qualifier("localAiRestClient") RestClient http,
                         @Value("${ai.local.model:qwen2.5-1.5b-instruct}") String model) {
        this.http = http;
        this.model = model;
    }

    public String configuredModel() { return model; }

    public AiResult complete(List<AiMessage> messages, double temperature, int maxTokens) {
        return complete(messages, temperature, maxTokens, SamplingOptions.NONE);
    }

    /**
     * Same as the three-argument call, plus optional llama.cpp sampling controls
     * (top_p, top_k, repeat_penalty, frequency_penalty) sent only when set.
     */
    public AiResult complete(List<AiMessage> messages, double temperature, int maxTokens, SamplingOptions sampling) {
        try {
            java.util.Map<String, Object> body = new java.util.LinkedHashMap<>();
            body.put("model", model);
            body.put("messages", messages);
            body.put("temperature", temperature);
            body.put("max_tokens", maxTokens);
            if (sampling != null) {
                sampling.applyTo(body);
            }
            AiCompletionResponse response = http.post().uri("/chat/completions")
                    .body(body)
                    .retrieve().body(AiCompletionResponse.class);
            if (response == null || response.choices() == null || response.choices().isEmpty()
                    || response.choices().getFirst().message() == null
                    || response.choices().getFirst().message().content() == null
                    || response.choices().getFirst().message().content().isBlank()) {
                throw new AppException(ErrorCode.INVALID_AI_RESPONSE);
            }
            var choice = response.choices().getFirst();
            var usage = response.usage();
            return new AiResult(choice.message().content(),
                    usage == null ? 0 : usage.prompt_tokens(),
                    usage == null ? 0 : usage.completion_tokens(), choice.finishReason());
        } catch (RestClientException exception) {
            throw new AppException(ErrorCode.AI_UNAVAILABLE, exception);
        }
    }

    public record AiResult(String content, int promptTokens, int completionTokens, String finishReason) {
        public AiResult(String content, int promptTokens, int completionTokens) {
            this(content, promptTokens, completionTokens, null);
        }
        public boolean isLengthTruncated() { return "length".equalsIgnoreCase(finishReason); }
    }

    /** Optional llama.cpp sampling parameters; null fields are not sent. */
    public record SamplingOptions(Double topP, Integer topK, Double repeatPenalty, Double frequencyPenalty) {
        public static final SamplingOptions NONE = new SamplingOptions(null, null, null, null);

        void applyTo(java.util.Map<String, Object> body) {
            if (topP != null) body.put("top_p", topP);
            if (topK != null) body.put("top_k", topK);
            if (repeatPenalty != null) body.put("repeat_penalty", repeatPenalty);
            if (frequencyPenalty != null) body.put("frequency_penalty", frequencyPenalty);
        }
    }}
