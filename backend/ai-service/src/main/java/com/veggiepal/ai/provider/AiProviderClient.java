package com.veggiepal.ai.provider;

import com.veggiepal.ai.groq.GroqClient.GroqResult;
import com.veggiepal.ai.groq.dto.GroqRequest;
import java.util.List;

/** Text completion contract shared by the existing Groq client and local inference. */
public interface AiProviderClient {
    GroqResult complete(String model, List<GroqRequest.Message> messages, double temperature, int maxTokens);

    static String usageModel(AiProviderClient client, String groqModel) {
        return client instanceof LocalAiClient local ? local.configuredModel() : groqModel;
    }
}
