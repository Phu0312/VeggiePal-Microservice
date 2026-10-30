package com.veggiepal.exception;

import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;

import lombok.Getter;

@Getter
public enum ErrorCode {

    UNCATEGORIZED_EXCEPTION(9999, "Uncategorized error", HttpStatus.INTERNAL_SERVER_ERROR),

    INVALID_KEY(1001, "Invalid validation key", HttpStatus.BAD_REQUEST),

    EMAIL_EXISTED(1002, "Email already existed", HttpStatus.BAD_REQUEST),

    INVALID_PASSWORD(1003, "Password must be at least {min} characters", HttpStatus.BAD_REQUEST),

    INVALID_EMAIL(1004, "Email is invalid", HttpStatus.BAD_REQUEST),

    EMAIL_REQUIRED(1005, "Email is required", HttpStatus.BAD_REQUEST),

    FULL_NAME_REQUIRED(1006, "Full name is required", HttpStatus.BAD_REQUEST),

    USER_NOT_EXISTED(1007, "User not existed", HttpStatus.NOT_FOUND),

    UNAUTHENTICATED(1008, "Unauthenticated", HttpStatus.UNAUTHORIZED),

    PASSWORD_REQUIRED(1010, "Password is required", HttpStatus.BAD_REQUEST),

    UNAUTHORIZED(1009, "You do not have permission", HttpStatus.FORBIDDEN),

    INVALID_DATE_OF_BIRTH(1013, "Date of birth must be in the past", HttpStatus.BAD_REQUEST),

    WRONG_PASSWORD(1011, "Current password is incorrect", HttpStatus.BAD_REQUEST),

    PASSWORD_UNCHANGED(1012, "New password must be different from current password", HttpStatus.BAD_REQUEST),

    FILE_UPLOAD_FAILED(1017, "Could not upload file, please try again later", HttpStatus.SERVICE_UNAVAILABLE),

    AVATAR_REQUIRED(1014, "Avatar file is required", HttpStatus.BAD_REQUEST),

    INVALID_AVATAR_TYPE(1015, "Avatar must be a JPEG, PNG or WEBP image", HttpStatus.BAD_REQUEST),

    AVATAR_TOO_LARGE(1016, "Avatar must not exceed 2MB", HttpStatus.BAD_REQUEST),

    INVALID_REQUEST(1018, "Invalid request data", HttpStatus.BAD_REQUEST),

    GOOGLE_TOKEN_INVALID(1019, "Google sign-in failed", HttpStatus.UNAUTHORIZED),

    USER_STATUS_UNCHANGED(1020, "User already has this status", HttpStatus.BAD_REQUEST),

    USER_BLOCKED(1021, "User account is locked or not active", HttpStatus.FORBIDDEN),

    CANNOT_MODIFY_SELF(1022, "Admin cannot lock or demote their own account", HttpStatus.BAD_REQUEST),

    USER_ROLE_UNCHANGED(1023, "User already has this role", HttpStatus.BAD_REQUEST),

    OTP_REQUIRED(1024, "OTP code is required", HttpStatus.BAD_REQUEST),

    OTP_INVALID_OR_EXPIRED(1025, "OTP code is invalid or expired", HttpStatus.BAD_REQUEST),

    OTP_MAX_ATTEMPTS_EXCEEDED(1026, "Too many invalid OTP attempts, please request a new code", HttpStatus.TOO_MANY_REQUESTS),

    RESET_TOKEN_INVALID(1027, "Password reset token is invalid or expired", HttpStatus.BAD_REQUEST),

    EMAIL_ALREADY_VERIFIED(1028, "Email is already verified", HttpStatus.BAD_REQUEST),

    REFRESH_TOKEN_REQUIRED(1029, "Refresh token is required", HttpStatus.BAD_REQUEST),

    REFRESH_TOKEN_INVALID(1030, "Refresh token is invalid, expired or revoked", HttpStatus.UNAUTHORIZED),

    FAVORITE_TARGET_REQUIRED(1031, "Favorite target type and id are required", HttpStatus.BAD_REQUEST),

    BADGE_NOT_EXISTED(1032, "Badge code not existed", HttpStatus.BAD_REQUEST);

    ErrorCode(
            int code,
            String message,
            HttpStatusCode statusCode
    ) {
        this.code = code;
        this.message = message;
        this.statusCode = statusCode;
    }

    private final int code;

    private final String message;

    private final HttpStatusCode statusCode;

    public int getCode() {
        return code;
    }

    public String getMessage() {
        return message;
    }

    public HttpStatusCode getStatusCode() {
        return statusCode;
    }
}
