package com.veggiepal.nutrition.controller;

import java.util.List;
import java.util.Map;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import com.veggiepal.nutrition.dto.response.ApiResponse;
import com.veggiepal.nutrition.entity.ChatConversation;
import com.veggiepal.nutrition.exception.AppException;
import com.veggiepal.nutrition.exception.ErrorCode;
import com.veggiepal.nutrition.service.ChatService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@RestController
@RequestMapping("/ai")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Tag(name = "AI Chatbot", description = "Nutrition AI chatbot (guest trial + full authenticated)")
public class ChatController {

    ChatService chatService;

    @Operation(summary = "Guest chatbot - max 3 free questions. Requires X-Guest-Id header.")
    @PostMapping("/chat/guest")
    ApiResponse<Map<String, Object>> guestChat(
            @RequestHeader(value = "X-Guest-Id", required = false) String guestId,
            @RequestBody Map<String, String> body
    ) {
        if (guestId == null || guestId.isBlank()) {
            throw new AppException(ErrorCode.GUEST_ID_REQUIRED);
        }

        String message = body.get("message");
        if (message == null || message.isBlank()) {
            throw new AppException(ErrorCode.CHAT_MESSAGE_REQUIRED);
        }

        return ApiResponse.<Map<String, Object>>builder()
                .result(chatService.guestChat(guestId, message))
                .build();
    }

    @Operation(summary = "Authenticated chatbot - create or continue a conversation")
    @PostMapping("/chat")
    ApiResponse<Map<String, Object>> chat(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @RequestBody Map<String, Object> body
    ) {
        String message = (String) body.get("message");
        if (message == null || message.isBlank()) {
            throw new AppException(ErrorCode.CHAT_MESSAGE_REQUIRED);
        }

        Long conversationId = body.get("conversationId") != null
                ? ((Number) body.get("conversationId")).longValue()
                : null;

        return ApiResponse.<Map<String, Object>>builder()
                .result(chatService.authenticatedChat(CurrentUser.id(jwt), conversationId, message))
                .build();
    }

    @Operation(summary = "List user's conversations")
    @GetMapping("/conversations")
    ApiResponse<List<ChatConversation>> getConversations(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt
    ) {
        return ApiResponse.<List<ChatConversation>>builder()
                .result(chatService.getConversations(CurrentUser.id(jwt)))
                .build();
    }

    @Operation(summary = "Get conversation with all messages")
    @GetMapping("/conversations/{id}")
    ApiResponse<Map<String, Object>> getConversation(
            @Parameter(hidden = true) @AuthenticationPrincipal Jwt jwt,
            @PathVariable("id") Long id
    ) {
        return ApiResponse.<Map<String, Object>>builder()
                .result(chatService.getConversation(CurrentUser.id(jwt), id))
                .build();
    }
}
