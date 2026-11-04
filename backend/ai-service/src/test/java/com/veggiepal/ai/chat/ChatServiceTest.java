package com.veggiepal.ai.chat;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import java.util.List;
import com.veggiepal.ai.provider.LocalAiClient;
import com.veggiepal.ai.monitoring.UsageService;
import com.veggiepal.ai.quota.QuotaProperties;
import com.veggiepal.ai.quota.QuotaService;
import com.veggiepal.ai.quota.PremiumQuotaService;
import org.junit.jupiter.api.Test;

class ChatServiceTest {
    @Test
    void failedMemberInferenceStillConsumesTheReservedQuotaSlot() {
        PremiumQuotaService premium = mock(PremiumQuotaService.class);
        ChatConversationRepository conversations = mock(ChatConversationRepository.class);
        ChatMessageRepository messages = mock(ChatMessageRepository.class);
        LocalAiClient provider = mock(LocalAiClient.class);
        when(provider.configuredModel()).thenReturn("chat-model");
        UsageService usage = mock(UsageService.class);
        when(conversations.save(any(ChatConversation.class))).thenAnswer(call -> call.getArgument(0));
        when(messages.findByConversationIdOrderByCreatedAtDesc(any(), any())).thenReturn(List.of());
        when(provider.complete(anyList(), eq(0.4), eq(700)))
                .thenThrow(new IllegalStateException("inference failed"));
        ChatService service = new ChatService(conversations, messages, mock(QuotaService.class), premium,
                new QuotaProperties(3, 50, 12, 4000), provider, usage,
                mock(GuestSessionService.class), mock(ChatPersistenceService.class));

        assertThrows(IllegalStateException.class,
                () -> service.member(7L, new ChatDtos.ChatRequest(null, "protein?")));
        verify(premium).reserveChat(7L);
        verify(usage).failure(eq(7L), eq("user:7"), eq("CHAT"), anyString(), anyLong(), any());
        verifyNoMoreInteractions(premium);
    }

    @Test
    void guestChatUsesQuotaAndReturnsProviderUsage() {
        QuotaService quota=mock(QuotaService.class);LocalAiClient ai=mock(LocalAiClient.class);UsageService usage=mock(UsageService.class);
        when(ai.configuredModel()).thenReturn("chat-model");
        when(quota.reserveChat("guest-ip:ip-hash",true)).thenReturn(2);
        when(ai.complete(anyList(),eq(0.4),eq(700))).thenReturn(new LocalAiClient.AiResult("answer",10,5));
        GuestSessionService guestSessions=mock(GuestSessionService.class);
        when(guestSessions.requireValid("abcdefghijklmnop", "203.0.113.10"))
                .thenReturn(new GuestSession("abcdefghijklmnop", "ip-hash", java.time.LocalDateTime.now(), java.time.LocalDateTime.now().plusHours(1)));
        ChatService service=new ChatService(mock(ChatConversationRepository.class),mock(ChatMessageRepository.class),quota,
                mock(PremiumQuotaService.class),new QuotaProperties(3,50,12,4000),ai,usage,
                guestSessions, mock(ChatPersistenceService.class));
        var result=service.guest("abcdefghijklmnop","  protein?  ", "203.0.113.10");
        assertEquals("answer",result.answer());assertEquals(2,result.remainingRequests());assertEquals(10,result.promptTokens());
        verify(guestSessions).requireValid("abcdefghijklmnop", "203.0.113.10");
        verify(usage).success(eq(null),eq("guest-ip:ip-hash"),eq("CHAT"),eq("chat-model"),any(),anyLong());
    }
}
