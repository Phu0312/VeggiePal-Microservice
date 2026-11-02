package com.veggiepal.ai.provider;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

import com.veggiepal.ai.groq.GroqClient;
import org.junit.jupiter.api.Test;

class ProviderConfigTest {
    private final ProviderConfig config = new ProviderConfig();
    private final LocalAiClient local = mock(LocalAiClient.class);
    private final GroqClient groq = mock(GroqClient.class);

    @Test
    void allTextFeaturesDefaultToLocalSelection() {
        assertSame(local, config.chatAiProvider(local, groq, "local"));
        assertSame(local, config.mealAiProvider(local, groq, "local"));
        assertSame(local, config.recommendationAiProvider(local, groq, "local"));
        assertSame(local, config.moderationAiProvider(local, groq, "local"));
    }

    @Test
    void groqRequiresExplicitSelection() {
        assertSame(groq, config.chatAiProvider(local, groq, "groq"));
        assertThrows(IllegalArgumentException.class,
                () -> config.chatAiProvider(local, groq, "unknown"));
    }
}
