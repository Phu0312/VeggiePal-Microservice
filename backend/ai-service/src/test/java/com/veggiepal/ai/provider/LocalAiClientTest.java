package com.veggiepal.ai.provider;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.*;
import static org.springframework.test.web.client.response.MockRestResponseCreators.*;

import com.veggiepal.ai.common.AppException;
import com.veggiepal.ai.common.ErrorCode;
import com.veggiepal.ai.groq.dto.GroqRequest;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;

class LocalAiClientTest {
    @Test
    void completionUsesLocalModelAndNoAuthorizationHeader() {
        var builder = RestClient.builder().baseUrl("http://localhost:8088/v1");
        var server = MockRestServiceServer.bindTo(builder).build();
        server.expect(requestTo("http://localhost:8088/v1/chat/completions"))
                .andExpect(jsonPath("$.model").value("qwen2.5-1.5b-instruct"))
                .andExpect(jsonPath("$.max_tokens").value(50))
                .andExpect(headerDoesNotExist("Authorization"))
                .andRespond(withSuccess("""
                        {"choices":[{"message":{"role":"assistant","content":"Ăn chay cân đối."},"finish_reason":"stop"}],
                         "usage":{"prompt_tokens":8,"completion_tokens":5,"total_tokens":13}}
                        """, MediaType.APPLICATION_JSON));
        var result = new LocalAiClient(builder.build(), "qwen2.5-1.5b-instruct")
                .complete("groq-model", List.of(new GroqRequest.Message("user", "Xin chào")), 0.2, 50);
        assertEquals("Ăn chay cân đối.", result.content());
        assertEquals(8, result.promptTokens());
        server.verify();
    }

    @Test
    void emptyCompletionIsRejected() {
        var builder = RestClient.builder().baseUrl("http://localhost:8088/v1");
        var server = MockRestServiceServer.bindTo(builder).build();
        server.expect(requestTo("http://localhost:8088/v1/chat/completions"))
                .andRespond(withSuccess("{\"choices\":[{\"message\":{\"content\":\" \"}}]}", MediaType.APPLICATION_JSON));
        var client = new LocalAiClient(builder.build(), "qwen");
        var ex = assertThrows(AppException.class,
                () -> client.complete("unused", List.of(new GroqRequest.Message("user", "test")), 0, 20));
        assertEquals(ErrorCode.INVALID_AI_RESPONSE, ex.getErrorCode());
        server.verify();
    }

    @Test
    void unavailableServerDoesNotFallBack() {
        var builder = RestClient.builder().baseUrl("http://localhost:8088/v1");
        var server = MockRestServiceServer.bindTo(builder).build();
        server.expect(requestTo("http://localhost:8088/v1/chat/completions"))
                .andRespond(withStatus(HttpStatus.SERVICE_UNAVAILABLE));
        var client = new LocalAiClient(builder.build(), "qwen");
        var ex = assertThrows(AppException.class,
                () -> client.complete("unused", List.of(new GroqRequest.Message("user", "test")), 0, 20));
        assertEquals(ErrorCode.GROQ_UNAVAILABLE, ex.getErrorCode());
        server.verify();
    }
}
