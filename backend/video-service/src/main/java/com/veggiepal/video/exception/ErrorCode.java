package com.veggiepal.video.exception;

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

    CATEGORY_ID_REQUIRED(3008, "Category is required", HttpStatus.BAD_REQUEST),
    VIDEO_NOT_EXISTED(3050, "Video not existed", HttpStatus.NOT_FOUND),
    VIDEO_TITLE_REQUIRED(3051, "Video title is required", HttpStatus.BAD_REQUEST),
    VIDEO_URL_REQUIRED(3052, "Video URL is required", HttpStatus.BAD_REQUEST),
    INVALID_VIDEO_STATUS_TRANSITION(3053, "Video is not in a state that allows this action", HttpStatus.BAD_REQUEST);

    private final int code;
    private final String message;
    private final HttpStatusCode statusCode;

    ErrorCode(int code, String message, HttpStatusCode statusCode) {
        this.code = code;
        this.message = message;
        this.statusCode = statusCode;
    }
}
