package com.veggiepal.meal.exception;

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

    // Ingredients
    INGREDIENT_NOT_FOUND(2010, "Ingredient not found", HttpStatus.NOT_FOUND),
    INGREDIENT_NAME_REQUIRED(2011, "Ingredient name is required", HttpStatus.BAD_REQUEST),

    // Meal Plan
    MEAL_PLAN_NOT_FOUND(2020, "Meal plan not found", HttpStatus.NOT_FOUND),
    INSUFFICIENT_RECIPES(2021, "Not enough safe recipes to generate a meal plan. Try removing some allergies.", HttpStatus.BAD_REQUEST),

    // Recipe
    RECIPE_NOT_FOUND(2050, "Recipe not found", HttpStatus.NOT_FOUND);

    private final int code;
    private final String message;
    private final HttpStatusCode statusCode;

    ErrorCode(int code, String message, HttpStatusCode statusCode) {
        this.code = code;
        this.message = message;
        this.statusCode = statusCode;
    }
}
