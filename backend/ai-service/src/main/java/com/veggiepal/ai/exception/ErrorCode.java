package com.veggiepal.ai.exception;

import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;

import lombok.Getter;

@Getter
public enum ErrorCode {

    UNCATEGORIZED_EXCEPTION(9999, "Uncategorized error", HttpStatus.INTERNAL_SERVER_ERROR),
    INVALID_KEY(1001, "Invalid validation key", HttpStatus.BAD_REQUEST),
    UNAUTHENTICATED(1008, "Unauthenticated", HttpStatus.UNAUTHORIZED),
    UNAUTHORIZED(1009, "You do not have permission", HttpStatus.FORBIDDEN),
    INVALID_REQUEST(1018, "Invalid request data", HttpStatus.BAD_REQUEST),

    // AI Chat
    GUEST_AI_QUOTA_EXCEEDED(2030, "You have used all 3 free trial questions. Please register or login to continue.", HttpStatus.TOO_MANY_REQUESTS),
    CONVERSATION_NOT_FOUND(2031, "Conversation not found", HttpStatus.NOT_FOUND),
    GUEST_ID_REQUIRED(2032, "X-Guest-Id header is required", HttpStatus.BAD_REQUEST),
    CHAT_MESSAGE_REQUIRED(2033, "Message content is required", HttpStatus.BAD_REQUEST);

    private final int code;
    private final String message;
    private final HttpStatusCode statusCode;

    ErrorCode(int code, String message, HttpStatusCode statusCode) {
        this.code = code;
        this.message = message;
        this.statusCode = statusCode;
    }
}
