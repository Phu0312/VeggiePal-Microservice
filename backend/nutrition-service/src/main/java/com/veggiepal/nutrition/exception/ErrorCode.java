package com.veggiepal.nutrition.exception;

import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;

import lombok.Getter;

@Getter
public enum ErrorCode {

    // Shared codes: keep the same numbers as identity-service
    UNCATEGORIZED_EXCEPTION(9999, "Uncategorized error", HttpStatus.INTERNAL_SERVER_ERROR),

    INVALID_KEY(1001, "Invalid validation key", HttpStatus.BAD_REQUEST),

    UNAUTHENTICATED(1008, "Unauthenticated", HttpStatus.UNAUTHORIZED),

    UNAUTHORIZED(1009, "You do not have permission", HttpStatus.FORBIDDEN),

    HEIGHT_REQUIRED(2001, "Height is required", HttpStatus.BAD_REQUEST),

    INVALID_HEIGHT(2002, "Height must be between 50 and 250 cm with at most 1 decimal", HttpStatus.BAD_REQUEST),

    WEIGHT_REQUIRED(2003, "Weight is required", HttpStatus.BAD_REQUEST),

    INVALID_WEIGHT(2004, "Weight must be between 20 and 300 kg with at most 1 decimal", HttpStatus.BAD_REQUEST),

    HEALTH_RECORD_NOT_EXISTED(2005, "Health record not existed", HttpStatus.NOT_FOUND),

    ALLERGEN_IDS_REQUIRED(2006, "Allergen list is required", HttpStatus.BAD_REQUEST),

    ALLERGEN_NOT_EXISTED(2007, "Allergen not existed", HttpStatus.BAD_REQUEST),

    FOOD_NAME_REQUIRED(2008, "Food name is required", HttpStatus.BAD_REQUEST),

    INVALID_NUTRITION_VALUE(2009, "Nutrition or activity values must not be negative", HttpStatus.BAD_REQUEST),

    FOOD_LOG_NOT_EXISTED(2010, "Food log entry not existed", HttpStatus.NOT_FOUND),

    INVALID_WATER_AMOUNT(2011, "Water amount must be between 1 and 5000 ml", HttpStatus.BAD_REQUEST),
    NUTRITION_TARGET_UNAVAILABLE(2012, "Nutrition target is unavailable", HttpStatus.SERVICE_UNAVAILABLE),
    NUTRITION_PROFILE_INCOMPLETE(2013, "Complete your health record and profile to calculate a nutrition target", HttpStatus.BAD_REQUEST),
    NUTRITION_AGE_NOT_SUPPORTED(2014, "A calorie target is only available for users aged 18 or older", HttpStatus.BAD_REQUEST),

    INVALID_REQUEST(1018, "Invalid request data", HttpStatus.BAD_REQUEST);

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
