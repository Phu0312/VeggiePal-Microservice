package com.veggiepal.recipe.exception;

import java.util.Map;
import java.util.Objects;

import jakarta.validation.ConstraintViolation;

import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.multipart.MaxUploadSizeExceededException;
import org.springframework.web.multipart.support.MissingServletRequestPartException;

import com.veggiepal.recipe.dto.response.ApiResponse;

@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final String MIN_ATTRIBUTE = "min";
    private static final String MAX_ATTRIBUTE = "max";

    @ExceptionHandler(AppException.class)
    ResponseEntity<ApiResponse<Void>> handleAppException(
            AppException exception
    ) {

        ErrorCode errorCode = exception.getErrorCode();

        ApiResponse<Void> response = ApiResponse
                .<Void>builder()
                .code(errorCode.getCode())
                .message(errorCode.getMessage())
                .build();

        return ResponseEntity
                .status(errorCode.getStatusCode())
                .body(response);
    }

    @ExceptionHandler({
            HttpMessageNotReadableException.class,
            MethodArgumentTypeMismatchException.class,
            MissingServletRequestParameterException.class
    })
    ResponseEntity<ApiResponse<Void>> handleInvalidRequest(
            Exception exception
    ) {

        ErrorCode errorCode = ErrorCode.INVALID_REQUEST;

        ApiResponse<Void> response = ApiResponse
                .<Void>builder()
                .code(errorCode.getCode())
                .message(errorCode.getMessage())
                .build();

        return ResponseEntity
                .status(errorCode.getStatusCode())
                .body(response);
    }

    @ExceptionHandler(MaxUploadSizeExceededException.class)
    ResponseEntity<ApiResponse<Void>> handleMaxUploadSize(
            MaxUploadSizeExceededException exception
    ) {
        ErrorCode errorCode = ErrorCode.RECIPE_IMAGE_TOO_LARGE;
        return ResponseEntity
                .status(errorCode.getStatusCode())
                .body(ApiResponse.<Void>builder()
                        .code(errorCode.getCode())
                        .message(errorCode.getMessage())
                        .build());
    }

    @ExceptionHandler(MissingServletRequestPartException.class)
    ResponseEntity<ApiResponse<Void>> handleMissingPart(
            MissingServletRequestPartException exception
    ) {
        ErrorCode errorCode = ErrorCode.RECIPE_IMAGE_REQUIRED;
        return ResponseEntity
                .status(errorCode.getStatusCode())
                .body(ApiResponse.<Void>builder()
                        .code(errorCode.getCode())
                        .message(errorCode.getMessage())
                        .build());
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    ResponseEntity<ApiResponse<Void>> handleValidationException(
            MethodArgumentNotValidException exception
    ) {

        String enumKey = Objects.requireNonNull(
                exception
                        .getFieldError()
        ).getDefaultMessage();

        ErrorCode errorCode = ErrorCode.INVALID_KEY;
        Map<String, Object> attributes = null;

        try {

            errorCode = ErrorCode.valueOf(enumKey);

            ConstraintViolation<?> constraintViolation =
                    exception.getBindingResult()
                            .getAllErrors()
                            .getFirst()
                            .unwrap(ConstraintViolation.class);

            attributes = constraintViolation
                    .getConstraintDescriptor()
                    .getAttributes();

        } catch (Exception ignored) {
        }

        String message = attributes != null
                ? mapAttribute(errorCode.getMessage(), attributes)
                : errorCode.getMessage();

        ApiResponse<Void> response = ApiResponse
                .<Void>builder()
                .code(errorCode.getCode())
                .message(message)
                .build();

        return ResponseEntity
                .status(errorCode.getStatusCode())
                .body(response);
    }

    @ExceptionHandler(AccessDeniedException.class)
    void handleAccessDenied(
            AccessDeniedException exception
    ) {

        throw exception;
    }

    @ExceptionHandler(Exception.class)
    ResponseEntity<ApiResponse<Void>> handleException(
            Exception exception
    ) {

        ErrorCode errorCode =
                ErrorCode.UNCATEGORIZED_EXCEPTION;

        ApiResponse<Void> response = ApiResponse
                .<Void>builder()
                .code(errorCode.getCode())
                .message(errorCode.getMessage())
                .build();

        return ResponseEntity
                .status(errorCode.getStatusCode())
                .body(response);
    }

    private String mapAttribute(
            String message,
            Map<String, Object> attributes
    ) {
        String mapped = message;
        for (String attribute : new String[]{MIN_ATTRIBUTE, MAX_ATTRIBUTE}) {
            Object value = attributes.get(attribute);
            if (value != null) {
                mapped = mapped.replace("{" + attribute + "}", String.valueOf(value));
            }
        }
        return mapped;
    }
}
