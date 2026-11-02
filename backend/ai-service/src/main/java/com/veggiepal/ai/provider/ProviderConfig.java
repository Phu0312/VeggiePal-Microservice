package com.veggiepal.ai.provider;

import com.veggiepal.ai.groq.GroqClient;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class ProviderConfig {
    @Bean("chatAiProvider")
    AiProviderClient chatAiProvider(@Qualifier("localAiClient") LocalAiClient local,
            @Qualifier("groqClient") GroqClient groq,
            @Value("${ai.chat.provider:local}") String selection) { return select(selection, local, groq); }

    @Bean("mealAiProvider")
    AiProviderClient mealAiProvider(@Qualifier("localAiClient") LocalAiClient local,
            @Qualifier("groqClient") GroqClient groq,
            @Value("${ai.meal-plan.provider:local}") String selection) { return select(selection, local, groq); }

    @Bean("recommendationAiProvider")
    AiProviderClient recommendationAiProvider(@Qualifier("localAiClient") LocalAiClient local,
            @Qualifier("groqClient") GroqClient groq,
            @Value("${ai.recommendation.provider:local}") String selection) { return select(selection, local, groq); }

    @Bean("moderationAiProvider")
    AiProviderClient moderationAiProvider(@Qualifier("localAiClient") LocalAiClient local,
            @Qualifier("groqClient") GroqClient groq,
            @Value("${ai.moderation.provider:local}") String selection) { return select(selection, local, groq); }

    private AiProviderClient select(String selection, LocalAiClient local, GroqClient groq) {
        return switch (selection.toLowerCase(java.util.Locale.ROOT)) {
            case "local" -> local;
            case "groq" -> groq;
            default -> throw new IllegalArgumentException("Unknown AI provider: " + selection);
        };
    }
}
